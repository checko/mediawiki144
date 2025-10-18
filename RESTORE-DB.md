# MediaWiki Database and Images Restoration Guide

## Quick Start

**One-command restoration from MediaWiki 1.31 (or older) to MediaWiki 1.44:**

```bash
./restore.sh
```

This script will:
1. ✅ Set up MediaWiki 1.44 containers
2. ✅ Backup your current database (if any)
3. ✅ Import your old database
4. ✅ Perform two-stage upgrade (1.35 → 1.44)
5. ✅ Restore images with Chinese encoding support
6. ✅ Rebuild all metadata
7. ✅ Verify the restoration

---

## Prerequisites

### Required Files

Place these files in the `data/` directory before running:

1. **Database dump:** `data/wikidb.sql`
   - Must be a MySQL dump from MediaWiki 1.31 or older
   - UTF-8 encoded

2. **Images archive:** `data/images.zip` (optional)
   - ZIP file containing your MediaWiki `images/` directory
   - Supports Traditional Chinese filenames (cp950/big5)

**⚠️ IMPORTANT: Backup Timing**
- The database dump and images archive must be from the **same point in time**
- If your database backup is newer than your images backup, some images referenced in the database will be missing
- If your images backup is newer than your database backup, extra images will be ignored (harmless)
- **Recommendation:** Always create both backups at the same time to ensure consistency

### Required Docker Images

The script requires these Docker images (pulled automatically if needed):
- `mediawiki:1.35` - Intermediate upgrade step
- `mediawiki:1.44` - Final target (custom built)
- `mysql:8.0` - Database server

---

## Usage

### Basic Restoration

```bash
# 1. Place your files in data/ directory
cp /path/to/your/wikidb.sql data/
cp /path/to/your/images.zip data/

# 2. Run restoration
./restore.sh
```

### Custom Configuration

To customize wiki settings:

```bash
# 1. Copy and edit .env file
cp .env.example .env
nano .env

# 2. Run restoration
./restore.sh
```

Available settings in `.env`:
- `WIKI_NAME` - Your wiki's name
- `WIKI_LANG` - Language code (en, zh, etc.)
- `HOST_IP` - Server IP/hostname
- `HOST_PORT` - Port number
- `ADMIN_USER` - Preserved from old database
- `ADMIN_PASS` - Preserved from old database

---

## What the Script Does

### Phase 1: Container Setup
- Starts MediaWiki 1.44 and MySQL 8.0 containers
- Detects container names automatically
- Verifies all containers are running

### Phase 2: Database Backup
- Backs up current database to `data/backups/backup-YYYYMMDD-HHMMSS.sql`
- Safe rollback point if restoration fails

### Phase 3: Old Database Import
- Drops and recreates database with UTF-8 support
- Imports your old SQL dump
- Verifies page and revision counts

### Phase 4: Two-Stage Upgrade

**Why two stages?**
MediaWiki 1.44 cannot upgrade directly from versions < 1.35. The database schema has breaking changes.

**Stage 1: Upgrade to 1.35**
- Uses minimal configuration (no extensions)
- Updates database schema to 1.35 format
- Handles actor table migrations

**Stage 2: Upgrade to 1.44**
- Uses full configuration with all extensions
- Final schema update to 1.44
- Enables all extensions

### Phase 5: Images Restoration
- Extracts images with encoding detection
- Handles Traditional Chinese filenames (cp950, big5, gbk)
- Copies to container with proper permissions
- Rebuilds image metadata and thumbnails

### Phase 6: Verification
- Counts pages, users, and images
- Saves deployed configuration
- Provides verification checklist

---

## File Structure

```
mediawiki144claude/
├── restore.sh                      # Master restoration script
├── scripts/
│   └── extract-images.py          # Encoding-aware image extractor
├── data/
│   ├── wikidb.sql                 # Your old database (you provide)
│   ├── images.zip                 # Your images archive (you provide)
│   ├── LocalSettings.minimal.php  # Minimal config for 1.35 upgrade
│   ├── backups/                   # Automatic backups
│   │   └── backup-*.sql
│   └── restore-*.log              # Restoration logs
├── LocalSettings.php              # Full config with extensions
└── LocalSettings.php.deployed     # Final deployed config (generated)
```

---

## Troubleshooting

### Issue: "Database dump not found"
```bash
# Ensure file exists
ls -lh data/wikidb.sql

# Check file permissions
chmod 644 data/wikidb.sql
```

### Issue: "MySQL import fails with encoding errors"
```bash
# Verify file encoding
file data/wikidb.sql  # Should show UTF-8

# Convert if needed
iconv -f ISO-8859-1 -t UTF-8 data/wikidb.sql > data/wikidb.utf8.sql
mv data/wikidb.utf8.sql data/wikidb.sql
```

