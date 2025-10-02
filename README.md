# MediaWiki 1.44 with Full Extension Suite

This setup provides MediaWiki 1.44 with comprehensive extensions including WikiMarkdown, Diagrams, VisualEditor, and more using Docker Compose.

## 🚀 Quick Start (Recommended)

**Skip the complex wizard and get MediaWiki running in one command:**

```bash
./setup.sh
```

**That's it!** Your MediaWiki will be ready at http://localhost:8050 with admin/AdminPassword123!

### Customization (Optional)

To customize wiki name, language, admin credentials, or server settings:

```bash
cp .env.example .env
# Edit .env with your preferred values
./setup.sh
```

The setup script automatically updates all configuration files including:
- `docker-compose.yml` - Uses `HOST_IP` and `HOST_PORT` from .env
- `LocalSettings.php` - Automatically updated with your server URL during setup

👉 **See [SIMPLE_SETUP.md](SIMPLE_SETUP.md) for details and customization options.**

## Manual Setup (Advanced Users)

<details>
<summary>Click here if you prefer the traditional wizard-based setup</summary>

### Manual Setup Instructions

1. **Start the containers:**
   ```bash
   docker-compose up -d
   ```

2. **Access MediaWiki setup:**
   - Open your browser and go to `http://localhost:8050`
   - Follow the MediaWiki installation wizard
   - Use these database settings:
     - Database type: MySQL
     - Database host: mysql
     - Database name: mediawiki
     - Database username: mediawiki
     - Database password: mediawiki_password

3. **Download and configure LocalSettings.php:**
   - At the end of the installation, download the generated `LocalSettings.php`
   - Run the configuration script: `./configure-wikimarkdown.sh`
   - Copy the configured file to the container: `docker cp LocalSettings.php mediawiki144claude-mediawiki-1:/var/www/html/`

4. **Restart the MediaWiki container:**
   ```bash
   docker-compose restart mediawiki
   ```

</details>

## 🎯 Features

- **MediaWiki 1.44** - Latest stable version with security updates
- **MySQL 8.0** database backend
- **Comprehensive Extension Suite:**
  - **WikiMarkdown** - Use Markdown syntax in wiki pages (Parsedown, Parsedown Extra, Parsedown Extended)
  - **Diagrams** - Create Graphviz, Mscgen, and PlantUML diagrams (MediaWiki 1.44 compatible)
  - **VisualEditor** - WYSIWYG editing interface
  - **CodeEditor** - Syntax highlighting for JavaScript/CSS
  - **Math** - Mathematical formula rendering
  - **SyntaxHighlight** - Code syntax highlighting
  - **EmbedVideo** - Embed videos from popular platforms
  - **PDF Handler** - View PDF files as images
- **Large file upload support** (up to 500MB)
- **Automatic dependency management** via Composer
- **Multi-format file support** (images, videos, audio, documents, archives)
- **One-command setup** - No complex configuration wizard

## 🛠️ Extensions Details

### WikiMarkdown Extension
Use Markdown syntax directly in wiki pages with full Parsedown support:
- Basic Markdown formatting
- Parsedown Extra features (tables, footnotes, etc.)
- Parsedown Extended syntax support

### Diagrams Extension
Create professional diagrams using text-based syntax:
- **Graphviz** - Network diagrams, flowcharts, organizational charts
- **PlantUML** - UML diagrams, sequence diagrams, use cases
- **Mscgen** - Message sequence charts
- Built with MediaWiki 1.44 compatibility fixes

## 🔄 Updating Extensions to Latest Version

### Root Cause: Docker Build Cache
Extensions (WikiMarkdown, Diagrams) are cloned from GitHub **during Docker image build** (Dockerfile lines 24-34). Docker's build layer caching means that even after `docker compose down -v --rmi all`, the `git clone` commands may use cached results from previous builds, leaving you with outdated extension code.

**Key Point:** `-v` removes volumes, `--rmi all` removes images, but **build cache persists separately**.

### Solution Options:

**Option 1: Clear build cache then rebuild (Recommended)**
```bash
docker compose down -v --rmi all
docker builder prune -a -f
docker compose build
docker compose up -d
./setup.sh
```

**Option 2: Force rebuild without using cache**
```bash
docker compose down -v --rmi all
docker compose build --no-cache
docker compose up -d
./setup.sh
```

Both options ensure you get the latest extension code from GitHub. Option 1 clears all build cache first, Option 2 bypasses cache for this specific build.