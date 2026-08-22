import pandas as pd

df = pd.read_csv("reports/classified_tables.csv")

for cat in [
    "health_stat",
    "population",
    "human_resource",
    "surgery",
    "cancer"
]:
    print("\n")
    print("=" * 80)
    print(cat.upper())
    print("=" * 80)

    subset = df[df["category"] == cat]

    subset = subset.sort_values(
        ["rows", "cols"],
        ascending=False
    )

    print(
        subset.head(20)[
            ["file", "rows", "cols"]
        ].to_string(index=False)
    )