### Issue: "Actor table conflicts during 1.35 upgrade"
The script handles this automatically, but if you see errors:
```bash
docker compose exec mysql mysql -u root -proot_password -e "
  USE mediawiki;
  UPDATE actor a
  JOIN user u ON u.user_id = a.actor_user
  SET a.actor_name = u.user_name
  WHERE a.actor_user IS NOT NULL AND a.actor_name <> u.user_name;
"
```

### Issue: "Chinese filenames are garbled"
The `extract-images.py` script handles this automatically. If issues persist:
```bash
# Try different encoding
python3 scripts/extract-images.py data/images.zip /tmp/wiki-images big5
```

### Issue: "Thumbnails not generating"
```bash
# Manually regenerate thumbnails
docker compose exec mediawiki php maintenance/refreshImageMetadata.php --force
docker compose exec mediawiki php maintenance/rebuildImages.php --missing
```

---

## Rollback

If restoration fails, restore your backup:

```bash
# 1. Find your backup
ls -lh data/backups/

# 2. Stop containers
docker compose down

# 3. Start MySQL
docker compose up -d mysql
sleep 5

# 4. Restore backup
docker compose exec -T mysql mysql -u root -proot_password -e "
  DROP DATABASE IF EXISTS mediawiki;
  CREATE DATABASE mediawiki CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
"
docker compose exec -T mysql mysql -u root -proot_password \
  mediawiki < data/backups/backup-YYYYMMDD-HHMMSS.sql

# 5. Restart all containers
docker compose up -d
```

---

## Verification Checklist

After restoration completes:

- [ ] **Homepage loads:** Visit `http://localhost:8050`
- [ ] **Admin login works:** Use your original admin credentials
- [ ] **Check version:** Visit `Special:Version` → should show MediaWiki 1.44
- [ ] **Browse pages:** Check that content displays correctly
- [ ] **Check images:** Visit `Special:ListFiles`
- [ ] **Chinese filenames:** Verify images with Chinese names work
- [ ] **Edit test:** Make a test edit to a page
- [ ] **Upload test:** Upload a new file
- [ ] **Extensions loaded:** Check `Special:Version` for:
  - WikiMarkdown
  - Diagrams
  - VisualEditor
  - CodeEditor
  - Math
  - SyntaxHighlight
  - EmbedVideo
  - PDF Handler

---

## Advanced Options

### Skip Images Restoration

If you only want to restore the database:
```bash
# Remove or rename images.zip
mv data/images.zip data/images.zip.skip

# Run script
./restore.sh
```

### Manual Step-by-Step

If you prefer manual control, see [RESTORE_PLAN.md](RESTORE_PLAN.md) for detailed step-by-step instructions.

### Custom LocalSettings.php

The script uses `LocalSettings.php` in the project root. To customize:
1. Edit `LocalSettings.php` before running `./restore.sh`
2. Your changes will be preserved during restoration

---

## Logs and Debugging

All restoration steps are logged:
```bash
# View latest log
ls -lt data/restore-*.log | head -1 | awk '{print $9}' | xargs cat

# Follow restoration in real-time
tail -f data/restore-*.log
```

---

## Post-Restoration Tasks

### Update Admin Password (Optional)

```bash
docker compose exec mediawiki php maintenance/changePassword.php \
  --user=admin \
  --password=NewSecurePassword123!
```

### Enable Additional Extensions

Edit `LocalSettings.php` and add:
```php
wfLoadExtension( 'YourExtension' );
```

Then update:
```bash
docker compose exec mediawiki php maintenance/update.php --quick
docker compose restart mediawiki
```

### Performance Tuning

For large wikis, consider:
```bash
# Run job queue
docker compose exec mediawiki php maintenance/runJobs.php

# Rebuild search index
docker compose exec mediawiki php maintenance/rebuildtextindex.php

# Update statistics
docker compose exec mediawiki php maintenance/updateSpecialPages.php
```

---

## Support

- **MediaWiki Documentation:** https://www.mediawiki.org/wiki/Manual:Upgrading
- **Project Issues:** Check `data/restore-*.log` for detailed error messages
- **Rollback:** See "Rollback" section above

---

## Technical Details

### Why Two-Stage Upgrade?

MediaWiki has breaking schema changes between major versions:
- **1.31 → 1.35:** Actor table migration, user rights changes
- **1.35 → 1.44:** Content model updates, extension API changes

Direct upgrade would fail. Two-stage ensures compatibility.

### Encoding Handling

The `extract-images.py` script:
1. Tries multiple encodings: UTF-8 → cp950 → big5 → gbk → gb18030
2. Normalizes escaped Unicode (#Uxxxx format)
3. Preserves original filenames for MediaWiki compatibility

### Container Strategy

- **1.35 container:** Temporary, used only for intermediate upgrade
- **1.44 container:** Final target, runs your wiki
- **MySQL 8.0:** Modern database with UTF-8 support

---

**Restoration complete! Your MediaWiki 1.44 is ready with all your old data! 🚀**
