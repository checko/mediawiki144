#!/bin/bash

# Script to configure WikiMarkdown extension in MediaWiki
# Run this after MediaWiki installation is complete

LOCALSETTINGS_FILE="./LocalSettings.php"

# Check if LocalSettings.php exists
if [ ! -f "$LOCALSETTINGS_FILE" ]; then
    echo "Error: LocalSettings.php not found. Please complete MediaWiki installation first."
    exit 1
fi

# Check if WikiMarkdown extension is already configured
if grep -q "wfLoadExtension.*WikiMarkdown" "$LOCALSETTINGS_FILE"; then
    echo "WikiMarkdown extension is already configured."
    exit 0
fi

# Add WikiMarkdown extension configuration
echo "" >> "$LOCALSETTINGS_FILE"
echo "# WikiMarkdown extension configuration" >> "$LOCALSETTINGS_FILE"
echo "wfLoadExtension( 'WikiMarkdown' );" >> "$LOCALSETTINGS_FILE"
echo "\$wgAllowMarkdownExtra = true; // allows usage of Parsedown Extra" >> "$LOCALSETTINGS_FILE"
echo "\$wgAllowMarkdownExtended = true; // allows usage of Parsedown Extended" >> "$LOCALSETTINGS_FILE"

echo "WikiMarkdown extension has been successfully configured!"
echo "Please restart your MediaWiki container for changes to take effect."