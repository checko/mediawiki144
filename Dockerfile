FROM mediawiki:1.44

# Install required tools and diagram dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    graphviz \
    mscgen \
    default-jre-headless \
    wget \
    ffmpeg \
    ghostscript \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Install PlantUML
RUN wget -O /usr/local/bin/plantuml.jar https://github.com/plantuml/plantuml/releases/download/v1.2024.0/plantuml-1.2024.0.jar && \
    echo '#!/bin/bash\njava -jar /usr/local/bin/plantuml.jar "$@"' > /usr/local/bin/plantuml && \
    chmod +x /usr/local/bin/plantuml

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clone WikiMarkdown extension from forked repository with MediaWiki 1.44 fixes
RUN cd /var/www/html/extensions && \
    git clone -b mediawiki-1.44-compatibility https://github.com/checko/WikiMarkdown.git WikiMarkdown

# Install MsUpload extension for multiple file uploads
RUN cd /var/www/html/extensions && \
    git clone https://github.com/wikimedia/mediawiki-extensions-MsUpload.git MsUpload

# Install Diagrams extension for diagram drawing functionality (MediaWiki 1.44 compatible version)
RUN cd /var/www/html/extensions && \
    git clone -b mediawiki-1.44-compatible https://github.com/checko/diagrams-extension.git Diagrams

# Install EmbedVideo extension for video/audio embedding
RUN cd /var/www/html/extensions && \
    git clone https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo.git EmbedVideo

# Install dependencies using composer
RUN cd /var/www/html/extensions/WikiMarkdown && \
    composer install --no-dev --ignore-platform-reqs


# Configure PHP for large file uploads (500MB)
RUN echo "upload_max_filesize = 500M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 500M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 1G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_file_uploads = 20" >> /usr/local/etc/php/conf.d/uploads.ini

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/extensions/WikiMarkdown && \
    chown -R www-data:www-data /var/www/html/extensions/Diagrams && \
    chown -R www-data:www-data /var/www/html/extensions/EmbedVideo

# Expose port 80
EXPOSE 80