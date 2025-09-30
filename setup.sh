#!/bin/bash

# MediaWiki 1.44 Automated Setup Script
# This script bypasses the configuration wizard and sets up MediaWiki automatically

set -e  # Exit on any error

echo "🚀 Starting MediaWiki 1.44 Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load .env file if it exists
if [ -f .env ]; then
    echo -e "${BLUE}Loading configuration from .env file...${NC}"
    set -a  # automatically export all variables
    source .env
    set +a
fi

# Default values (can be overridden with environment variables or .env file)
WIKI_NAME="${WIKI_NAME:-My Wiki}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-AdminPassword123!}"
WIKI_LANG="${WIKI_LANG:-en}"
HOST_IP="${HOST_IP:-localhost}"
HOST_PORT="${HOST_PORT:-8050}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Wiki Name: $WIKI_NAME"
echo "  Admin User: $ADMIN_USER"
echo "  Admin Password: $ADMIN_PASS"
echo "  Language: $WIKI_LANG"
echo "  URL: http://$HOST_IP:$HOST_PORT"
echo ""

# Step 1: Start containers
echo -e "${YELLOW}Step 1: Starting Docker containers...${NC}"
docker compose up -d

# Wait for containers to be ready
echo -e "${YELLOW}Waiting for containers to be ready...${NC}"
sleep 10

# Check if containers are running
if ! docker ps | grep -q "mediawiki144-mediawiki-1"; then
    echo -e "${RED}Error: MediaWiki container is not running${NC}"
    exit 1
fi

if ! docker ps | grep -q "mediawiki144-mysql-1"; then
    echo -e "${RED}Error: MySQL container is not running${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Containers are running${NC}"

# Step 2: Initialize database
echo -e "${YELLOW}Step 2: Initializing MediaWiki database...${NC}"

# Move existing LocalSettings.php out of the way
echo "  - Moving LocalSettings.php temporarily..."
docker exec mediawiki144-mediawiki-1 bash -c "
    if [ -f /var/www/html/LocalSettings.php ]; then
        mv /var/www/html/LocalSettings.php /var/www/html/LocalSettings.php.backup
    fi
" || true

# Run MediaWiki installation
echo "  - Running MediaWiki installation..."
docker exec mediawiki144-mediawiki-1 php /var/www/html/maintenance/install.php \
    --dbname=mediawiki \
    --dbserver=mysql \
    --dbuser=mediawiki \
    --dbpass=mediawiki_password \
    --server="http://$HOST_IP:$HOST_PORT" \
    --scriptpath="" \
    --lang="$WIKI_LANG" \
    --pass="$ADMIN_PASS" \
    "$WIKI_NAME" "$ADMIN_USER"

echo -e "${GREEN}✓ Database initialized${NC}"

# Step 3: Apply custom configuration
echo -e "${YELLOW}Step 3: Applying custom configuration...${NC}"

# Copy our pre-configured LocalSettings.php
if [ -f "LocalSettings.php" ]; then
    echo "  - Updating LocalSettings.php with configuration from .env..."

    # Create meta namespace from wiki name (replace spaces with underscores)
    META_NAMESPACE=$(echo "$WIKI_NAME" | sed 's/ /_/g')

    # Update LocalSettings.php with all configuration values from .env
    sed -e "s|\$wgServer = \"http://[^\"]*\"|\$wgServer = \"http://$HOST_IP:$HOST_PORT\"|g" \
        -e "s|\$wgSitename = \"[^\"]*\"|\$wgSitename = \"$WIKI_NAME\"|g" \
        -e "s|\$wgMetaNamespace = \"[^\"]*\"|\$wgMetaNamespace = \"$META_NAMESPACE\"|g" \
        -e "s|\$wgLanguageCode = \"[^\"]*\"|\$wgLanguageCode = \"$WIKI_LANG\"|g" \
        LocalSettings.php > LocalSettings.php.tmp

    echo "  - Copying custom LocalSettings.php..."
    docker cp LocalSettings.php.tmp mediawiki144-mediawiki-1:/var/www/html/LocalSettings.php

    # Clean up temporary file
    rm LocalSettings.php.tmp

    echo -e "${GREEN}✓ Custom configuration applied${NC}"
else
    echo -e "${YELLOW}⚠ No LocalSettings.php found, using default configuration${NC}"
fi

# Step 4: Restart MediaWiki
echo -e "${YELLOW}Step 4: Restarting MediaWiki...${NC}"
docker compose restart mediawiki

# Wait for restart
sleep 5

# Step 5: Copy deployed configuration for user review
echo -e "${YELLOW}Step 5: Copying deployed configuration...${NC}"
docker cp mediawiki144-mediawiki-1:/var/www/html/LocalSettings.php LocalSettings.php.deployed
echo -e "${GREEN}✓ Deployed configuration saved to LocalSettings.php.deployed${NC}"

echo -e "${GREEN}🎉 MediaWiki 1.44 setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}Access your wiki at: http://$HOST_IP:$HOST_PORT${NC}"
echo ""
echo -e "${BLUE}Login credentials:${NC}"
echo "  Username: $ADMIN_USER"
echo "  Password: $ADMIN_PASS"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  ✓ Deployed settings saved to: LocalSettings.php.deployed"
echo "  ✓ Review this file to verify your configuration"
echo ""
echo -e "${BLUE}Available extensions:${NC}"
echo "  ✓ WikiMarkdown - Use Markdown syntax"
echo "  ✓ Diagrams - Create diagrams (Graphviz, PlantUML, Mscgen)"
echo "  ✓ VisualEditor - WYSIWYG editing"
echo "  ✓ CodeEditor - Syntax highlighting"
echo "  ✓ Math - Mathematical formulas"
echo "  ✓ SyntaxHighlight - Code highlighting"
echo "  ✓ EmbedVideo - Video embedding"
echo "  ✓ PDF Handler - PDF file support"
echo ""
echo -e "${GREEN}Setup complete! Your MediaWiki is ready to use! 🚀${NC}"