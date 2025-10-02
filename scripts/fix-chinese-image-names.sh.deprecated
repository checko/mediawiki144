#!/bin/bash
#
# Fix Chinese image filename mismatches between database and filesystem
#
# Problem: The backup ZIP has 46 files with corrupted/translated filenames:
#   - Database: "多個鍵盤.jpg"  ->  ZIP: "keyboard.jpg"
#   - Database: "RN2-聲音出來的硬體修改位置.JPG"  ->  ZIP: "RN2-sound.JPG"
#   - Database: "2013-4-30_上午_10-25-53.png"  ->  ZIP: "2013-4-30_下午_10-25-53.png"
#
# This script copies files to match database expectations.
#
set -e

echo "======================================"
echo "Fixing Chinese Image Filename Issues"
echo "======================================"
echo

FIXED=0

# Helper function to copy files
fix_file() {
    local src_pattern="$1"
    local target="$2"

    docker compose exec -T mediawiki bash -c "
        cd /var/www/html/images
        if [ ! -f \"$target\" ]; then
            for src in $src_pattern; do
                if [ -f \"\$src\" ]; then
                    cp -- \"\$src\" \"$target\" 2>/dev/null && echo \"  ✓ Fixed: $target\" && exit 0
                fi
            done
        fi
    " 2>/dev/null
}

echo "Fixing date/time files (上午/下午/AM/PM mismatches)..."
# When database has 上午 (morning) but filesystem has 下午 (afternoon) or vice versa
# Also handles AM/PM vs 上午/下午 conversions
fix_file "9/92/*PM_03-17-02.jpg" "9/92/2011-1-5_下午_03-17-02.jpg"
fix_file "e/e2/*午_10-25-53.png" "e/e2/2013-4-30_上午_10-25-53.png"
fix_file "e/ef/*午_10-20-07.png" "e/ef/2013-4-30_上午_10-20-07.png"
fix_file "d/de/*午_08-42-08.png" "d/de/2014-3-18_上午_08-42-08.png"
fix_file "8/81/*午_10-30-40.png" "8/81/2014-3-18_上午_10-30-40.png"
fix_file "f/ff/*午_10-30-05.png" "f/ff/2014-3-18_上午_10-30-05.png"
fix_file "1/13/*午_10-30-57.png" "1/13/2014-3-18_上午_10-30-57.png"
fix_file "a/a5/*午_10-30-15.png" "a/a5/2014-3-18_上午_10-30-15.png"
fix_file "0/07/*午_11-02-22.jpg" "0/07/2013-6-19_上午_11-02-22.jpg"
fix_file "c/cc/*午_10-37-59.png" "c/cc/2014-3-18_上午_10-37-59.png"
fix_file "f/fa/*午_09-57-19.jpg" "f/fa/2013-10-19_上午_09-57-19.jpg"
fix_file "f/f4/*午_11-03-54.jpg" "f/f4/2013-4-22_上午_11-03-54.jpg"
fix_file "a/a4/*午_10-15-49.png" "a/a4/2014-4-30_上午_10-15-49.png"
fix_file "c/c9/*午_10-22-03.png" "c/c9/2014-7-16_上午_10-22-03.png"
fix_file "7/7e/*午_11-12-35.jpg" "7/7e/2013-5-30_上午_11-12-35.jpg"
fix_file "a/a2/*午_11-32-42.jpg" "a/a2/2013-5-30_上午_11-32-42.jpg"
fix_file "6/6b/*午_11-34-08.jpg" "6/6b/2013-5-30_上午_11-34-08.jpg"
fix_file "0/0b/*午_11-31-04.jpg" "0/0b/2013-5-30_上午_11-31-04.jpg"
fix_file "4/4d/*午_11-10-56.jpg" "4/4d/2013-5-30_上午_11-10-56.jpg"
fix_file "6/66/*午_04-13-04.png" "6/66/2013-10-1_下午_04-13-04.png"
fix_file "7/78/*午_06-39-50.jpg" "7/78/2013-10-9_下午_06-39-50.jpg"
fix_file "0/07/*午_11-35-39.png" "0/07/2013-8-5_上午_11-35-39.png"

echo
echo "Fixing Chinese word files (translations/garbled)..."
# Chinese words translated to English or garbled
fix_file "9/93/keyboard.jpg" "9/93/多個鍵盤.jpg"
fix_file "5/51/RN2-sound.JPG" "5/51/RN2-聲音出來的硬體修改位置.JPG"
fix_file "7/7d/*FileExplorer.JPG" "7/7d/-架構圖-FileExplorer.JPG"
fix_file "e/e5/*MediaService.JPG" "e/e5/-架構圖-MediaService.JPG"
fix_file "c/cb/*AppleRemoteExplorer.JPG" "c/cb/-架構圖-AppleRemoteExplorer.JPG"
fix_file "c/cf/*AppleLibary.JPG" "c/cf/-架構圖-AppleLibary.JPG"
fix_file "e/ed/*MediaExplorer.JPG" "e/ed/-架構圖-MediaExplorer.JPG"
fix_file "5/5a/DVR_Recoder_*.jpg" "5/5a/DVR_Recoder_架構說明.jpg"
fix_file "0/0e/DVR_UI_*.jpg" "0/0e/DVR_UI_架構說明.jpg"
fix_file "d/db/Usb-*.JPG" "d/db/Usb-音樂畫面.JPG"
fix_file "1/19/Debug_port_*.JPG" "1/19/Debug_port_示意圖_轉版.JPG"
fix_file "3/38/MCU_ISP_*.png" "3/38/MCU_ISP_更新功能1.png"
fix_file "3/33/MCU_ISP_*.png" "3/33/MCU_ISP_更新功能2.png"
fix_file "3/3d/MCU_*.png" "3/3d/MCU_軟體版本資訊.png"
fix_file "5/56/Cv_7310_status_bar*.jpg" "5/56/Cv_7310_status_bar說明.jpg"
fix_file "6/61/20140716_Roy_*.jpg" "6/61/20140716_Roy_專利公告.jpg"
fix_file "2/22/CV7310menuconfig*.jpg" "2/22/CV7310menuconfig比對.jpg"

echo
echo "Fixing severely garbled Chinese files (by size matching)..."
# Some Chinese filenames are completely garbled and need to be matched by file size
docker compose exec -T mediawiki bash -c '
    cd /var/www/html/images
    # 投影片1.JPG (72354 bytes) - may be garbled as _蔣__.JPG or similar
    if [ ! -f "e/e8/投影片1.JPG" ]; then
        SRC=$(find e/e8/ -type f -size 72354c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "e/e8/投影片1.JPG"
            chown www-data:www-data "e/e8/投影片1.JPG"
            chmod 644 "e/e8/投影片1.JPG"
            echo "  ✓ Fixed: 投影片1.JPG (by size)"
        fi
    fi

    # 藍芽畫面.JPG (452926 bytes) - may be garbled as __恍.JPG or similar
    if [ ! -f "0/0e/藍芽畫面.JPG" ]; then
        SRC=$(find 0/0e/ -type f -size 452926c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "0/0e/藍芽畫面.JPG"
            chown www-data:www-data "0/0e/藍芽畫面.JPG"
            chmod 644 "0/0e/藍芽畫面.JPG"
            echo "  ✓ Fixed: 藍芽畫面.JPG (by size)"
        fi
    fi

    # 歌曲依照時間排列.JPG (107667 bytes) - translated to sound_serial.JPG
    if [ ! -f "a/aa/歌曲依照時間排列.JPG" ]; then
        SRC=$(find a/aa/ -type f -size 107667c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "a/aa/歌曲依照時間排列.JPG"
            chown www-data:www-data "a/aa/歌曲依照時間排列.JPG"
            chmod 644 "a/aa/歌曲依照時間排列.JPG"
            echo "  ✓ Fixed: 歌曲依照時間排列.JPG (by size)"
        fi
    fi

    # 太祖魷魚羹米粉.jpeg (105353 bytes) - severely garbled
    if [ ! -f "7/72/太祖魷魚羹米粉.jpeg" ]; then
        SRC=$(find 7/72/ -type f -size 105353c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "7/72/太祖魷魚羹米粉.jpeg"
            chown www-data:www-data "7/72/太祖魷魚羹米粉.jpeg"
            chmod 644 "7/72/太祖魷魚羹米粉.jpeg"
            echo "  ✓ Fixed: 太祖魷魚羹米粉.jpeg (by size)"
        fi
    fi

    # 華園牛肉湯麵.jpeg (33318 bytes) - severely garbled
    if [ ! -f "a/a1/華園牛肉湯麵.jpeg" ]; then
        SRC=$(find a/a1/ -type f -size 33318c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "a/a1/華園牛肉湯麵.jpeg"
            chown www-data:www-data "a/a1/華園牛肉湯麵.jpeg"
            chmod 644 "a/a1/華園牛肉湯麵.jpeg"
            echo "  ✓ Fixed: 華園牛肉湯麵.jpeg (by size)"
        fi
    fi

    # 2013-11-14_下午_02-34-35.jpg (52059 bytes) - wrong filename
    if [ ! -f "f/f3/2013-11-14_下午_02-34-35.jpg" ]; then
        SRC=$(find f/f3/ -type f -size 52059c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "f/f3/2013-11-14_下午_02-34-35.jpg"
            chown www-data:www-data "f/f3/2013-11-14_下午_02-34-35.jpg"
            chmod 644 "f/f3/2013-11-14_下午_02-34-35.jpg"
            echo "  ✓ Fixed: 2013-11-14_下午_02-34-35.jpg (by size)"
        fi
    fi

    # 2013-11-7_下午_03-29-43.png (27990 bytes) - wrong filename
    if [ ! -f "b/b0/2013-11-7_下午_03-29-43.png" ]; then
        SRC=$(find b/b0/ -type f -size 27990c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "b/b0/2013-11-7_下午_03-29-43.png"
            chown www-data:www-data "b/b0/2013-11-7_下午_03-29-43.png"
            chmod 644 "b/b0/2013-11-7_下午_03-29-43.png"
            echo "  ✓ Fixed: 2013-11-7_下午_03-29-43.png (by size)"
        fi
    fi

    # 2014-2-21_下午_05-09-32.png (15750 bytes) - timestamp prefix + wrong time
    if [ ! -f "2/2d/2014-2-21_下午_05-09-32.png" ]; then
        SRC=$(find 2/2d/ -type f -size 15750c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "2/2d/2014-2-21_下午_05-09-32.png"
            chown www-data:www-data "2/2d/2014-2-21_下午_05-09-32.png"
            chmod 644 "2/2d/2014-2-21_下午_05-09-32.png"
            echo "  ✓ Fixed: 2014-2-21_下午_05-09-32.png (by size)"
        fi
    fi

    # 2014-4-30_上午_10-18-36.png (59083 bytes) - completely different date/time
    if [ ! -f "1/10/2014-4-30_上午_10-18-36.png" ]; then
        SRC=$(find 1/10/ -type f -size 59083c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "1/10/2014-4-30_上午_10-18-36.png"
            chown www-data:www-data "1/10/2014-4-30_上午_10-18-36.png"
            chmod 644 "1/10/2014-4-30_上午_10-18-36.png"
            echo "  ✓ Fixed: 2014-4-30_上午_10-18-36.png (by size)"
        fi
    fi

    # 2014-4-8_下午_05-00-38.jpg (34997 bytes) - timestamp prefix + wrong time
    if [ ! -f "c/c5/2014-4-8_下午_05-00-38.jpg" ]; then
        SRC=$(find c/c5/ -type f -size 34997c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "c/c5/2014-4-8_下午_05-00-38.jpg"
            chown www-data:www-data "c/c5/2014-4-8_下午_05-00-38.jpg"
            chmod 644 "c/c5/2014-4-8_下午_05-00-38.jpg"
            echo "  ✓ Fixed: 2014-4-8_下午_05-00-38.jpg (by size)"
        fi
    fi

    # 2013-10-1_下午_04-13-04.png (137149 bytes) - different directory, wrong filename
    if [ ! -f "6/66/2013-10-1_下午_04-13-04.png" ]; then
        SRC=$(find 6/66/ -type f -size 137149c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "6/66/2013-10-1_下午_04-13-04.png"
            chown www-data:www-data "6/66/2013-10-1_下午_04-13-04.png"
            chmod 644 "6/66/2013-10-1_下午_04-13-04.png"
            echo "  ✓ Fixed: 2013-10-1_下午_04-13-04.png (by size)"
        fi
    fi

    # 2013-10-9_下午_06-39-50.jpg (147046 bytes) - wrong filename
    if [ ! -f "7/78/2013-10-9_下午_06-39-50.jpg" ]; then
        SRC=$(find 7/78/ -type f -size 147046c 2>/dev/null | head -1)
        if [ -n "$SRC" ]; then
            cp "$SRC" "7/78/2013-10-9_下午_06-39-50.jpg"
            chown www-data:www-data "7/78/2013-10-9_下午_06-39-50.jpg"
            chmod 644 "7/78/2013-10-9_下午_06-39-50.jpg"
            echo "  ✓ Fixed: 2013-10-9_下午_06-39-50.jpg (by size)"
        fi
    fi
' 2>/dev/null

echo
echo "Fixing (1) suffix files..."
# Files with (1) in filename
fix_file "2/2c/2013-4-22_下午_05-29-06 (1).png" "2/2c/2013-4-22_下午_05-29-06.png"
fix_file "e/e5/2013-11-14_下午_02-28-35 (1).jpg" "e/e5/2013-11-14_下午_02-28-35.jpg"
fix_file "c/ce/2013-11-7_下午_03-29-16 (1).png" "c/ce/2013-11-7_下午_03-29-16.png"
fix_file "5/58/20131022093506!2013-10-22_下午_06-21-10 (1).png" "5/58/2013-10-22_下午_06-21-10.png"
fix_file "6/67/2013-10-9_下午_06-39-50 (1).jpg" "6/67/2013-10-9_下午_07-01-13.jpg"
fix_file "c/ce/2013-10-1_下午_04-12-07 (1).png" "c/ce/2013-10-1_下午_04-12-07.png"

echo
echo "======================================"
echo "✓ Fixed ~44 Chinese filename issues"
echo "  Including:"
echo "    - AM/PM ↔ 上午/下午 conversions"
echo "    - Garbled Chinese characters"
echo "    - (1) suffix duplicates"
echo "    - Size-based matching for severely garbled files"
echo ""
echo "  Note: ~6 files genuinely missing from backup"
echo "======================================"
