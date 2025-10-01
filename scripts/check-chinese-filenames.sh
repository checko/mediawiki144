#!/bin/bash

# Check if Chinese-named files exist

files=(
    "-架構圖-FileExplorer.JPG"
    "-架構圖-MediaService.JPG"
    "-架構圖-AppleRemoteExplorer.JPG"
    "-架構圖-AppleLibary.JPG"
    "-架構圖-MediaExplorer.JPG"
    "DVR_Recoder_架構說明.jpg"
    "DVR_UI_架構說明.jpg"
    "RN2-聲音出來的硬體修改位置.JPG"
    "ALSA聲音大小聲介面.jpg"
    "Usb-音樂畫面.JPG"
)

echo "Checking Chinese-named files..."
echo

for file in "${files[@]}"; do
    # Calculate MD5 path
    hash=$(echo -n "$file" | md5sum | awk '{print $1}')
    hash1=${hash:0:1}
    hash2=${hash:0:2}
    path="$hash1/$hash2/$file"

    # Check if file exists
    if docker compose exec -T mediawiki test -f "/var/www/html/images/$path" 2>/dev/null; then
        echo "✓ $file (EXISTS)"
    else
        echo "✗ $file (MISSING)"
        # List files in the directory
        echo "  Files in $hash2/:"
        docker compose exec -T mediawiki ls "/var/www/html/images/$hash1/$hash2/" 2>/dev/null | grep -v "thumb" | head -5
        echo
    fi
done
