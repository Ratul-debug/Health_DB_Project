import pandas as pd
import pymysql

FILES = [
    "extracted_tables/043_Health_Bulletin_2007/table_0191.csv",
    "extracted_tables/043_Health_Bulletin_2007/table_0192.csv",
    "extracted_tables/043_Health_Bulletin_2007/table_0200.csv"
]

conn = pymysql.connect(
    host="localhost",
    user="healthuser",
    password="HealthDB@2026",
    database="health_db"
)

cur = conn.cursor()

designation_count = 0
hr_count = 0

for file in FILES:

    df = pd.read_csv(
        file,
        header=None,
        dtype=str,
        keep_default_na=False
    )

    for _, row in df.iterrows():

        designation = str(row[0]).strip()

        if designation == "":
            continue

        if designation.startswith("Class"):
            continue

        if designation.startswith("Scale"):
            continue

        if designation.startswith("Sub-Total"):
            continue

        try:

            sanctioned = int(row[1])
            male = int(row[2])
            female = int(row[3])
            total = int(row[4])
            vacant = int(row[5])

        except:
            continue

        cur.execute(
            """
            INSERT IGNORE INTO designation
            (designation_name)
            VALUES (%s)
            """,
            (designation,)
        )

        cur.execute(
            """
            SELECT designation_id
            FROM designation
            WHERE designation_name=%s
            """,
            (designation,)
        )

        designation_id = cur.fetchone()[0]

        cur.execute(
            """
            INSERT INTO human_resource
            (
                designation_id,
                sanctioned_post,
                existing_male,
                existing_female,
                existing_total,
                vacant_post
            )
            VALUES (%s,%s,%s,%s,%s,%s)
            """,
            (
                designation_id,
                sanctioned,
                male,
                female,
                total,
                vacant
            )
        )

        hr_count += 1

conn.commit()

cur.execute(
    "SELECT COUNT(*) FROM designation"
)
designation_count = cur.fetchone()[0]

cur.execute(
    "SELECT COUNT(*) FROM human_resource"
)
hr_count = cur.fetchone()[0]

print("Designations:", designation_count)
print("HR Records:", hr_count)

conn.close()
