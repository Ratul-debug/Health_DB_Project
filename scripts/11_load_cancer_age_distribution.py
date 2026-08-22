import pandas as pd
import mysql.connector
from pathlib import Path

conn = mysql.connector.connect(
    host="localhost",
    user="healthuser",
    password="HealthDB@2026",
    database="health_db"
)

cur = conn.cursor()

cur.execute("DELETE FROM cancer_age_distribution")

age_groups = [
    "<=14",
    "15-24",
    "25-34",
    "35-44",
    "45-54",
    "55-64",
    "65-74",
    "=>75"
]

files = [
    "table_025.csv",
    "table_026.csv",
    "table_027.csv",
    "table_028.csv",
    "table_029.csv",
    "table_030.csv",
    "table_031.csv",
    "table_032.csv"
]

base = Path(
    "extracted_tables/074_Hospital_Cancer_Registry_Report_2014"
)

gender = "Male"

for file in files:

    df = pd.read_csv(base / file, dtype=str).fillna("")

    for row in df.values.tolist():

        row = [str(x).strip() for x in row]

        if len(row) < 10:
            continue

        # Female header found
        if row[0].strip().lower() == "female":
            gender = "Female"
            continue

        icd = row[0].strip()
        site = row[1].strip()

        # skip junk rows
        if icd == "":
            continue

        if icd.startswith("Total"):
            continue

        if icd == "0":
            continue

        counts = row[2:10]

        if len(counts) != 8:
            continue

        for age_group, value in zip(age_groups, counts):

            value = value.strip()

            if value == "":
                continue

            try:
                cases = int(float(value))
            except:
                continue

            cur.execute(
                """
                INSERT INTO cancer_age_distribution
                (
                    icd_code,
                    site_name,
                    age_group,
                    gender,
                    cases
                )
                VALUES (%s,%s,%s,%s,%s)
                """,
                (
                    icd,
                    site,
                    age_group,
                    gender,
                    cases
                )
            )

conn.commit()

cur.execute(
    "SELECT COUNT(*) FROM cancer_age_distribution"
)

print(
    "Cancer age rows loaded:",
    cur.fetchone()[0]
)

cur.close()
conn.close()
