import pandas as pd
import pymysql

FILE = "extracted_tables/074_Hospital_Cancer_Registry_Report_2014/table_011.csv"

conn = pymysql.connect(
    host="localhost",
    user="healthuser",
    password="HealthDB@2026",
    database="health_db"
)

cur = conn.cursor()

df = pd.read_csv(
    FILE,
    header=None,
    dtype=str,
    keep_default_na=False
)

loaded = 0

for i in range(1, len(df)):

    site = str(df.iloc[i,1]).strip()

    if site == "":
        continue

    try:
        cases = int(
            str(df.iloc[i,2]).replace(",","")
        )
    except:
        continue

    try:
        percentage = float(
            str(df.iloc[i,3]).replace("%","")
        )
    except:
        percentage = 0

    cur.execute(
        """
        INSERT IGNORE INTO cancer_site(site_name)
        VALUES(%s)
        """,
        (site,)
    )

    cur.execute(
        """
        SELECT site_id
        FROM cancer_site
        WHERE site_name=%s
        """,
        (site,)
    )

    site_id = cur.fetchone()[0]

    cur.execute(
        """
        INSERT INTO cancer_statistics
        (
            site_id,
            cases,
            percentage
        )
        VALUES(%s,%s,%s)
        """,
        (
            site_id,
            cases,
            percentage
        )
    )

    loaded += 1

conn.commit()

print("Cancer rows loaded:", loaded)

cur.close()
conn.close()
