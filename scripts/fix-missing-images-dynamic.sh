#!/bin/bash
#
# Dynamic Missing Image File Finder and Fixer
# Works with ANY backup by using pattern matching instead of hardcoded file sizes
#

set -e

echo "=========================================="
echo "Dynamic Missing Image File Fixer"
echo "=========================================="
echo ""

# Get container name
MEDIAWIKI_CONTAINER=$(docker ps --format '{{.Names}}' | grep mediawiki | head -1)
MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep mysql | head -1)

if [ -z "$MEDIAWIKI_CONTAINER" ] || [ -z "$MYSQL_CONTAINER" ]; then
    echo "Error: Containers not running"
    exit 1
fi

echo "Step 1: Finding missing files from database..."
echo ""

# Export all images from database
docker exec $MYSQL_CONTAINER mysql -u root -proot_password -se \
    "USE mediawiki; SELECT img_name, img_size FROM image ORDER BY img_name;" \
    2>/dev/null > /tmp/all_db_images.txt

# Check which files are missing
docker exec $MEDIAWIKI_CONTAINER bash -c 'cat > /tmp/check_missing.sh << '\''INNEREOF'\''
#!/bin/bash
cd /var/www/html/images
while IFS=$'\''\t'\'' read -r filename size; do
    [ -z "$filename" ] && continue
    md5=$(echo -n "$filename" | md5sum | awk '\''{print $1}'\'')
    path="${md5:0:1}/${md5:0:2}/$filename"
    if [ ! -f "$path" ]; then
        echo "$filename	$size	$path"
    fi
done
INNEREOF
chmod +x /tmp/check_missing.sh
'

cat /tmp/all_db_images.txt | docker exec -i $MEDIAWIKI_CONTAINER bash /tmp/check_missing.sh > /tmp/missing_files.txt

MISSING_COUNT=$(wc -l < /tmp/missing_files.txt)
echo "Found $MISSING_COUNT missing files"
echo ""

if [ "$MISSING_COUNT" -eq 0 ]; then
    echo "✓ No missing files - all images present!"
    exit 0
fi

echo "Step 2: Searching for missing files using pattern matching..."
echo ""

# Copy the finder script to container
docker exec $MEDIAWIKI_CONTAINER bash -c 'cat > /tmp/find_and_fix.sh << '\''INNEREOF'\''
#!/bin/bash
cd /var/www/html/images

fixed=0
not_found=0

while IFS=$'\''\t'\'' read -r filename size path; do
    [ -z "$filename" ] && continue

    dir=$(dirname "$path")
    base=$(basename "$filename")
    ext="${base##*.}"
    name="${base%.*}"

    found_file=""

    # Strategy 1: Look for file with (1), (2), (3) suffix
    for i in 1 2 3 4 5; do
        pattern="${name} ($i).${ext}"
        if [ -f "$dir/$pattern" ]; then
            found_file="$dir/$pattern"
            break
        fi
    done

    # Strategy 2: Look for file with timestamp prefix (YYYYMMDDHHMMSS!)
    if [ -z "$found_file" ]; then
        found_file=$(find "$dir" -name "*!${base}" 2>/dev/null | head -1)
    fi

    # Strategy 3: Try AM/PM <-> 上午/下午 conversion
    if [ -z "$found_file" ]; then
        if [[ "$filename" =~ 上午 ]]; then
            alt_name="${filename//上午/下午}"
            alt_md5=$(echo -n "$alt_name" | md5sum | awk '\''{print $1}'\'')
            alt_path="${alt_md5:0:1}/${alt_md5:0:2}/$alt_name"
            [ -f "$alt_path" ] && found_file="$alt_path"

            if [ -z "$found_file" ]; then
                alt_name="${filename//上午/AM}"
                alt_md5=$(echo -n "$alt_name" | md5sum | awk '\''{print $1}'\'')
                alt_path="${alt_md5:0:1}/${alt_md5:0:2}/$alt_name"
                [ -f "$alt_path" ] && found_file="$alt_path"
            fi
        elif [[ "$filename" =~ 下午 ]]; then
            alt_name="${filename//下午/上午}"
            alt_md5=$(echo -n "$alt_name" | md5sum | awk '\''{print $1}'\'')
            alt_path="${alt_md5:0:1}/${alt_md5:0:2}/$alt_name"
            [ -f "$alt_path" ] && found_file="$alt_path"

            if [ -z "$found_file" ]; then
                alt_name="${filename//下午/PM}"
                alt_md5=$(echo -n "$alt_name" | md5sum | awk '\''{print $1}'\'')
                alt_path="${alt_md5:0:1}/${alt_md5:0:2}/$alt_name"
                [ -f "$alt_path" ] && found_file="$alt_path"
            fi
        elif [[ "$filename" =~ AM ]]; then
            alt_name="${filename//AM/上午}"
            alt_md5=$(echo -n "$alt_name" | md5sum | awk '\''{print $1}'\'')
            alt_path="${alt_md5:0:1}/${alt_md5:0:2}/$alt_name"
            [ -f "$alt_path" ] && found_file="$alt_path"
        elif [[ "$filename" =~ PM ]]; then
            alt_name="${filename//PM/下午}"
            alt_md5=$(echo -n "$alt_name" | md5sum | awk '\''{print $1}'\'')
            alt_path="${alt_md5:0:1}/${alt_md5:0:2}/$alt_name"
            [ -f "$alt_path" ] && found_file="$alt_path"
        fi
    fi

    # Strategy 4: Search by file size in the expected directory
    if [ -z "$found_file" ] && [ -n "$size" ] && [ -d "$dir" ]; then
        found_file=$(find "$dir" -type f -size ${size}c 2>/dev/null | head -1)
    fi

    # Copy the file if found
    if [ -n "$found_file" ]; then
        mkdir -p "$dir"
        cp "$found_file" "$path"
        chown www-data:www-data "$path"
        chmod 644 "$path"
        echo "✓ $filename (from: $(basename "$found_file"))"
        ((fixed++))
    else
        echo "✗ $filename (NOT FOUND)"
        ((not_found++))
    fi
done

echo ""
echo "Fixed: $fixed files"
echo "Not found: $not_found files"
INNEREOF
chmod +x /tmp/find_and_fix.sh
'

# Run the finder
cat /tmp/missing_files.txt | docker exec -i $MEDIAWIKI_CONTAINER bash /tmp/find_and_fix.sh

echo ""
echo "=========================================="
echo "✓ Dynamic fix complete!"
echo "=========================================="

# Cleanup
rm -f /tmp/all_db_images.txt /tmp/missing_files.txt
