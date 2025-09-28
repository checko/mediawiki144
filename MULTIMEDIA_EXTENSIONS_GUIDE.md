# MediaWiki Multimedia Preview Extensions Guide

This guide documents the multimedia preview extensions installed in MediaWiki 1.44 for comprehensive PDF, video, audio, and image preview functionality.

## Overview

The MediaWiki installation includes three main multimedia extensions that provide enhanced preview capabilities:

1. **PdfHandler** - PDF document preview and thumbnails
2. **EmbedVideo** - Video/audio embedding and local media support
3. **MultimediaViewer** - Enhanced image gallery and lightbox viewing

## PDF Preview - PdfHandler Extension

### Features
- **Multipage PDF thumbnails**: Automatic thumbnail generation for PDF pages
- **Page navigation**: Browse through PDF pages in the file description page
- **Integration support**: Works with Proofread Page extension for document transcription
- **Thumbnail previews**: Shows PDF page previews in file listings

### Usage
```wikitext
# Upload and display PDF like an image
[[File:document.pdf]]

# Display specific page from PDF
[[File:document.pdf|page=3]]

# With caption and size
[[File:manual.pdf|thumb|300px|User manual documentation]]
```

### Configuration
```php
# PdfHandler extension configuration in LocalSettings.php
$wgPdfProcessor = '/usr/bin/gs';           # Ghostscript path
$wgPdfPostProcessor = '/usr/bin/convert';  # ImageMagick path
$wgPdfInfo = '/usr/bin/pdfinfo';          # PDF info extraction
$wgPdftoText = '/usr/bin/pdftotext';      # PDF text extraction
```

**Note**: PDF thumbnail generation requires system dependencies (Ghostscript and Poppler tools) to be installed.

## Video & Audio Support - EmbedVideo Extension

### Features
- **Local media files**: HTML5 `<video>` and `<audio>` tag support
- **External services**: YouTube, Vimeo, Twitch, Spotify, SoundCloud support
- **Privacy controls**: External content loads only after user consent
- **FFmpeg integration**: Video processing and thumbnail generation
- **Timestamp support**: Start/end time parameters for clips
- **Responsive design**: Configurable player dimensions

### Supported External Services
- YouTube
- Vimeo
- Twitch
- Spotify
- SoundCloud
- And many more...

### Usage Examples

#### Local Video Files
```wikitext
# Basic video embedding
[[File:presentation.mp4]]

# With custom dimensions
[[File:demo.mp4|400px]]

# Video with start/end timestamps
[[File:tutorial.mp4|start=60|end=180]]
```

#### External Videos
```wikitext
# YouTube video
{{#ev:youtube|dQw4w9WgXcQ}}

# With custom dimensions
{{#ev:youtube|dQw4w9WgXcQ|640|480}}

# Vimeo video
{{#ev:vimeo|123456789}}

# With alignment
{{#ev:youtube|dQw4w9WgXcQ|||right}}
```

#### Audio Files
```wikitext
# Local audio file
[[File:podcast.mp3]]

# Spotify playlist
{{#ev:spotify|playlist|37i9dQZF1DXcBWIGoYBM5M}}
```

### Configuration
```php
# EmbedVideo extension settings in LocalSettings.php
$wgEmbedVideoMinWidth = 300;           # Minimum player width
$wgEmbedVideoMaxWidth = 800;           # Maximum player width
$wgEmbedVideoDefaultWidth = 640;       # Default player width
$wgEmbedVideoEnableVideoHandler = true; # Enable local video support
$wgEmbedVideoEnableAudioHandler = true; # Enable local audio support
$wgFFmpegLocation = '/usr/bin/ffmpeg';  # FFmpeg binary location
```

## Enhanced Image Gallery - MultimediaViewer

### Features
- **Lightbox viewing**: Click images for full-screen preview
- **Metadata display**: Shows image information, author, license
- **Navigation controls**: Previous/next image navigation
- **Zoom functionality**: Zoom in/out on high-resolution images
- **Share tools**: Easy sharing and download options
- **Mobile responsive**: Touch gestures and mobile optimization

### Usage
No special syntax required - works automatically with all images:

```wikitext
# Regular image - click for lightbox view
[[File:photo.jpg|thumb|Beautiful landscape]]

# Image gallery - each image opens in lightbox
<gallery>
File:image1.jpg|Caption 1
File:image2.jpg|Caption 2
File:image3.jpg|Caption 3
</gallery>
```

### Configuration
Works automatically - no additional configuration required.

## Supported File Formats

### Images
- **Raster**: PNG, GIF, JPG, JPEG, WebP, TIFF, TIF, BMP, ICO, PSD
- **Vector**: SVG

### Documents
- **Office**: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX
- **OpenDocument**: ODT, ODS, ODP
- **Text**: RTF, TXT, CSV
- **eBooks**: EPUB, MOBI

### Media Files (with EmbedVideo)
- **Video**: MP4, WebM, OGV, AVI, MOV, WMV, FLV, MKV
- **Audio**: MP3, WAV, OGG, FLAC, M4A, AAC

### Archives
- **Compressed**: ZIP, RAR, 7Z, TAR, GZ, BZ2

### Technical Files
- **Code**: XML, JSON, CSS, JS, PHP, PY, JAVA, CPP, C, H
- **CAD**: DWG, DXF, STEP, STP, IGES, IGS

## System Dependencies

### Required Packages
```bash
# FFmpeg for video/audio processing
ffmpeg

# PDF processing tools (CRITICAL for PDF previews)
ghostscript     # PDF to image conversion for thumbnails - required for PdfHandler
poppler-utils   # PDF metadata extraction (pdfinfo, pdftotext) - required for PdfHandler

# Already installed for diagrams:
graphviz        # For diagram rendering
mscgen          # For message sequence charts
default-jre     # Java runtime for PlantUML
plantuml        # UML diagram generation
```

