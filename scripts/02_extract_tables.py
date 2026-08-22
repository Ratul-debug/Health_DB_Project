#!/usr/bin/env python3

from pathlib import Path
import pdfplumber
import pandas as pd
import hashlib
import json
import traceback
import gc
from tqdm import tqdm

# =====================================================
# PATHS
# =====================================================

BASE_DIR = Path(__file__).resolve().parent.parent

PDF_DIR = BASE_DIR / "pdfs"
EXTRACTED_DIR = BASE_DIR / "extracted_tables"
METADATA_DIR = BASE_DIR / "metadata"
LOG_DIR = BASE_DIR / "logs"

EXTRACTED_DIR.mkdir(exist_ok=True)
METADATA_DIR.mkdir(exist_ok=True)
LOG_DIR.mkdir(exist_ok=True)

ERROR_LOG = LOG_DIR / "extract_errors.log"

# =====================================================
# SETTINGS
# =====================================================

MIN_ROWS = 5
MIN_COLS = 2

# Skip huge PDFs initially
MAX_PAGES_PER_PDF = 150

# =====================================================
# HELPERS
# =====================================================

def clean_dataframe(df):

    df = df.dropna(axis=0, how="all")
    df = df.dropna(axis=1, how="all")

    return df


def table_hash(df):

    text = (
        df.fillna("")
          .astype(str)
          .to_csv(index=False)
    )

    return hashlib.md5(
        text.encode("utf-8")
    ).hexdigest()


# =====================================================
# MAIN
# =====================================================

pdf_files = sorted(PDF_DIR.glob("*.pdf"))

seen_hashes = set()

total_tables = 0
processed_pdfs = 0

with open(ERROR_LOG, "w", encoding="utf-8") as elog:

    for pdf_file in tqdm(pdf_files, desc="Processing PDFs"):

        pdf_name = pdf_file.stem

        metadata_file = (
            METADATA_DIR /
            f"{pdf_name}.json"
        )

        if metadata_file.exists():
            continue

        metadata = {
            "pdf": pdf_file.name,
            "tables": []
        }

        output_dir = (
            EXTRACTED_DIR /
            pdf_name
        )

        output_dir.mkdir(
            parents=True,
            exist_ok=True
        )

        try:

            with pdfplumber.open(pdf_file) as pdf:

                page_count = len(pdf.pages)

                if page_count > MAX_PAGES_PER_PDF:

                    print(
                        f"\nSKIPPED LARGE PDF "
                        f"({page_count} pages): "
                        f"{pdf_file.name}"
                    )

                    continue

                table_counter = 0

                for page_num in range(page_count):

                    try:

                        page = pdf.pages[page_num]

                        tables = (
                            page.extract_tables()
                        )

                    except Exception:

                        elog.write(
                            f"\nPAGE ERROR: "
                            f"{pdf_file.name} "
                            f"Page {page_num+1}\n"
                        )

                        elog.write(
                            traceback.format_exc()
                        )

                        continue

                    if not tables:
                        continue

                    for table in tables:

                        try:

                            df = pd.DataFrame(table)

                            df = clean_dataframe(df)

                            if df.empty:
                                continue

                            if len(df) < MIN_ROWS:
                                continue

                            if len(df.columns) < MIN_COLS:
                                continue

                            h = table_hash(df)

                            if h in seen_hashes:
                                continue

                            seen_hashes.add(h)

                            table_counter += 1
                            total_tables += 1

                            csv_file = (
                                output_dir /
                                f"table_{table_counter:03d}.csv"
                            )

                            df.to_csv(
                                csv_file,
                                index=False
                            )

                            metadata["tables"].append(
                                {
                                    "page":
                                    page_num + 1,

                                    "file":
                                    csv_file.name,

                                    "rows":
                                    int(df.shape[0]),

                                    "cols":
                                    int(df.shape[1]),

                                    "hash":
                                    h
                                }
                            )

                        except Exception:

                            elog.write(
                                f"\nTABLE ERROR: "
                                f"{pdf_file.name} "
                                f" Page {page_num+1}\n"
                            )

                            elog.write(
                                traceback.format_exc()
                            )

                    gc.collect()

            with open(
                metadata_file,
                "w",
                encoding="utf-8"
            ) as f:

                json.dump(
                    metadata,
                    f,
                    indent=2,
                    ensure_ascii=False
                )

            processed_pdfs += 1

            gc.collect()

        except Exception:

            elog.write(
                f"\nPDF ERROR: "
                f"{pdf_file.name}\n"
            )

            elog.write(
                traceback.format_exc()
            )

# =====================================================
# SUMMARY
# =====================================================

print("\n====================================")
print("EXTRACTION COMPLETE")
print("====================================")
print("PDFs Processed :", processed_pdfs)
print("Tables Saved   :", total_tables)
print("====================================")
