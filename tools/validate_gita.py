#!/usr/bin/env python3
"""Validate gita.json verse data integrity."""

import json
import sys
import os

EXPECTED = {
    1:47, 2:72, 3:43, 4:42, 5:29, 6:47,
    7:30, 8:28, 9:34, 10:42, 11:55, 12:20,
    13:34, 14:27, 15:20, 16:24, 17:28, 18:78
}

def validate(path):
    with open(path, encoding='utf-8') as f:
        data = json.load(f)

    chapters = data.get('chapters', [])
    errors = []
    total = 0

    if len(chapters) != 18:
        errors.append(f"Expected 18 chapters, got {len(chapters)}")

    for ch in chapters:
        num = ch['number']
        verses = ch.get('verses', [])
        count = len(verses)
        total += count

        expected = EXPECTED.get(num, 0)
        # Ch13 has 35 verses in some editions (34 is the common count)
        valid_variants = {13: [34, 35]}
        allowed = valid_variants.get(num, [expected])
        if count not in allowed:
            errors.append(f"Chapter {num}: expected {allowed} verses, got {count}")

        for v in verses:
            for field in ['sanskrit', 'transliteration', 'translation']:
                val = v.get(field, '')
                if not val or not val.strip():
                    errors.append(f"Chapter {num} Verse {v['number']}: empty {field}")

    if total not in (700, 701):
        errors.append(f"Total verses: {total} (expected 700 or 701)")

    if errors:
        print(f"VALIDATION FAILED — {len(errors)} error(s):")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        print(f"OK — {len(chapters)} chapters, {total} verses")
        sys.exit(0)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        path = os.path.join(script_dir, '..', 'gita.json')
    else:
        path = sys.argv[1]
    validate(path)
