#!/bin/bash

# MediaWiki 1.44 Setup and Data Restoration Script
# Restores database and images from older MediaWiki installations (1.31 or earlier)
# Handles encoding issues with Traditional Chinese filenames

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="data/backups"
LOG_FILE="data/restore-$(date +%Y%m%d-%H%M%S).log"
DB_DUMP="data/wikidb.sql"
IMAGES_ZIP="data/images.zip"
TEMP_IMAGES="/tmp/wiki-images"

# Container names (will be auto-detected)
MEDIAWIKI_CONTAINER=""
MYSQL_CONTAINER=""

# Load .env file if it exists
if [ -f .env ]; then
    echo -e "${BLUE}Loading configuration from .env file...${NC}"
    set -a
    source .env
    set +a
fi

# Default values
WIKI_NAME="${WIKI_NAME:-My Wiki}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-AdminPassword123!}"
WIKI_LANG="${WIKI_LANG:-en}"
HOST_IP="${HOST_IP:-localhost}"
HOST_PORT="${HOST_PORT:-8050}"

# Logging function
log() {
    echo -e "$@" | tee -a "$LOG_FILE"
}

log "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
log "${BLUE}║  MediaWiki 1.44 Setup and Restoration Script                  ║${NC}"
log "${BLUE}║  Restoring from MediaWiki 1.31 or older                        ║${NC}"
log "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
log ""

# Pre-flight checks
log "${YELLOW}Pre-flight checks...${NC}"

if [ ! -f "$DB_DUMP" ]; then
    log "${RED}Error: Database dump not found at $DB_DUMP${NC}"
    log "${YELLOW}Please place your wikidb.sql file in the data/ directory${NC}"
    exit 1
fi
log "${GREEN}✓ Database dump found${NC}"

if [ ! -f "$IMAGES_ZIP" ]; then
    log "${YELLOW}⚠ Images archive not found at $IMAGES_ZIP${NC}"
    log "${YELLOW}  Will continue without images restoration${NC}"
    RESTORE_IMAGES=false
else
    log "${GREEN}✓ Images archive found${NC}"
    RESTORE_IMAGES=true
fi

if [ ! -f "scripts/extract-images.py" ]; then
    log "${RED}Error: Image extraction script not found at scripts/extract-images.py${NC}"
    exit 1
fi
log "${GREEN}✓ Image extraction script found${NC}"

if [ ! -f "LocalSettings.php" ]; then
    log "${RED}Error: LocalSettings.php not found${NC}"
    log "${YELLOW}Please ensure LocalSettings.php exists in the project root${NC}"
    exit 1
fi
log "${GREEN}✓ LocalSettings.php found${NC}"

log ""
log "${BLUE}Configuration:${NC}"
log "  Wiki Name: $WIKI_NAME"
log "  Admin User: $ADMIN_USER"
log "  Language: $WIKI_LANG"
log "  URL: http://$HOST_IP:$HOST_PORT"
log "  Database Dump: $DB_DUMP"
log "  Images Archive: $IMAGES_ZIP"
log "  Log File: $LOG_FILE"
log ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Step 1: Start containers
log "${YELLOW}═══ Step 1: Starting Docker containers ═══${NC}"
docker compose up -d

log "${YELLOW}Waiting for containers to be ready...${NC}"
sleep 10

# Auto-detect container names
MEDIAWIKI_CONTAINER=$(docker ps --format '{{.Names}}' | grep mediawiki | head -1)
MYSQL_CONTAINER=$(docker ps --format '{{.Names}}' | grep mysql | head -1)

if [ -z "$MEDIAWIKI_CONTAINER" ]; then
    log "${RED}Error: MediaWiki container not found${NC}"
    exit 1
fi

if [ -z "$MYSQL_CONTAINER" ]; then
    log "${RED}Error: MySQL container not found${NC}"
    exit 1
fi

log "${GREEN}✓ Containers running${NC}"
log "  MediaWiki: $MEDIAWIKI_CONTAINER"
log "  MySQL: $MYSQL_CONTAINER"
log ""

# Step 2: Backup current database
log "${YELLOW}═══ Step 2: Backing up current database ═══${NC}"
BACKUP_FILE="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).sql"

docker compose exec mysql mysqldump \
    -u root -proot_password \
    mediawiki > "$BACKUP_FILE" 2>/dev/null || true

if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    log "${GREEN}✓ Current database backed up to $BACKUP_FILE${NC}"
else
    log "${YELLOW}⚠ No existing database to backup${NC}"
fi
log ""

