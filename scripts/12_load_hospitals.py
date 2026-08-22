#!/usr/bin/env python3

import pandas as pd
import pymysql

conn = pymysql.connect(
    host="localhost",
    user="healthuser",
    password="HealthDB@2026",
    database="health_db"
)

cur = conn.cursor()

df = pd.read_csv(
    "extracted_tables/042_Health_Bulletin_2008/table_009.csv",
    dtype=str,
    keep_default_na=False
)

divisions = set()

for _, row in df.iterrows():

    division = row.iloc[0].strip()
    hospital = row.iloc[3].strip()

    if division == "":
        continue

    if hospital == "":
        continue

    if division.startswith("Total"):
        continue

    if division == "Division":
        continue

    divisions.add(division)

for d in divisions:

    cur.execute(
        """
        INSERT IGNORE INTO division(division_name)
        VALUES(%s)
        """,
        (d,)
    )

conn.commit()

cur.execute(
    """
    SELECT division_id, division_name
    FROM division
    """
)

division_map = {
    name: did
    for did, name in cur.fetchall()
}

hospital_count = 0

for _, row in df.iterrows():

    division = row.iloc[0].strip()
    hospital = row.iloc[3].strip()

    if division == "":
        continue

    if hospital == "":
        continue

    if division.startswith("Total"):
        continue

    if division == "Division":
        continue

    cur.execute(
        """
        INSERT INTO hospital(
            hospital_name,
            division_id
        )
        VALUES(%s,%s)
        """,
        (
            hospital,
            division_map[division]
        )
    )

    hospital_count += 1

conn.commit()

print("Divisions loaded :", len(divisions))
print("Hospitals loaded :", hospital_count)

conn.close()
