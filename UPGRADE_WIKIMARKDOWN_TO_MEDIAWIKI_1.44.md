# Upgrading WikiMarkdown Extension to MediaWiki 1.44

This document provides a comprehensive guide for upgrading the WikiMarkdown extension to work with MediaWiki 1.44. The upgrade addresses several breaking changes in MediaWiki 1.44's namespace structure and deprecated methods.

## Overview

MediaWiki 1.44 introduced significant changes that break compatibility with older extensions:
- Classes moved to new namespaces
- Deprecated methods removed
- ResourceLoader module changes
- Stricter type checking

## Issues and Solutions

### 1. Missing Composer Autoloader

**Issue**: ParsedownExtended class not found
```
Error: Class "ParsedownExtended" not found
```

**Root Cause**: The WikiMarkdown extension installs Parsedown dependencies via composer but doesn't load the autoloader.

**Solution**: Add composer autoloader include at the beginning of `WikiMarkdown.php`

```php
<?php

require_once __DIR__ . "/../vendor/autoload.php";

class WikiMarkdown {
    // ... rest of class
}
```

### 2. Type Hint Compatibility Issues

**Issue**: TypeError with Title class parameter
```
TypeError: WikiMarkdown::onContentHandlerDefaultModelFor(): Argument #1 ($title) must be of type Title, MediaWiki\Title\Title given
```

**Root Cause**: MediaWiki 1.44 passes namespaced class instances but extension expects old class names.

**Solution**: Remove strict type hints from hook methods

**Before:**
```php
public static function onContentHandlerDefaultModelFor( Title $title, &$model ) {
```

**After:**
```php
public static function onContentHandlerDefaultModelFor( $title, &$model ) {
```

**Apply to these methods:**
- `onContentHandlerDefaultModelFor`
- `onCodeEditorGetPageLanguage`

### 3. Linker Class Namespace Change

**Issue**: Linker class not found
```
Error: Class "Linker" not found
```

**Root Cause**: Linker class moved to `MediaWiki\Linker\Linker` namespace.

**Solution**: Add namespace import
```php
use MediaWiki\Linker\Linker;
```

### 4. Html Class Namespace Change

**Issue**: Html class not found
```
Error: Class "Html" not found
```

**Root Cause**: Html class moved to `MediaWiki\Html\Html` namespace.

**Solution**: Add namespace import
```php
use MediaWiki\Html\Html;
```

### 5. Deprecated Linker::makeHeadline Method

**Issue**: Undefined method makeHeadline
```
Error: Call to undefined method MediaWiki\Linker\Linker::makeHeadline()
```

**Root Cause**: `makeHeadline` method removed from MediaWiki 1.44.

**Solution**: Replace with manual HTML generation

**Before:**
```php
return Linker::makeHeadline($matches[1], '>', $anchor, $matches[4], '');
```

**After:**
```php
return "<h{$matches[1]} id=\"{$anchor}\">{$matches[4]}</h{$matches[1]}>";
```

### 6. ResourceLoader Module Namespace Issues

**Issue**: ResourceLoaderFileModule not found
```
Error: Class "ResourceLoaderFileModule" not found
```

**Root Cause**: ResourceLoader classes moved to new namespaces in MediaWiki 1.44.

**Solution**: Update `ResourceLoaderWikiMarkdownVisualEditorModule.php`

**Before:**
```php
<?php

class ResourceLoaderWikiMarkdownVisualEditorModule extends ResourceLoaderFileModule {
    public function getScript( ResourceLoaderContext $context ) {
        // ...
    }
}
```

**After:**
```php
<?php
use MediaWiki\ResourceLoader\FileModule;
use MediaWiki\ResourceLoader\Context;

class ResourceLoaderWikiMarkdownVisualEditorModule extends FileModule {
    public function getScript( Context $context ) {
        // ...
    }
}
```

## Complete Fix Implementation

### Method 1: Manual File Editing

1. **Edit `includes/WikiMarkdown.php`:**

```php
<?php

use MediaWiki\Linker\Linker;
use MediaWiki\Html\Html;
require_once __DIR__ . "/../vendor/autoload.php";

class WikiMarkdown {
    // ... existing code ...

    // Remove Title type hints from these methods:
    public static function onContentHandlerDefaultModelFor( $title, &$model ) {
        // Match .md pages.
        if ( preg_match( '/\.md$/i', $title->getText() ) && $title->isContentPage() ) {
            $model = CONTENT_MODEL_MARKDOWN;
            return false;
        }
        return true;
    }

    public static function onCodeEditorGetPageLanguage( $title, &$languageCode ) {
        if ( !ExtensionRegistry::getInstance()->isLoaded( 'CodeEditor' ) ) {
            return true;
        }
        if ( $title->hasContentModel( CONTENT_MODEL_MARKDOWN ) ) {
            $languageCode = 'markdown';
            return false;
        }
        return true;
    }

    // Replace makeHeadline usage around line 89:
    // Find this line and replace:
    // return Linker::makeHeadline($matches[1], '>', $anchor, $matches[4], '');
    // With:
    // return "<h{$matches[1]} id=\"{$anchor}\">{$matches[4]}</h{$matches[1]}>";
}
```

