# Chinese Image Filename Fix

## Problem

During the MediaWiki backup/restoration process, some Chinese-named image files had encoding issues. The database contains the correct Chinese filenames, but the actual files in the ZIP archive have garbled characters due to encoding problems (likely cp950/big5 encoding issues).

### Examples of Affected Files:

| Database Name (Correct) | Filesystem Name (Garbled) |
|-------------------------|---------------------------|
| RN2-聲音出來的硬體修改位置.JPG | RN2-sound.JPG |
| -架構圖-FileExplorer.JPG | -_嗆___FileExplorer.JPG |
| DVR_Recoder_架構說明.jpg | DVR_Recoder_嗆_隤芣_.jpg |
| Usb-音樂畫面.JPG | Usb-_單__恍.JPG |

## Solution

The fix creates copies of the garbled files with their correct Chinese names, so MediaWiki can find them when looking up database records.

## How to Fix

### Automatic (Recommended)

The fix is now integrated into `restore.sh`. It will automatically run after image restoration:

```bash
./restore.sh
```

### Manual

If you need to fix Chinese filenames separately:

```bash
./scripts/fix-all-chinese-images.sh
```

### Verification

Check if all Chinese files exist:

```bash
./scripts/check-chinese-filenames.sh
```

Expected output: All files should show ✓ (EXISTS)

## Files Fixed

The script fixes these known problematic files:

1. **架構圖 (architecture diagram) files (5 files)**
   - `-架構圖-FileExplorer.JPG`
   - `-架構圖-MediaService.JPG`
   - `-架構圖-AppleRemoteExplorer.JPG`
   - `-架構圖-AppleLibary.JPG`
   - `-架構圖-MediaExplorer.JPG`

2. **架構說明 (description) files (2 files)**
   - `DVR_Recoder_架構說明.jpg`
   - `DVR_UI_架構說明.jpg`

3. **聲音 (sound) files (1 file)**
   - `RN2-聲音出來的硬體修改位置.JPG`

4. **音樂 (music) files (1 file)**
   - `Usb-音樂畫面.JPG`

5. **其他 (other) files (1 file)**
   - `ALSA聲音大小聲介面.jpg`

**Total: 39+ files fixed automatically**

## Coverage

- **Original issue:** 46 Chinese-named files missing
- **Automatically fixed:** 39 files
- **Remaining:** 7 files (files genuinely missing from backup)

### Categories Fixed

1. **上午/下午 (morning/afternoon) mismatches:** ~25 files
   - Database had "上午" but filesystem had "下午" or vice versa
   - Likely caused by timezone conversion during backup

2. **Chinese-to-English translations:** ~14 files
   - Examples: "多個鍵盤" → "keyboard", "架構圖" → garbled characters

### Known Limitations

The following 7 files cannot be automatically fixed as they don't exist in the backup:
- `2014-2-21_下午_05-09-32.png`
- `2013-11-7_下午_03-29-43.png`
- `2014-4-8_下午_05-00-38.jpg`
- `2013-11-14_下午_02-34-35.jpg`
- `2014-4-30_上午_10-18-36.png`
- `2011-1-5_下午_03-17-02.jpg`
- `2013-10-1_下午_04-13-04.png`

These files were likely never included in the original backup or were deleted.

## Technical Details

### Why This Happens

1. The original MediaWiki 1.31 database was created with UTF-8 encoding
2. When the images ZIP was created, filenames were converted to cp950/big5 encoding (Traditional Chinese Windows encoding)
3. Some characters don't have exact equivalents, resulting in garbled names
4. MediaWiki calculates file paths using MD5 of the filename from the database
5. Without matching filenames, MediaWiki can't find the files

### How the Fix Works

1. The script identifies garbled filenames by pattern matching
2. It copies each garbled file to a new file with the correct Chinese name
3. Both files exist (no deletion), ensuring no data loss
4. MediaWiki can now find files using database names

### File Path Calculation

MediaWiki stores images in a hash-based directory structure:

```
images/{md5[0]}/{md5[0:2]}/{filename}
```

For example: `RN2-聲音出來的硬體修改位置.JPG`
- MD5: `5158f4f83f26702001dcbd8e3de53565`
- Path: `images/5/51/RN2-聲音出來的硬體修改位置.JPG`

## Testing

To verify the fix worked, visit these URLs (replace with your server):

```
http://localhost:8050/index.php/檔案:RN2-聲音出來的硬體修改位置.JPG
http://localhost:8050/index.php/檔案:-架構圖-FileExplorer.JPG
http://localhost:8050/index.php/檔案:Usb-音樂畫面.JPG
```

All pages should load correctly and display the images.

## Future Improvements

If you encounter more Chinese filename issues:

1. Check the database for Chinese filenames:
   ```sql
   SELECT img_name FROM image WHERE img_name LIKE '%中文字%';
   ```

2. Find the actual garbled filename in the filesystem:
   ```bash
   docker compose exec mediawiki ls /var/www/html/images/{hash1}/{hash2}/
   ```

3. Add the mapping to `fix-all-chinese-images.sh`

## Related Scripts

- `restore.sh` - Main restoration script (includes Chinese fix)
- `scripts/fix-all-chinese-images.sh` - Chinese filename fix script
- `scripts/check-chinese-filenames.sh` - Verification script
- `scripts/extract-images.py` - Image extraction with encoding support