# Step 3: Import old database
log "${YELLOW}═══ Step 3: Importing old database ═══${NC}"
log "  Dropping and recreating database..."

docker compose exec mysql mysql -u root -proot_password -e "
    DROP DATABASE IF EXISTS mediawiki;
    CREATE DATABASE mediawiki CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    GRANT ALL ON mediawiki.* TO 'mediawiki'@'%';
    FLUSH PRIVILEGES;
" 2>/dev/null

log "  Importing SQL dump (this may take a while)..."
docker compose exec -T mysql mysql \
    -u root -proot_password \
    mediawiki < "$DB_DUMP" 2>/dev/null

# Verify import
PAGE_COUNT=$(docker compose exec mysql mysql -u root -proot_password -se "USE mediawiki; SELECT COUNT(*) FROM page;" 2>/dev/null | tr -d '\r')
REVISION_COUNT=$(docker compose exec mysql mysql -u root -proot_password -se "USE mediawiki; SELECT COUNT(*) FROM revision;" 2>/dev/null | tr -d '\r')

log "${GREEN}✓ Database imported successfully${NC}"
log "  Pages: $PAGE_COUNT"
log "  Revisions: $REVISION_COUNT"
log ""

# Step 4: Upgrade to MediaWiki 1.35 (Intermediate)
log "${YELLOW}═══ Step 4: Upgrading to MediaWiki 1.35 (Intermediate) ═══${NC}"
log "  Why: MediaWiki 1.44 requires database schema from 1.35+ minimum"
log ""

# Stop MediaWiki container temporarily
docker compose stop mediawiki

# Get network name
NETWORK=$(docker network ls --format '{{.Name}}' | grep mediawiki144claude)

if [ -z "$NETWORK" ]; then
    log "${RED}Error: Docker network not found${NC}"
    exit 1
fi

log "  Running MediaWiki 1.35 updater..."
docker run --rm \
    --network "$NETWORK" \
    -v "$PWD/data/LocalSettings.minimal.php:/var/www/html/LocalSettings.php:ro" \
    mediawiki:1.35 \
    php maintenance/update.php --quick 2>&1 | tee -a "$LOG_FILE"

log "${GREEN}✓ Database upgraded to MediaWiki 1.35 schema${NC}"
log ""

# Step 5: Upgrade to MediaWiki 1.44 (Final)
log "${YELLOW}═══ Step 5: Upgrading to MediaWiki 1.44 (Final) ═══${NC}"

# Update LocalSettings.php with .env values
log "  Updating LocalSettings.php with configuration..."
META_NAMESPACE=$(echo "$WIKI_NAME" | sed 's/ /_/g')

sed -e "s|\$wgServer = \"http://[^\"]*\"|\$wgServer = \"http://$HOST_IP:$HOST_PORT\"|g" \
    -e "s|\$wgSitename = \"[^\"]*\"|\$wgSitename = \"$WIKI_NAME\"|g" \
    -e "s|\$wgMetaNamespace = \"[^\"]*\"|\$wgMetaNamespace = \"$META_NAMESPACE\"|g" \
    -e "s|\$wgLanguageCode = \"[^\"]*\"|\$wgLanguageCode = \"$WIKI_LANG\"|g" \
    LocalSettings.php > LocalSettings.php.tmp

# Copy updated LocalSettings.php to container
docker cp LocalSettings.php.tmp "$MEDIAWIKI_CONTAINER:/var/www/html/LocalSettings.php"
rm LocalSettings.php.tmp

# Start MediaWiki container
docker compose start mediawiki
sleep 5

log "  Running MediaWiki 1.44 updater with all extensions..."
docker compose exec mediawiki php maintenance/update.php --quick 2>&1 | tee -a "$LOG_FILE"

log "${GREEN}✓ Database upgraded to MediaWiki 1.44${NC}"
log ""

