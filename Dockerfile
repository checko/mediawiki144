FROM mediawiki:1.44

# Install required tools
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clone WikiMarkdown extension from correct repository
RUN cd /var/www/html/extensions && \
    git clone https://github.com/kuenzign/WikiMarkdown.git WikiMarkdown

# Install MsUpload extension for multiple file uploads
RUN cd /var/www/html/extensions && \
    git clone https://github.com/wikimedia/mediawiki-extensions-MsUpload.git MsUpload

# Install dependencies using composer
RUN cd /var/www/html/extensions/WikiMarkdown && \
    composer install --no-dev --ignore-platform-reqs

# Fix MediaWiki 1.44 compatibility issues in WikiMarkdown extension
RUN sed -i 's/public static function onContentHandlerDefaultModelFor( Title \$title, &\$model )/public static function onContentHandlerDefaultModelFor( $title, \&$model )/' \
    /var/www/html/extensions/WikiMarkdown/includes/WikiMarkdown.php && \
    sed -i 's/public static function onCodeEditorGetPageLanguage( Title \$title, &\$languageCode )/public static function onCodeEditorGetPageLanguage( $title, \&$languageCode )/' \
    /var/www/html/extensions/WikiMarkdown/includes/WikiMarkdown.php && \
    sed -i '2i\\nrequire_once __DIR__ . "/../vendor/autoload.php";' \
    /var/www/html/extensions/WikiMarkdown/includes/WikiMarkdown.php && \
    sed -i '3i\use MediaWiki\\Linker\\Linker;' \
    /var/www/html/extensions/WikiMarkdown/includes/WikiMarkdown.php && \
    sed -i '4i\use MediaWiki\\Html\\Html;' \
    /var/www/html/extensions/WikiMarkdown/includes/WikiMarkdown.php && \
    sed -i 's/return Linker::makeHeadline.*$/return "<h{$matches[1]} id=\"{$anchor}\">{$matches[4]}<\/h{$matches[1]}>";/' \
    /var/www/html/extensions/WikiMarkdown/includes/WikiMarkdown.php

# Configure PHP for large file uploads (500MB)
RUN echo "upload_max_filesize = 500M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 500M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 1G" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_file_uploads = 20" >> /usr/local/etc/php/conf.d/uploads.ini

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/extensions/WikiMarkdown

# Expose port 80
EXPOSE 80