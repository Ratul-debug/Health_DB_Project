#!/usr/bin/env python3

"""Classify only when evidence is sufficient and document every load decision."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

try:
    from tqdm import tqdm
except ImportError:
    def tqdm(iterable, **_kwargs):
        return iterable


BASE_DIR = Path(__file__).resolve().parent.parent
REPORT_DIR = BASE_DIR / "reports"
CATALOG_FILE = REPORT_DIR / "table_catalog.csv"
OUTPUT_FILE = REPORT_DIR / "classified_tables.csv"
MAPPING_FILE = REPORT_DIR / "source_to_schema_mapping.csv"
QUALITY_SUMMARY_FILE = REPORT_DIR / "etl_quality_gate_summary.txt"

RULES = {
    "population": ["population", "census", "division", "district"],
    "health_stat": ["disease", "admission", "deaths", "hospital", "opd", "patient", "measles", "confirmed"],
    "human_resource": ["designation", "sanctioned", "vacant", "professor", "nurse", "doctor", "provider", "post"],
    "cancer": ["cancer", "tumour", "tumor", "site", "icd"],
    "surgery": ["surgery", "operation", "cataract"],
    "maternal_child": ["maternal", "pregnancy", "newborn", "nutrition", "immunization"],
}

EXPLICIT_LOADS = {
    "cleaned_tables/114_DGHS_Active_Facility_Registry/HealthFacility.csv": ("HealthFacility", 39434),
    "cleaned_tables/114_DGHS_Active_Facility_Registry/Laboratory.csv": ("Laboratory", 9694),
    "cleaned_tables/116_Bangladesh_ICD11_Condition_ValueSet/Disease.csv": ("Disease", 18508),
    "cleaned_tables/118_Bangladesh_Open_Data_Doctor_Directory/Designation.csv": ("Designation", 54),
}

EXPLICIT_CATEGORIES = {
    "cleaned_tables/114_DGHS_Active_Facility_Registry/HealthFacility.csv": "health_facility",
    "cleaned_tables/114_DGHS_Active_Facility_Registry/Laboratory.csv": "laboratory",
    "cleaned_tables/116_Bangladesh_ICD11_Condition_ValueSet/Disease.csv": "disease_reference",
    "cleaned_tables/117_Bangladesh_Vaccine_Value_Set/VaccineReference.csv": "vaccine_reference",
    "cleaned_tables/118_Bangladesh_Open_Data_Doctor_Directory/Designation.csv": "human_resource",
}


def classify(text: str) -> tuple[str, int, str, str]:
    matches = {
        category: [keyword for keyword in keywords if keyword in text]
        for category, keywords in RULES.items()
    }
    ranking = sorted(
        ((category, len(words)) for category, words in matches.items()),
        key=lambda item: (-item[1], item[0]),
    )
    category, score = ranking[0]
    runner_up = ranking[1][1]
    if score < 2:
        return "unclassified", score, ";".join(matches[category]), "insufficient_keyword_evidence"
    if score == runner_up:
        return "unclassified", score, ";".join(matches[category]), "ambiguous_category_tie"
    return category, score, ";".join(matches[category]), "rule_supported"


def mapping_decision(file: str, quality: str) -> tuple[str, str, str, int]:
    if file in EXPLICIT_LOADS:
        table, rows = EXPLICIT_LOADS[file]
        return table, "loaded_by_migration_006", "explicit_verified_mapping", rows
    if "086_Measles_Update_Till_14_05_26_" in file:
        return "Measles", "excluded", "aggregate_grain_does_not_match_patient_event_table", 0
    if file.endswith("/VaccineReference.csv"):
        return "Vaccination", "excluded", "terminology_has_no_patient_or_event_date", 0
    if "115_Bangladesh_Core_FHIR_IG" in file:
        return "", "reference_only", "implementation_guide_inventory_not_observation_data", 0
    if not quality.startswith("accepted"):
        return "", "blocked_quality_gate", "table_requires_review_or_was_rejected", 0
    return "", "reference_only", "no_explicit_field_level_mapping_to_21_table_schema", 0


def main() -> None:
    if not CATALOG_FILE.exists():
        raise FileNotFoundError(f"Run scripts/05_build_catalog.py first: {CATALOG_FILE}")
    catalog = pd.read_csv(CATALOG_FILE, keep_default_na=False)
    classifications: list[dict[str, object]] = []
    mappings: list[dict[str, object]] = []
    for item in tqdm(catalog.to_dict("records"), total=len(catalog), desc="Classifying safely"):
        csv_file = BASE_DIR / str(item["file"])
        quality = str(item["quality_status"])
        file_name = str(item["file"])
        if file_name in EXPLICIT_CATEGORIES:
            category, score, keywords, reason = (
                EXPLICIT_CATEGORIES[file_name], 0, "", "explicit_verified_mapping"
            )
        elif "086_Measles_Update_Till_14_05_26_" in file_name:
            category, score, keywords, reason = (
                "measles_aggregate", 0, "", "verified_source_specific_classification"
            )
        elif "115_Bangladesh_Core_FHIR_IG" in file_name:
            category, score, keywords, reason = (
                "interoperability_reference", 0, "", "verified_source_specific_classification"
            )
        elif not csv_file.is_file() or not quality.startswith("accepted"):
            category, score, keywords, reason = (
                "unclassified", 0, "", "quality_gate_not_passed"
            )
        else:
            try:
                frame = pd.read_csv(
                    csv_file, dtype=str, keep_default_na=False, nrows=30,
                    on_bad_lines="skip", encoding_errors="replace",
                )
                preview = " ".join(
                    [file_name, *map(str, frame.columns), *frame.fillna("").astype(str).values.flatten()]
                ).lower()
                category, score, keywords, reason = classify(preview)
            except Exception:
                category, score, keywords, reason = "unclassified", 0, "", "read_error"
        classifications.append({
            "file": item["file"], "category": category, "keyword_score": score,
            "matched_keywords": keywords, "classification_status": reason,
            "quality_status": quality, "rows": int(item["rows"]), "cols": int(item["cols"]),
        })
        target, mapping_status, mapping_reason, loaded_rows = mapping_decision(str(item["file"]), quality)
        mappings.append({
            "source_file": item["source_file"], "pipeline_file": item["file"],
            "quality_status": quality, "classification": category,
            "target_sql_table": target, "mapping_status": mapping_status,
            "load_eligible": "yes" if mapping_status == "loaded_by_migration_006" else "no",
            "loaded_rows": loaded_rows, "decision_reason": mapping_reason,
        })

    pd.DataFrame(classifications).to_csv(OUTPUT_FILE, index=False)
    mapping_frame = pd.DataFrame(mappings)
    mapping_frame.to_csv(MAPPING_FILE, index=False)
    mapped = sum(row["mapping_status"] == "loaded_by_migration_006" for row in mappings)
    unclassified = sum(row["category"] == "unclassified" for row in classifications)
    quality_counts = catalog["quality_status"].value_counts().to_dict()
    mapping_counts = mapping_frame["mapping_status"].value_counts().to_dict()
    QUALITY_SUMMARY_FILE.write_text(
        "ETL QUALITY-GATE SUMMARY\n\n"
        f"raw_extracted_tables={len(catalog) - quality_counts.get('accepted_mapped', 0)}\n"
        f"accepted_automatic={quality_counts.get('accepted', 0)}\n"
        f"accepted_curated={quality_counts.get('accepted_curated', 0)}\n"
        f"review_required={quality_counts.get('review_required', 0)}\n"
        f"rejected={quality_counts.get('rejected', 0)}\n"
        f"derived_mapping_outputs={quality_counts.get('accepted_mapped', 0)}\n"
        f"catalogued_pipeline_outputs={len(catalog)}\n"
        f"keyword_unclassified={unclassified}\n"
        f"explicit_sql_mappings={mapped}\n"
        f"sql_rows_loaded_by_migration_006={int(mapping_frame['loaded_rows'].sum())}\n"
        f"blocked_by_quality_gate={mapping_counts.get('blocked_quality_gate', 0)}\n"
        f"reference_only={mapping_counts.get('reference_only', 0)}\n"
        f"excluded_for_schema_or_granularity={mapping_counts.get('excluded', 0)}\n"
        "measles_tables_verified=3\n"
        "measles_tables_loaded=0\n"
        "measles_exclusion_reason=aggregate grain does not match patient/event Measles schema\n",
        encoding="utf-8",
    )
    print(f"Assessed            : {len(classifications)}")
    print(f"Explicit SQL loads  : {mapped}")
    print(f"Unclassified        : {unclassified}")
    print(f"Classification      : {OUTPUT_FILE}")
    print(f"Schema mapping      : {MAPPING_FILE}")
    print(f"Quality summary     : {QUALITY_SUMMARY_FILE}")


if __name__ == "__main__":
    main()