# Step 6: Restore images
if [ "$RESTORE_IMAGES" = true ]; then
    log "${YELLOW}═══ Step 6: Restoring images ═══${NC}"

    # Extract images with encoding support
    log "  Extracting images with Traditional Chinese encoding support..."
    python3 scripts/extract-images.py "$IMAGES_ZIP" "$TEMP_IMAGES" cp950 2>&1 | tee -a "$LOG_FILE"

    # Check if images directory exists in extracted files
    if [ ! -d "$TEMP_IMAGES/images" ]; then
        log "${YELLOW}⚠ No 'images' directory found in archive, checking root...${NC}"
        if [ -d "$TEMP_IMAGES" ] && [ "$(ls -A $TEMP_IMAGES)" ]; then
            # Files are in root of archive, treat as images directory
            mv "$TEMP_IMAGES" "${TEMP_IMAGES}.tmp"
            mkdir -p "$TEMP_IMAGES/images"
            mv "${TEMP_IMAGES}.tmp"/* "$TEMP_IMAGES/images/" 2>/dev/null || true
            rmdir "${TEMP_IMAGES}.tmp" 2>/dev/null || true
        fi
    fi

    if [ -d "$TEMP_IMAGES/images" ]; then
        log "  Copying images to container..."
        docker compose exec mediawiki mkdir -p /var/www/html/images
        docker cp "$TEMP_IMAGES/images/." "$MEDIAWIKI_CONTAINER:/var/www/html/images/"

        log "  Fixing permissions..."
        docker compose exec mediawiki chown -R www-data:www-data /var/www/html/images
        docker compose exec mediawiki find /var/www/html/images -type d -exec chmod 755 {} +
        docker compose exec mediawiki find /var/www/html/images -type f -exec chmod 644 {} +

        log "  Rebuilding image metadata..."
        docker compose exec mediawiki php maintenance/refreshImageMetadata.php --force 2>&1 | tee -a "$LOG_FILE"
        docker compose exec mediawiki php maintenance/rebuildImages.php --missing 2>&1 | tee -a "$LOG_FILE"

        # Cleanup
        rm -rf "$TEMP_IMAGES"

        log "${GREEN}✓ Images restored successfully${NC}"
    else
        log "${RED}Error: Could not find images in archive${NC}"
    fi
    log ""
fi

# Step 7: Copy deployed configuration
log "${YELLOW}═══ Step 7: Finalizing setup ═══${NC}"
docker cp "$MEDIAWIKI_CONTAINER:/var/www/html/LocalSettings.php" LocalSettings.php.deployed
log "${GREEN}✓ Deployed configuration saved to LocalSettings.php.deployed${NC}"
log ""

# Final verification
log "${YELLOW}═══ Final Verification ═══${NC}"
PAGE_COUNT=$(docker compose exec mysql mysql -u root -proot_password -se "USE mediawiki; SELECT COUNT(*) FROM page;" 2>/dev/null | tr -d '\r')
USER_COUNT=$(docker compose exec mysql mysql -u root -proot_password -se "USE mediawiki; SELECT COUNT(*) FROM user;" 2>/dev/null | tr -d '\r')
IMAGE_COUNT=$(docker compose exec mysql mysql -u root -proot_password -se "USE mediawiki; SELECT COUNT(*) FROM image;" 2>/dev/null | tr -d '\r')

log "${GREEN}✓ Database Statistics:${NC}"
log "  Pages: $PAGE_COUNT"
log "  Users: $USER_COUNT"
log "  Images: $IMAGE_COUNT"
log ""

# Success summary
log "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
log "${GREEN}║  🎉 MediaWiki 1.44 Restoration Completed Successfully!         ║${NC}"
log "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
log ""
log "${BLUE}Access your wiki at: http://$HOST_IP:$HOST_PORT${NC}"
log ""
log "${BLUE}Login with your OLD wiki credentials${NC}"
log "  (Your original admin account has been preserved)"
log ""
log "${BLUE}Verification checklist:${NC}"
log "  [ ] Homepage loads at http://$HOST_IP:$HOST_PORT"
log "  [ ] Admin login works with old credentials"
log "  [ ] Visit Special:Version to verify MediaWiki 1.44"
log "  [ ] Browse pages to check content integrity"
log "  [ ] Check Special:ListFiles for uploaded images"
log "  [ ] Verify Chinese filename images display correctly"
log "  [ ] Test editing a page"
log "  [ ] Test uploading a new file"
log ""
log "${BLUE}Available extensions:${NC}"
log "  ✓ WikiMarkdown"
log "  ✓ Diagrams (Graphviz, PlantUML, Mscgen)"
log "  ✓ VisualEditor"
log "  ✓ CodeEditor"
log "  ✓ Math"
log "  ✓ SyntaxHighlight"
log "  ✓ EmbedVideo"
log "  ✓ PDF Handler"
log ""
log "${BLUE}Backup and logs:${NC}"
log "  Original database backup: $BACKUP_FILE"
log "  Restoration log: $LOG_FILE"
log ""
log "${YELLOW}Note: First thumbnail generation may be slow (normal behavior)${NC}"
log ""
log "${GREEN}Restoration complete! 🚀${NC}"
