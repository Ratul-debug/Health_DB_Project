import pandas as pd
import pymysql

conn = pymysql.connect(
    host="localhost",
    user="healthuser",
    password="HealthDB@2026",
    database="health_db"
)

cur = conn.cursor()

FILES = [
    "extracted_tables/039_Health_Bulletin_2011/table_0065.csv",
    "extracted_tables/039_Health_Bulletin_2011/table_0069.csv",
    "extracted_tables/039_Health_Bulletin_2011/table_0072.csv"
]

AGE_GROUPS = {
    1: "0-28d",
    2: "29d-11m",
    3: "1-4y",
    4: "5-14y",
    5: "15-24y",
    6: "25-49y",
    7: "50y+"
}

loaded = 0

for file in FILES:

    df = pd.read_csv(
        file,
        header=None,
        dtype=str,
        keep_default_na=False
    )

    for i in range(2, len(df)):

        disease = str(df.iloc[i,0]).strip()

        if disease == "":
            continue

        cur.execute("""
            INSERT IGNORE INTO disease(disease_name)
            VALUES(%s)
        """,(disease,))

        cur.execute("""
            SELECT disease_id
            FROM disease
            WHERE disease_name=%s
        """,(disease,))

        disease_id = cur.fetchone()[0]

        pairs = [
            (1,1,2),
            (2,3,4),
            (3,5,6),
            (4,7,8),
            (5,9,10),
            (6,11,12),
            (7,13,14)
        ]

        for age_id,mcol,fcol in pairs:

            try:
                male = int(str(df.iloc[i,mcol]).replace(",",""))
            except:
                male = 0

            try:
                female = int(str(df.iloc[i,fcol]).replace(",",""))
            except:
                female = 0

            if male==0 and female==0:
                continue

            cur.execute("""
            INSERT INTO disease_statistics
            (
                disease_id,
                age_group_id,
                male_count,
                female_count,
                report_year
            )
            VALUES(%s,%s,%s,%s,%s)
            """,
            (
                disease_id,
                age_id,
                male,
                female,
                2011
            ))

            loaded += 1

conn.commit()

print("Disease rows loaded:",loaded)

cur.close()
conn.close()
