#!/usr/bin/env python3

import pandas as pd
import requests
from pathlib import Path
from tqdm import tqdm
import re
import csv
import time

# =====================================
# PATHS
# =====================================

BASE_DIR = Path(__file__).resolve().parent.parent

PDF_DIR = BASE_DIR / "pdfs"
PDF_DIR.mkdir(exist_ok=True)

SOURCE_PAGE_DIR = BASE_DIR / "source_pages"
SOURCE_PAGE_DIR.mkdir(exist_ok=True)

possible_excel_files = [
    BASE_DIR / "health_data.xlsx",
    BASE_DIR / "data_catalog" / "health_data.xlsx",
]

# =====================================
# FIND EXCEL FILE
# =====================================

excel_file = None

for f in possible_excel_files:
    if f.exists():
        excel_file = f
        break

if excel_file is None:
    raise FileNotFoundError(
        "health_data.xlsx not found.\n"
        f"Checked:\n{possible_excel_files}"
    )

print(f"Using Excel file: {excel_file}")

# =====================================
# LOAD EXCEL
# =====================================

workbook = pd.ExcelFile(excel_file)
catalog_sheet = (
    "Health_Catalog_Clean"
    if "Health_Catalog_Clean" in workbook.sheet_names
    else workbook.sheet_names[0]
)
df = pd.read_excel(workbook, sheet_name=catalog_sheet)

print(f"Using worksheet: {catalog_sheet}")
print("Columns found:")
print(df.columns.tolist())

# =====================================
# FIND URL COLUMN
# =====================================

url_col = None

for col in df.columns:
    if "link" in str(col).lower():
        url_col = col
        break

if url_col is None:
    raise ValueError("Could not find URL column.")

print(f"Using URL column: {url_col}")

# =====================================
# DOWNLOAD SETTINGS
# =====================================

session = requests.Session()

downloaded = 0
downloaded_html = 0
skipped = 0
failed = 0

failed_urls = []

# =====================================
# DOWNLOAD LOOP
# =====================================

for idx, row in tqdm(df.iterrows(), total=len(df)):

    url = str(row.get(url_col, "")).strip()

    if not url.startswith("http"):
        continue

    dataset_name = str(
        row.get("Dataset Name", f"dataset_{idx}")
    )

    dataset_name = re.sub(
        r'[^A-Za-z0-9_-]+',
        "_",
        dataset_name
    ).strip("_")

    if not dataset_name:
        dataset_name = f"dataset_{idx:03d}"

    dataset_name = dataset_name[:120]

    file_stem = f"{idx:03d}_{dataset_name}"
    pdf_path = PDF_DIR / f"{file_stem}.pdf"
    html_path = SOURCE_PAGE_DIR / f"{file_stem}.html"

    if pdf_path.exists() or html_path.exists():
        skipped += 1
        continue

    success = False

    for attempt in range(3):

        try:

            response = session.get(
                url,
                timeout=90,
                allow_redirects=True,
                headers={
                    "User-Agent":
                    "Mozilla/5.0"
                }
            )

            if response.status_code == 200:

                content = response.content

                if len(content) > 1000 and content.startswith(b"%PDF-"):

                    with open(pdf_path, "wb") as f:
                        f.write(content)

                    downloaded += 1
                    success = True
                    break

                content_type = response.headers.get(
                    "Content-Type", ""
                ).lower()
                looks_like_html = (
                    "text/html" in content_type
                    or content.lstrip().lower().startswith(
                        (b"<!doctype html", b"<html")
                    )
                )

                if len(content) > 1000 and looks_like_html:

                    with open(html_path, "wb") as f:
                        f.write(content)

                    downloaded_html += 1
                    success = True
                    break

            time.sleep(2)

        except Exception:
            time.sleep(2)

    if not success:

        failed += 1

        failed_urls.append([
            idx,
            dataset_name,
            url
        ])

# =====================================
# SAVE FAILED DOWNLOADS
# =====================================

failed_csv = BASE_DIR / "failed_downloads.csv"

with open(
    failed_csv,
    "w",
    newline="",
    encoding="utf-8"
) as f:

    writer = csv.writer(f)

    writer.writerow([
        "row",
        "dataset_name",
        "url"
    ])

    writer.writerows(failed_urls)

# =====================================
# SUMMARY
# =====================================

print("\n=================================")
print("DOWNLOAD SUMMARY")
print("=================================")

print("Downloaded :", downloaded)
print("HTML pages:", downloaded_html)
print("Skipped    :", skipped)
print("Failed     :", failed)

print(
    f"\nFailed URLs saved to:\n{failed_csv}"
)
