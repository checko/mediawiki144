# MediaWiki 1.44 with WikiMarkdown Extension

This setup provides MediaWiki 1.44 with the WikiMarkdown extension using Docker Compose.

## Setup Instructions

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

## Features

- MediaWiki 1.44
- MySQL 8.0 database
- WikiMarkdown extension with Parsedown support
- Automatic dependency management via Composer
- Serves on 192.168.145.166:8050

## WikiMarkdown Extension

The WikiMarkdown extension allows you to use Markdown syntax on wiki pages. It includes:
- Parsedown for basic Markdown
- Parsedown Extra for extended Markdown features
- Parsedown Extended for additional syntax support