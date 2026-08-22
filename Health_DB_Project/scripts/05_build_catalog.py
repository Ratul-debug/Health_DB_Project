#!/usr/bin/env python3

import os
import pandas as pd

ROOT = "extracted_tables"

records = []

for root, dirs, files in os.walk(ROOT):

    for file in files:

        if not file.endswith(".csv"):
            continue

        path = os.path.join(root, file)

        try:

            df = pd.read_csv(
                path,
                nrows=5,
                header=None,
                on_bad_lines="skip",
                encoding_errors="ignore"
            )

            rows = len(df)
            cols = len(df.columns)

        except:

            rows = 0
            cols = 0

        records.append([
            path,
            rows,
            cols
        ])

catalog = pd.DataFrame(
    records,
    columns=["file","rows","cols"]
)

catalog.to_csv(
    "reports/table_catalog.csv",
    index=False
)

print("table_catalog.csv created")
