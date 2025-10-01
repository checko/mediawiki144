#!/usr/bin/env python3
"""
Find ALL missing image files by checking database against filesystem.
"""

import subprocess
import hashlib
import sys

def get_db_images():
    """Get all image names from database"""
    result = subprocess.run(
        ['docker', 'compose', 'exec', '-T', 'mysql',
         'mysql', '-u', 'root', '-proot_password', '-se',
         'USE mediawiki; SELECT img_name FROM image;'],
        capture_output=True,
        text=True
    )
    return [line.strip() for line in result.stdout.split('\n') if line.strip()]

def file_exists(path):
    """Check if file exists in container"""
    result = subprocess.run(
        ['docker', 'compose', 'exec', '-T', 'mediawiki', 'test', '-f', path],
        capture_output=True
    )
    return result.returncode == 0

def get_image_path(filename):
    """Calculate MediaWiki image path"""
    md5 = hashlib.md5(filename.encode('utf-8')).hexdigest()
    return f"/var/www/html/images/{md5[0]}/{md5[:2]}/{filename}"

def has_chinese(text):
    """Check if text contains Chinese characters"""
    return any('\u4e00' <= char <= '\u9fff' for char in text)

def list_dir(dir_path):
    """List files in directory"""
    result = subprocess.run(
        ['docker', 'compose', 'exec', '-T', 'mediawiki', 'ls', '-1', dir_path],
        capture_output=True,
        text=True
    )
    if result.returncode == 0:
        return [f.strip() for f in result.stdout.split('\n') if f.strip()]
    return []

def main():
    print("Getting all images from database...")
    db_images = get_db_images()
    print(f"Total images in database: {len(db_images)}\n")

    print("Checking for missing files with Chinese characters...")
    missing_chinese = []

    for i, img_name in enumerate(db_images):
        if (i + 1) % 1000 == 0:
            print(f"  Checked {i + 1}/{len(db_images)}...")

        # Only check Chinese-named files
        if not has_chinese(img_name):
            continue

        img_path = get_image_path(img_name)
        if not file_exists(img_path):
            # Get directory path
            md5 = hashlib.md5(img_name.encode('utf-8')).hexdigest()
            dir_path = f"/var/www/html/images/{md5[0]}/{md5[:2]}"
            dir_files = list_dir(dir_path)

            missing_chinese.append({
                'name': img_name,
                'path': img_path,
                'dir': dir_path,
                'dir_files': dir_files
            })

    print(f"\n{'='*60}")
    print(f"Missing Chinese-named files: {len(missing_chinese)}")
    print(f"{'='*60}\n")

    if missing_chinese:
        print("List of missing files:\n")
        for i, item in enumerate(missing_chinese, 1):
            print(f"{i}. {item['name']}")
            print(f"   Expected: {item['path']}")
            if item['dir_files']:
                # Show potential matches
                base_name = item['name'].split('.')[0]
                ext = item['name'].split('.')[-1]
                similar = [f for f in item['dir_files'] if f.endswith(f'.{ext}')]
                if similar:
                    print(f"   Files in same directory with .{ext}: {similar[:5]}")
            print()

if __name__ == '__main__':
    main()
