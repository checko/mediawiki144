# Simple MediaWiki 1.44 Setup (No Configuration Wizard!)

Set up MediaWiki 1.44 with all extensions in **one command** - no complex wizard, no manual configuration!

## 🚀 One-Command Setup

```bash
./setup.sh
```

That's it! The script will automatically:
- Start Docker containers
- Initialize the MediaWiki database
- Configure all extensions
- Create an admin user
- Set up everything for immediate use

## 📋 Prerequisites

- Docker and Docker Compose installed
- This repository cloned to your system

## 🎯 What You Get

After running `./setup.sh`, you'll have:

✅ **MediaWiki 1.44** ready at http://localhost:8050
✅ **Admin login:** username `admin`, password `AdminPassword123!`
✅ **All extensions pre-configured and working:**
- WikiMarkdown - Use Markdown syntax in wiki pages
- Diagrams - Create Graphviz, Mscgen, and PlantUML diagrams
- VisualEditor - WYSIWYG editing interface
- CodeEditor - Syntax highlighting for code
- Math - Mathematical formula rendering
- SyntaxHighlight - Code syntax highlighting
- EmbedVideo - Embed videos from popular platforms
- PDF Handler - View PDF files as images

✅ **Large file upload support** (up to 500MB)
✅ **Multimedia support** for images, videos, audio

## ⚙️ Customization

You can customize the setup by setting environment variables before running the script:

```bash
# Custom wiki settings
export WIKI_NAME="My Company Wiki"
export ADMIN_USER="administrator"
export ADMIN_PASS="MySecurePassword123!"
export WIKI_LANG="zh-tw"  # or "en", "fr", etc.
export HOST_IP="192.168.1.100"
export HOST_PORT="8080"

./setup.sh
```

## 🛠️ Advanced Configuration

The script uses the pre-configured `LocalSettings.php` which includes:
- Comprehensive extension settings
- File upload configuration (500MB max)
- Multiple file format support
- Security settings
- Performance optimizations

**To customize further:** Edit `LocalSettings.php` before running `./setup.sh`

## 🔧 Troubleshooting

### Port Already in Use
```bash
export HOST_PORT="8051"  # Use different port
./setup.sh
```

### Different IP Address
```bash
export HOST_IP="192.168.1.100"  # Your server IP
./setup.sh
```

### Database Connection Issues
```bash
docker compose down
docker compose up -d
./setup.sh
```

### Check Container Status
```bash
docker ps  # Both containers should show "Up" status
```

## 📝 Manual Method (Advanced Users)

<details>
<summary>Click to see the manual steps that the script automates</summary>

If you prefer to run the setup steps manually:

1. **Start containers:**
   ```bash
   docker compose up -d
   ```

2. **Initialize database:**
   ```bash
   # Move LocalSettings.php temporarily
   docker exec mediawiki144-mediawiki-1 mv /var/www/html/LocalSettings.php /var/www/html/LocalSettings.php.backup

   # Run MediaWiki installation
   docker exec mediawiki144-mediawiki-1 php /var/www/html/maintenance/install.php \
     --dbname=mediawiki \
     --dbserver=mysql \
     --dbuser=mediawiki \
     --dbpass=mediawiki_password \
     --server="http://localhost:8050" \
     --scriptpath="" \
     --lang=en \
     --pass=AdminPassword123! \
     "My Wiki" "admin"

   # Restore custom LocalSettings.php
   docker cp LocalSettings.php mediawiki144-mediawiki-1:/var/www/html/LocalSettings.php

   # Restart MediaWiki
   docker compose restart mediawiki
   ```

3. **Access:** http://localhost:8050

</details>

---

**Result:** MediaWiki 1.44 with all extensions, ready to use in under 2 minutes! 🎉

**No wizard, no manual configuration, no hassle!** ✨