2. **Edit `includes/ResourceLoaderWikiMarkdownVisualEditorModule.php`:**

```php
<?php
use MediaWiki\ResourceLoader\FileModule;
use MediaWiki\ResourceLoader\Context;

class ResourceLoaderWikiMarkdownVisualEditorModule extends FileModule {
    protected $targets = [ 'desktop', 'mobile' ];

    public function getScript( Context $context ) {
        $scripts = parent::getScript( $context );
        return $scripts;
    }

    public function enableModuleContentVersion() {
        return true;
    }

    public function supportsURLLoading() {
        return false;
    }
}
```

### Method 2: Automated Docker Build

Add these commands to your Dockerfile after composer install:

```dockerfile
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

# Fix ResourceLoader module
RUN sed -i '2,3c\
use MediaWiki\\ResourceLoader\\FileModule;\
use MediaWiki\\ResourceLoader\\Context;' \
    /var/www/html/extensions/WikiMarkdown/includes/ResourceLoaderWikiMarkdownVisualEditorModule.php && \
    sed -i 's/extends ResourceLoaderFileModule/extends FileModule/' \
    /var/www/html/extensions/WikiMarkdown/includes/ResourceLoaderWikiMarkdownVisualEditorModule.php && \
    sed -i 's/ResourceLoaderContext \$context/Context $context/g' \
    /var/www/html/extensions/WikiMarkdown/includes/ResourceLoaderWikiMarkdownVisualEditorModule.php
```

## Verification Steps

After applying the fixes, verify the extension works:

1. **Check Extension Loading:**
   ```bash
   # No errors in MediaWiki logs
   docker logs mediawiki-container 2>&1 | grep -i error
   ```

2. **Test Markdown Rendering:**
   - Create a page with markdown content using `<markdown>` tags
   - Verify headers, bold, italic text render correctly
   - Check that heading IDs are generated properly

3. **Test VisualEditor Integration:**
   - Ensure VisualEditor loads without JavaScript errors
   - Verify WikiMarkdown VisualEditor module loads:
     ```
     http://your-wiki/load.php?modules=ext.wikimarkdown.visualEditor
     ```

4. **Test Core Functionality:**
   - Create account page works
   - Edit pages work without errors
   - Special pages function correctly

## Configuration Requirements

Ensure your `LocalSettings.php` includes:

```php
# WikiMarkdown extension configuration
wfLoadExtension( 'WikiMarkdown' );
$wgAllowMarkdownExtra = true;
$wgAllowMarkdownExtended = true;

# VisualEditor configuration (if using VisualEditor)
wfLoadExtension( 'VisualEditor' );
$wgDefaultUserOptions['visualeditor-enable'] = 1;
$wgVisualEditorAvailableNamespaces = [
    NS_MAIN => true,
    NS_USER => true,
    NS_PROJECT => true,
    NS_HELP => true,
    NS_CATEGORY => true
];
```

## Troubleshooting

### Common Issues

1. **"Class not found" errors**: Ensure all namespace imports are added correctly
2. **"Method not found" errors**: Check that deprecated method calls are replaced
3. **Composer autoloader issues**: Verify `vendor/autoload.php` exists and is included
4. **Cache issues**: Clear MediaWiki cache after making changes

### Debug Mode

Enable debug mode to see detailed error messages:
```php
$wgShowExceptionDetails = true;
$wgDebugComments = true;
$wgShowDebug = true;
```

## Testing Checklist

- [ ] Extension loads without errors
- [ ] Markdown parsing works (headers, bold, italic)
- [ ] Heading IDs are generated correctly
- [ ] VisualEditor integration works
- [ ] No JavaScript console errors
- [ ] Create account page works
- [ ] Edit pages work
- [ ] Special pages function

## Dependencies

The WikiMarkdown extension requires:
- MediaWiki 1.44+
- PHP 8.1+
- Composer dependencies:
  - erusev/parsedown: ^1.8.0-beta-7
  - erusev/parsedown-extra: ^0.8.1
  - benjaminhoegh/parsedown-extended: 1.1.2

## Additional Notes

- These fixes maintain backward compatibility where possible
- The extension should work with both MediaWiki 1.44 and future versions
- Consider contributing these fixes back to the original WikiMarkdown repository
- Regular testing is recommended when upgrading MediaWiki versions

## References

- [MediaWiki 1.44 Release Notes](https://www.mediawiki.org/wiki/MediaWiki_1.44)
- [MediaWiki Extension Migration Guide](https://www.mediawiki.org/wiki/Manual:Developing_extensions)
- [WikiMarkdown Extension Repository](https://github.com/kuenzign/WikiMarkdown)