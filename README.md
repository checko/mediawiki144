# MediaWiki 1.44 with Full Extension Suite

This setup provides MediaWiki 1.44 with comprehensive extensions including WikiMarkdown, Diagrams, VisualEditor, and more using Docker Compose.

## 🚀 Quick Start (Recommended)

**Skip the complex wizard and get MediaWiki running in one command:**

```bash
./setup.sh
```

**That's it!** Your MediaWiki will be ready at http://192.168.147.182:8050 with admin/AdminPassword123!

### Customization (Optional)

To customize wiki name, language, admin credentials, or server settings:

```bash
cp .env.example .env
# Edit .env with your preferred values
./setup.sh
```

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
   - Open your browser and go to `http://192.168.145.166:8050`
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