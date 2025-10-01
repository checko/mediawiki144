#!/usr/bin/env python3
"""
Extract ZIP with Traditional Chinese filename support
Handles cp950, big5, gbk encodings
"""
import zipfile
import os
import sys
import re
from pathlib import Path

def detect_encoding(filename_bytes):
    """Try multiple Chinese encodings"""
    encodings = ['utf-8', 'cp950', 'big5', 'gbk', 'gb18030']
    for enc in encodings:
        try:
            return filename_bytes.decode(enc), enc
        except (UnicodeDecodeError, AttributeError):
            continue
    # Fallback: use escaped Unicode
    return filename_bytes.decode('utf-8', errors='replace'), 'utf-8-replace'

def normalize_escaped_unicode(name):
    """Convert #Uxxxx or #Lxxxxxx to actual Unicode characters"""
    if '#U' not in name and '#L' not in name:
        return name
    pattern = re.compile(r'#([UL])([0-9A-Fa-f]{4,6})')
    def repl(match):
        try:
            return chr(int(match.group(2), 16))
        except ValueError:
            return match.group(0)
    return pattern.sub(repl, name)

def extract_zip_with_encoding(zip_path, extract_to, encoding='utf-8'):
    """Extract ZIP handling Chinese filenames"""
    extract_to = Path(extract_to)
    extract_to.mkdir(parents=True, exist_ok=True)

    extracted_files = []
    skipped_files = []

    with zipfile.ZipFile(zip_path, 'r') as zf:
        for member in zf.namelist():
            # Try to decode filename
            try:
                # Modern ZIPs use UTF-8, try that first
                decoded_name = member
                used_enc = 'utf-8'

                # If the filename looks like mojibake, try re-encoding
                if decoded_name != member:
                    try:
                        filename_bytes = member.encode('cp437')
                        decoded_name, used_enc = detect_encoding(filename_bytes)
                    except:
                        decoded_name = member
                        used_enc = 'utf-8'

                decoded_name = normalize_escaped_unicode(decoded_name)

                # Create full path
                target_path = extract_to / decoded_name

                # Extract
                if member.endswith('/'):
                    target_path.mkdir(parents=True, exist_ok=True)
                else:
                    target_path.parent.mkdir(parents=True, exist_ok=True)
                    with zf.open(member) as source, open(target_path, 'wb') as target:
                        target.write(source.read())

                extracted_files.append((member, decoded_name, used_enc))

            except Exception as e:
                skipped_files.append((member, str(e)))

    return extracted_files, skipped_files

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <zip_file> <extract_to> [encoding]")
        print(f"Example: {sys.argv[0]} data/images.zip /tmp/wiki-images cp950")
        sys.exit(1)

    zip_file = sys.argv[1]
    extract_to = sys.argv[2]
    encoding = sys.argv[3] if len(sys.argv) > 3 else 'cp950'

    print(f"Extracting {zip_file} to {extract_to} with encoding hints...")
    extracted, skipped = extract_zip_with_encoding(zip_file, extract_to, encoding)

    print(f"\n✓ Extracted {len(extracted)} files/directories")
    if skipped:
        print(f"⚠ Skipped {len(skipped)} items:")
        for item, error in skipped[:10]:
            print(f"  - {item}: {error}")

    # Show encoding statistics
    enc_stats = {}
    for _, _, enc in extracted:
        enc_stats[enc] = enc_stats.get(enc, 0) + 1
    print(f"\nEncoding statistics:")
    for enc, count in enc_stats.items():
        print(f"  {enc}: {count} files")