**Important**: PDF preview functionality requires both `ghostscript` and `poppler-utils` to be installed in the system. Without these packages, PDF files will not generate thumbnails or previews.

### PHP Configuration
```ini
# Large file upload support (500MB)
upload_max_filesize = 500M
post_max_size = 500M
memory_limit = 1G
max_execution_time = 300
max_input_time = 300
max_file_uploads = 20
```

## Installation Process

### Automatic Installation (Docker)
The extensions are automatically installed during Docker build:

```dockerfile
# Install multimedia system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    graphviz \
    mscgen \
    default-jre-headless \
    wget

# Install extensions
RUN cd /var/www/html/extensions && \
    git clone https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo.git EmbedVideo

# PdfHandler and MultimediaViewer are included with MediaWiki 1.44
```

### Manual Installation
1. **Install system dependencies**:
   ```bash
   sudo apt-get install ffmpeg
   ```

2. **Download EmbedVideo extension**:
   ```bash
   cd /var/www/html/extensions
   git clone https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo.git EmbedVideo
   ```

3. **Enable in LocalSettings.php**:
   ```php
   wfLoadExtension( 'EmbedVideo' );
   wfLoadExtension( 'MultimediaViewer' ); // Usually enabled by default
   // PdfHandler is enabled by default in MediaWiki 1.44
   ```

## Privacy and Security

### EmbedVideo Privacy Features
- **Consent-based loading**: External content requires user click to load
- **GDPR compliance**: Respects user privacy preferences
- **Local file priority**: Encourages local media uploads over external embedding

### Security Considerations
- **File type validation**: Only allowed file extensions can be uploaded
- **FFmpeg sandboxing**: Video processing runs in controlled environment
- **Size limits**: 500MB upload limit prevents resource abuse

## Troubleshooting

### Common Issues

1. **FFmpeg not found**
   ```bash
   # Verify FFmpeg installation
   which ffmpeg
   # Should output: /usr/bin/ffmpeg
   ```

2. **Video thumbnails not generating**
   - Check FFmpeg permissions
   - Verify video file format is supported
   - Check MediaWiki error logs

3. **PDF previews not working**
   - Ensure GhostScript is installed (usually included with MediaWiki)
   - Check file permissions on uploads directory

4. **Large file uploads failing**
   - Verify PHP upload limits are configured correctly
   - Check available disk space
   - Review web server timeout settings

### Debug Mode
Enable detailed error reporting:
```php
$wgShowExceptionDetails = true;
$wgDebugComments = true;
$wgShowDebug = true;
```

## Performance Optimization

### Thumbnail Generation
- **Async processing**: Large video thumbnails are generated in background
- **Caching**: Generated thumbnails are cached for performance
- **Format optimization**: Automatic format conversion for web display

### Best Practices
1. **Optimize media files** before upload when possible
2. **Use appropriate dimensions** for embedded videos
3. **Enable caching** for frequently accessed files
4. **Monitor disk space** usage for media files

## Version Compatibility

### MediaWiki Requirements
- **MediaWiki**: 1.44+ (current installation)
- **PHP**: 8.1+ (satisfied)
- **EmbedVideo**: Requires MediaWiki >= 1.43.0 ✅

### Extension Versions
- **PdfHandler**: Included with MediaWiki 1.44
- **MultimediaViewer**: Included with MediaWiki 1.44
- **EmbedVideo**: Latest from StarCitizenWiki fork (privacy-enhanced)

## Advanced Configuration

### Custom Video Players
```php
# Advanced EmbedVideo configuration
$wgEmbedVideoAddFileExtensions = true;    # Enable file extension handling
$wgEmbedVideoLazyLoadLocalVideos = false; # Disable lazy loading for local videos
$wgEmbedVideoFetchExternalThumbnails = false; # Privacy: disable external thumbnails
```

### PDF Handler Settings
```php
# PDF processing configuration
$wgMaxImageArea = 1.25e7;              # Maximum image area for processing
$wgMaxShellMemory = 512000;            # Memory limit for image processing
$wgMaxShellFileSize = 512000;          # File size limit for processing
```

## Integration Examples

### Creating a Media Gallery Page
```wikitext
= Company Presentations =

== Video Presentations ==
{{#ev:youtube|companyVideoID|640|360}}

== PDF Documents ==
[[File:annual_report.pdf|thumb|300px|Annual Report 2024]]
[[File:company_brochure.pdf|thumb|300px|Company Brochure]]

== Image Gallery ==
<gallery mode="packed" heights="200px">
File:office_photo1.jpg|Main Office
File:team_photo.jpg|Our Team
File:product_showcase.jpg|Product Line
</gallery>

== Audio Content ==
[[File:podcast_episode1.mp3|Company Podcast Episode 1]]
```

### Documentation with Mixed Media
```wikitext
= User Manual =

== Quick Start Video ==
{{#ev:youtube|tutorialVideoID}}

== Complete Manual ==
[[File:user_manual.pdf|Download PDF Manual]]

== Step-by-Step Screenshots ==
<gallery>
File:step1.png|Step 1: Login
File:step2.png|Step 2: Navigation
File:step3.png|Step 3: Settings
</gallery>
```

## References

- [MediaWiki Manual: File uploads](https://www.mediawiki.org/wiki/Manual:Configuring_file_uploads)
- [Extension:EmbedVideo Documentation](https://www.mediawiki.org/wiki/Extension:EmbedVideo)
- [Extension:PdfHandler](https://www.mediawiki.org/wiki/Extension:PdfHandler)
- [Extension:MultimediaViewer](https://www.mediawiki.org/wiki/Extension:MultimediaViewer)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)