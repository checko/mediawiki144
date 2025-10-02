# Deprecated Scripts

## fix-chinese-image-names.sh.deprecated

**Status:** Deprecated - Do NOT use in production

**Why deprecated:**
This script used hardcoded filename mappings and file sizes that only worked for ONE specific backup. Examples:

```bash
# Hardcoded translation mapping - only works for this backup
fix_file "9/93/keyboard.jpg" "9/93/多個鍵盤.jpg"

# Hardcoded file size - only works for this backup
SRC=$(find e/e8/ -type f -size 72354c 2>/dev/null | head -1)

# Hardcoded date pattern - only works for files with this exact date
fix_file "9/92/*PM_03-17-02.jpg" "9/92/2011-1-5_下午_03-17-02.jpg"
```

**Replacement:**
Use `fix-missing-images-dynamic.sh` which:
- Works with ANY backup (not just one)
- Dynamically queries database for missing files
- Uses generic pattern matching instead of hardcoded mappings
- Automatically handles new/different images

**Kept for reference only:**
This file is preserved to show what issues were found in the original backup, but should not be used in production.
