#!/usr/bin/env python3

from pathlib import Path
import pandas as pd
import csv

approved = []

with open("approved_sources.txt") as f:
    approved = [x.strip() for x in f if x.strip()]

RULES = {
    "population": [
        "population",
        "census",
        "division",
        "district"
    ],

    "health_stat": [
        "disease",
        "admission",
        "deaths",
        "hospital",
        "opd",
        "patient"
    ],

    "human_resource": [
        "designation",
        "sanctioned",
        "vacant",
        "professor",
        "nurse",
        "doctor"
    ],

    "cancer": [
        "cancer",
        "tumour",
        "tumor",
        "site",
        "icd"
    ],

    "surgery": [
        "surgery",
        "operation",
        "cataract"
    ]
}

rows = []

for src in approved:

    for file in Path(src).glob("*.csv"):

        try:

            df = pd.read_csv(
                file,
                dtype=str,
                keep_default_na=False
            )

            text = " ".join(
                str(x)
                for x in df.head(10)
                .fillna("")
                .astype(str)
                .values.flatten()
            ).lower()

            category = "other"
            best_score = 0

            for cat, keywords in RULES.items():

                score = sum(
                    1 for k in keywords
                    if k in text
                )

                if score > best_score:
                    best_score = score
                    category = cat

            rows.append([
                str(file),
                category,
                len(df),
                len(df.columns)
            ])

        except:
            pass

with open(
    "reports/classified_tables.csv",
    "w",
    newline="",
    encoding="utf-8"
) as f:

    w = csv.writer(f)

    w.writerow([
        "file",
        "category",
        "rows",
        "cols"
    ])

    w.writerows(rows)

print("classified_tables.csv created")
