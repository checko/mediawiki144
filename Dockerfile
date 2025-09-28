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

# Install dependencies using composer
RUN cd /var/www/html/extensions/WikiMarkdown && \
    composer install --no-dev --ignore-platform-reqs

# Fix MediaWiki 1.44 compatibility issue in WikiMarkdown extension
RUN sed -i 's/public static function onContentHandlerDefaultModelFor( Title \$title, &\$model )/public static function onContentHandlerDefaultModelFor( $title, \&$model )/' \
    /var/www/html/extensions/WikiMarkdown/includes/WikiMarkdown.php

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/extensions/WikiMarkdown

# Expose port 80
EXPOSE 80