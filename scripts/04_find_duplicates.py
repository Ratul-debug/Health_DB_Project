#!/usr/bin/env python3

from pathlib import Path
import pandas as pd
import hashlib

BASE_DIR = Path(__file__).resolve().parent.parent

hashes = {}

dupes = []

for root in [
    BASE_DIR / "extracted_tables",
    BASE_DIR / "extracted_large"
]:

    if not root.exists():
        continue

    for csv_file in root.rglob("*.csv"):

        try:

            text = csv_file.read_text(
                encoding="utf-8",
                errors="ignore"
            )

            h = hashlib.md5(
                text.encode()
            ).hexdigest()

            if h in hashes:

                dupes.append({
                    "original": hashes[h],
                    "duplicate": str(csv_file)
                })

            else:

                hashes[h] = str(csv_file)

        except Exception:
            pass

pd.DataFrame(dupes).to_csv(
    BASE_DIR /
    "data_catalog" /
    "duplicate_tables.csv",
    index=False
)

print()
print("DUPLICATES:", len(dupes))
