#!/usr/bin/env python3
"""Build the Bangladesh-only national-scale data expansion.

This script does not change the 21-table schema. It converts four official,
locally archived source extracts into deterministic SQL rows for the existing
HealthFacility, Laboratory, Disease, and Designation tables.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
import runpy
from collections import Counter
from pathlib import Path
from zipfile import ZipFile

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
FULL_DUMP = ROOT / "sql" / "health_db_21_tables_with_data.sql"
SCHEMA_DUMP = ROOT / "sql" / "schema.sql"
MIGRATION = ROOT / "sql" / "migrations" / "006_bangladesh_national_scale_expansion.sql"
REPORT = ROOT / "reports" / "bangladesh_national_scale_static_validation.txt"
PIPELINE_MANIFEST = ROOT / "reports" / "bangladesh_scale_pipeline_manifest.csv"

SOURCE_ROOT = ROOT / "source_datasets"
EXTRACTED_ROOT = ROOT / "extracted_tables"
CLEANED_ROOT = ROOT / "cleaned_tables"
METADATA_ROOT = ROOT / "metadata"

FACILITY_RAW = SOURCE_ROOT / "dghs_active_facility_registry_2026-09-01.xlsx"
FHIR_IG_RAW = SOURCE_ROOT / "bd_core_fhir_ig_0.4.6_full.zip"
CONDITION_RAW = SOURCE_ROOT / "bd_condition_icd11_2025_01_ocl.json"
VACCINE_VALUESET_RAW = SOURCE_ROOT / "bd_vaccine_valueset_0.4.6.json"
VACCINE_CODE_SYSTEM_RAW = SOURCE_ROOT / "bd_vaccine_code_system_0.4.6.json"
DOCTOR_RAW = SOURCE_ROOT / "bangladesh_open_data_doctor_directory_2016.xls"

SOURCE_DOWNLOAD_URLS = {
    114: [
        "https://hrm.dghs.gov.bd/public/facility-registry/reports/organization-list?is_active=1&submit=Run&columns_csv=id%2Cname%2Cname_bn%2Ccode%2Cemail_1%2Cfacility_agency_name%2Cfacility_type_name%2Cdivision_name%2Cdistrict_name%2Ccity_corporation_name%2Cupazila_name%2Cpaurasava_name%2Cunion_name%2Cis_private&alias_columns_csv=ID%2CName%2CName+%28Bangla%29%2CCode%2CEmail%2CAgency%2CType%2CDivision%2CDistrict%2CCity+Corporation%2CUpazila%2CPaurasava%2CUnion%2CPrivate&ret=excel"
    ],
    115: ["https://fhir.dghs.gov.bd/core/full-ig.zip"],
    116: [
        "https://tr.ocl.dghs.gov.bd/api/orgs/MoHFW/collections/bd-condition-icd11-diagnosis-valueset/HEAD/expansions/autoexpand-HEAD/concepts/?limit=1000"
    ],
    117: [
        "https://fhir.dghs.gov.bd/core/ValueSet-bd-vaccine-valueset.json",
        "https://fhir.dghs.gov.bd/core/CodeSystem-bd-vaccine-code.json",
    ],
    118: [
        "https://data.gov.bd/sites/default/files/data-resource/2016/10/18/Doctor-Directory.xls"
    ],
}

FACILITY_CSV = (
    EXTRACTED_ROOT
    / "114_DGHS_Active_Facility_Registry"
    / "table_0001.csv"
)
FHIR_INVENTORY_CSV = (
    EXTRACTED_ROOT
    / "115_Bangladesh_Core_FHIR_IG"
    / "table_0001.csv"
)
CONDITION_CSV = (
    EXTRACTED_ROOT
    / "116_Bangladesh_ICD11_Condition_ValueSet"
    / "table_0001.csv"
)
VACCINE_CSV = (
    EXTRACTED_ROOT
    / "117_Bangladesh_Vaccine_Value_Set"
    / "table_0001.csv"
)
DOCTOR_CSV = (
    EXTRACTED_ROOT
    / "118_Bangladesh_Open_Data_Doctor_Directory"
    / "table_0001.csv"
)

CLEAN_FACILITY_CSV = CLEANED_ROOT / "114_DGHS_Active_Facility_Registry" / "HealthFacility.csv"
CLEAN_LAB_CSV = CLEANED_ROOT / "114_DGHS_Active_Facility_Registry" / "Laboratory.csv"
CLEAN_DISEASE_CSV = CLEANED_ROOT / "116_Bangladesh_ICD11_Condition_ValueSet" / "Disease.csv"
CLEAN_VACCINE_CSV = CLEANED_ROOT / "117_Bangladesh_Vaccine_Value_Set" / "VaccineReference.csv"
CLEAN_DESIGNATION_CSV = CLEANED_ROOT / "118_Bangladesh_Open_Data_Doctor_Directory" / "Designation.csv"

DIVISION_TO_REGION = {
    "Dhaka": 1,
    "Chattogram": 2,
    "Rajshahi": 3,
    "Khulna": 4,
    "Barishal": 5,
    "Sylhet": 6,
    "Rangpur": 7,
    "Mymensingh": 8,
}

LAB_FACILITY_TYPES = {
    "Consultancy & Diagnostic Center",
    "Blood Bank",
    "Drug Testing Laboratory",
}

EXPECTED_FACILITIES = 39_434
EXPECTED_LABS = 9_694
EXPECTED_CONDITIONS = 18_508
EXPECTED_RAW_POSTS = 68
EXPECTED_CLEAN_NEW_POSTS = 54
BASELINE_TOTAL_ROWS = 495

FACILITY_ID_OFFSET = 100_000
LAB_ID_OFFSET = 200_000
DISEASE_ID_OFFSET = 300_000
DESIGNATION_ID_OFFSET = 400_000


def write_csv(path: Path, rows: list[dict[str, object]], columns: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def write_source_metadata(
    *,
    catalog_row: int,
    slug: str,
    source_name: str,
    source_url: str,
    raw_files: list[Path],
    extracted_file: Path,
    extracted_rows: int,
    extracted_columns: int,
    release_or_snapshot: str,
    sql_mapping: dict[str, int],
    exclusion_note: str,
) -> None:
    METADATA_ROOT.mkdir(parents=True, exist_ok=True)
    payload = {
        "catalog_row": catalog_row,
        "source_name": source_name,
        "source_url": source_url,
        "download_urls": SOURCE_DOWNLOAD_URLS[catalog_row],
        "bangladesh_only": True,
        "collection_date": "2026-09-01",
        "release_or_snapshot": release_or_snapshot,
        "raw_files": [
            {
                "file": str(path.relative_to(ROOT)),
                "sha256": sha256(path),
            }
            for path in raw_files
        ],
        "extracted_tables": [
            {
                "file": str(extracted_file.relative_to(ROOT)),
                "rows": extracted_rows,
                "columns": extracted_columns,
            }
        ],
        "sql_mapping": sql_mapping,
        "exclusion_note": exclusion_note,
        "pipeline": [
            "catalogued_in_health_data.xlsx",
            "raw_source_archived",
            "table_extracted",
            "mapping_cleaned" if sql_mapping else "reference_reviewed",
            "loaded_by_migration_006" if sql_mapping else "retained_as_reference_only",
            "validated",
        ],
    }
    destination = METADATA_ROOT / f"{catalog_row}_{slug}.json"
    destination.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def extract_source_tables() -> None:
    """Convert every new raw source into an auditable extracted CSV table."""

    facility = pd.read_excel(FACILITY_RAW, dtype=str, keep_default_na=False)
    assert facility.shape == (EXPECTED_FACILITIES, 14), facility.shape
    FACILITY_CSV.parent.mkdir(parents=True, exist_ok=True)
    facility.to_csv(FACILITY_CSV, index=False, encoding="utf-8-sig")

    with ZipFile(FHIR_IG_RAW) as archive:
        package_rows = [
            {
                "member_path": item.filename,
                "uncompressed_bytes": item.file_size,
                "compressed_bytes": item.compress_size,
                "crc32": f"{item.CRC:08x}",
                "is_directory": int(item.is_dir()),
            }
            for item in archive.infolist()
        ]
    write_csv(
        FHIR_INVENTORY_CSV,
        package_rows,
        ["member_path", "uncompressed_bytes", "compressed_bytes", "crc32", "is_directory"],
    )

    condition_rows = json.loads(CONDITION_RAW.read_text(encoding="utf-8"))
    assert len(condition_rows) == EXPECTED_CONDITIONS
    condition_extract = [
        {
            "id": str(row["id"]).strip(),
            "display_name": str(row["display_name"]).strip(),
            "concept_class": str(row["concept_class"]).strip(),
            "source": str(row["source"]).strip(),
            "latest_source_version": str(row["latest_source_version"]).strip(),
        }
        for row in condition_rows
    ]
    write_csv(
        CONDITION_CSV,
        condition_extract,
        ["id", "display_name", "concept_class", "source", "latest_source_version"],
    )

    vaccine_payload = json.loads(VACCINE_CODE_SYSTEM_RAW.read_text(encoding="utf-8"))
    vaccine_rows = [
        {
            "code": str(item["code"]).strip(),
            "display": str(item["display"]).strip(),
            "definition": str(item["definition"]).strip(),
            "code_system": str(vaccine_payload["url"]),
            "version": str(vaccine_payload["version"]),
        }
        for item in vaccine_payload["concept"]
    ]
    assert len(vaccine_rows) == 10
    write_csv(
        VACCINE_CSV,
        vaccine_rows,
        ["code", "display", "definition", "code_system", "version"],
    )

    doctor = pd.read_excel(DOCTOR_RAW, dtype=str, keep_default_na=False, engine="xlrd")
    assert doctor.shape == (199, 11), doctor.shape
    DOCTOR_CSV.parent.mkdir(parents=True, exist_ok=True)
    doctor.to_csv(DOCTOR_CSV, index=False, encoding="utf-8-sig")

    write_source_metadata(
        catalog_row=114,
        slug="DGHS_Active_Facility_Registry",
        source_name="DGHS Active Facility Registry (Bangladesh)",
        source_url="https://hrm.dghs.gov.bd/public/facility-registry",
        raw_files=[FACILITY_RAW],
        extracted_file=FACILITY_CSV,
        extracted_rows=len(facility),
        extracted_columns=len(facility.columns),
        release_or_snapshot="Live active-facility snapshot collected 2026-09-01",
        sql_mapping={"HealthFacility": EXPECTED_FACILITIES, "Laboratory": EXPECTED_LABS},
        exclusion_note="Only three laboratory/diagnostic facility types create Laboratory rows.",
    )
    write_source_metadata(
        catalog_row=115,
        slug="Bangladesh_Core_FHIR_IG",
        source_name="Bangladesh Core FHIR Implementation Guide v0.4.6",
        source_url="https://fhir.dghs.gov.bd/core/artifacts.html",
        raw_files=[FHIR_IG_RAW],
        extracted_file=FHIR_INVENTORY_CSV,
        extracted_rows=len(package_rows),
        extracted_columns=5,
        release_or_snapshot="v0.4.6 generated 2026-04-27",
        sql_mapping={},
        exclusion_note="Documentation/package inventory; terminology content is loaded from catalog rows 116 and 117.",
    )
    write_source_metadata(
        catalog_row=116,
        slug="Bangladesh_ICD11_Condition_ValueSet",
        source_name="Bangladesh ICD-11 MMS Condition ValueSet",
        source_url="https://fhir.dghs.gov.bd/core/ValueSet-bd-condition-icd11-diagnosis-valueset.html",
        raw_files=[CONDITION_RAW],
        extracted_file=CONDITION_CSV,
        extracted_rows=len(condition_extract),
        extracted_columns=5,
        release_or_snapshot="ICD-11-MMS 2025-01 expansion collected 2026-09-01",
        sql_mapping={"Disease": EXPECTED_CONDITIONS},
        exclusion_note="All displayable Diagnosis and Finding concepts returned by the archived public expansion are included.",
    )
    write_source_metadata(
        catalog_row=117,
        slug="Bangladesh_Vaccine_Value_Set",
        source_name="Bangladesh Vaccine Value Set",
        source_url="https://fhir.dghs.gov.bd/core/ValueSet-bd-vaccine-valueset.html",
        raw_files=[VACCINE_VALUESET_RAW, VACCINE_CODE_SYSTEM_RAW],
        extracted_file=VACCINE_CSV,
        extracted_rows=len(vaccine_rows),
        extracted_columns=5,
        release_or_snapshot="v0.4.6 generated 2026-04-27",
        sql_mapping={},
        exclusion_note="Terminology has no PatientID or vaccination date, so it is not converted into patient events.",
    )
    write_source_metadata(
        catalog_row=118,
        slug="Bangladesh_Open_Data_Doctor_Directory",
        source_name="Bangladesh Open Data Doctor Directory",
        source_url="https://data.gov.bd/dataset/doctor-directory",
        raw_files=[DOCTOR_RAW],
        extracted_file=DOCTOR_CSV,
        extracted_rows=len(doctor),
        extracted_columns=len(doctor.columns),
        release_or_snapshot="Released 2016-10-18; metadata modified 2017-01-18",
        sql_mapping={"Designation": EXPECTED_CLEAN_NEW_POSTS},
        exclusion_note="Provider rows lack mandatory Gender and therefore are not inserted as HealthWorker records.",
    )


def normalize(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.casefold())


def sql_text(value: str) -> str:
    value = value.replace("\x00", "").replace("\r", " ").replace("\n", " ")
    value = re.sub(r"\s+", " ", value).strip()
    value = value.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{value}'"


def sql_tuple(values: tuple[object, ...]) -> str:
    encoded = []
    for value in values:
        if isinstance(value, int):
            encoded.append(str(value))
        elif isinstance(value, str):
            encoded.append(sql_text(value))
        else:
            raise TypeError(f"Unsupported SQL value: {value!r}")
    return "(" + ",".join(encoded) + ")"


def chunks(values: list[tuple[object, ...]], size: int = 500):
    for start in range(0, len(values), size):
        yield values[start : start + size]


def insert_statements(
    table: str,
    columns: tuple[str, ...],
    rows: list[tuple[object, ...]],
    *,
    upsert: bool,
) -> str:
    statements = []
    column_sql = ", ".join(f"`{column}`" for column in columns)
    update_columns = columns[1:]
    for group in chunks(rows):
        prefix = f"INSERT INTO `{table}` ({column_sql}) VALUES\n"
        statement = prefix + ",\n".join(sql_tuple(row) for row in group)
        if upsert:
            updates = ", ".join(
                f"`{column}` = VALUES(`{column}`)" for column in update_columns
            )
            statement += f"\nON DUPLICATE KEY UPDATE {updates}"
        statements.append(statement + ";")
    return "\n\n".join(statements)


def load_facilities() -> list[dict[str, str]]:
    with FACILITY_CSV.open(encoding="utf-8-sig", newline="") as handle:
        rows = [row for row in csv.DictReader(handle) if any(v.strip() for v in row.values())]

    assert len(rows) == EXPECTED_FACILITIES, len(rows)
    for field in ("Id", "Name", "Type", "Division"):
        assert all(row[field].strip() for row in rows), f"blank {field}"
    assert len({row["Id"].strip() for row in rows}) == len(rows), "duplicate facility ID"
    assert set(row["Division"].strip() for row in rows) == set(DIVISION_TO_REGION)
    return rows


def load_conditions() -> list[dict[str, object]]:
    with CONDITION_CSV.open(encoding="utf-8-sig", newline="") as handle:
        rows = [row for row in csv.DictReader(handle) if any(v.strip() for v in row.values())]
    assert len(rows) == EXPECTED_CONDITIONS, len(rows)
    assert all(str(row["id"]).strip() for row in rows)
    assert all(str(row["display_name"]).strip() for row in rows)
    assert len({str(row["id"]).strip() for row in rows}) == len(rows)
    assert {str(row["concept_class"]) for row in rows} == {"Diagnosis", "Finding"}
    assert {str(row["source"]) for row in rows} == {"ICD-11-MMS"}
    assert {str(row["latest_source_version"]) for row in rows} == {"2025-01"}
    return rows


def existing_designations(full_dump: str) -> list[str]:
    match = re.search(r"INSERT INTO `Designation` VALUES (.*?);", full_dump, re.DOTALL)
    assert match
    values = []
    for item in re.finditer(r"\(\d+,'((?:\\'|[^'])*)'\)", match.group(1)):
        values.append(item.group(1).replace("\\'", "'").replace("\\\\", "\\"))
    assert len(values) == 31, len(values)
    return values


def load_new_designations(full_dump: str) -> list[str]:
    with DOCTOR_CSV.open(encoding="utf-8-sig", newline="") as handle:
        rows = [row for row in csv.DictReader(handle) if any(v.strip() for v in row.values())]
    assert len(rows) == 199, len(rows)
    assert all(row["Post"].strip() for row in rows)
    assert all(row["Provider"].strip() for row in rows)
    assert all(row["facility"].strip() for row in rows)

    raw_posts = sorted({row["Post"].strip() for row in rows}, key=str.casefold)
    assert len(raw_posts) == EXPECTED_RAW_POSTS, len(raw_posts)
    clean_posts = [post for post in raw_posts if " - " not in post]
    existing = {normalize(value) for value in existing_designations(full_dump)}
    new_posts = [post for post in clean_posts if normalize(post) not in existing]
    assert len(new_posts) == EXPECTED_CLEAN_NEW_POSTS, len(new_posts)
    assert len({normalize(post) for post in new_posts}) == len(new_posts)
    return new_posts


def source_rows(full_dump: str):
    facility_source = load_facilities()
    condition_source = load_conditions()
    designation_source = load_new_designations(full_dump)

    facility_rows = []
    laboratory_rows = []
    for row in sorted(facility_source, key=lambda item: int(item["Id"])):
        source_id = int(row["Id"])
        source_name = row["Name"].strip()
        source_type = row["Type"].strip()
        region_id = DIVISION_TO_REGION[row["Division"].strip()]
        facility_id = FACILITY_ID_OFFSET + source_id
        traceable_name = f"{source_name} [DGHS Facility ID {source_id}]"
        facility_rows.append((facility_id, source_type, traceable_name, region_id))
        if source_type in LAB_FACILITY_TYPES:
            lab_id = LAB_ID_OFFSET + source_id
            lab_name = f"{source_name} — {source_type} [DGHS Facility ID {source_id}]"
            laboratory_rows.append((lab_id, lab_name, facility_id))

    assert len(facility_rows) == EXPECTED_FACILITIES
    assert len(laboratory_rows) == EXPECTED_LABS
    assert len({row[0] for row in facility_rows}) == len(facility_rows)
    assert len({normalize(str(row[2])) for row in facility_rows}) == len(facility_rows)
    assert len({row[0] for row in laboratory_rows}) == len(laboratory_rows)
    assert len({normalize(str(row[1])) for row in laboratory_rows}) == len(laboratory_rows)
    facility_ids = {row[0] for row in facility_rows}
    assert all(row[2] in facility_ids for row in laboratory_rows)

    disease_rows = []
    for index, row in enumerate(
        sorted(condition_source, key=lambda item: str(item["id"]).casefold()), start=1
    ):
        disease_rows.append(
            (
                DISEASE_ID_OFFSET + index,
                str(row["display_name"]).strip(),
                str(row["id"]).strip(),
            )
        )
    assert len(disease_rows) == EXPECTED_CONDITIONS
    assert len({row[2] for row in disease_rows}) == len(disease_rows)

    designation_rows = [
        (DESIGNATION_ID_OFFSET + index, post)
        for index, post in enumerate(designation_source, start=1)
    ]
    return designation_rows, disease_rows, facility_rows, laboratory_rows, condition_source


def write_mapping_outputs(
    designation_rows: list[tuple[object, ...]],
    disease_rows: list[tuple[object, ...]],
    facility_rows: list[tuple[object, ...]],
    laboratory_rows: list[tuple[object, ...]],
) -> None:
    """Write mapping-ready tables, matching the original extracted/cleaned flow."""

    write_csv(
        CLEAN_DESIGNATION_CSV,
        [
            {"DesignationID": row[0], "DesignationName": row[1]}
            for row in designation_rows
        ],
        ["DesignationID", "DesignationName"],
    )
    write_csv(
        CLEAN_DISEASE_CSV,
        [
            {"DiseaseID": row[0], "DiseaseName": row[1], "ICDCode": row[2]}
            for row in disease_rows
        ],
        ["DiseaseID", "DiseaseName", "ICDCode"],
    )
    write_csv(
        CLEAN_FACILITY_CSV,
        [
            {
                "FacilityID": row[0],
                "FacilityType": row[1],
                "FacilityName": row[2],
                "RegionID": row[3],
            }
            for row in facility_rows
        ],
        ["FacilityID", "FacilityType", "FacilityName", "RegionID"],
    )
    write_csv(
        CLEAN_LAB_CSV,
        [
            {"LabID": row[0], "LabName": row[1], "FacilityID": row[2]}
            for row in laboratory_rows
        ],
        ["LabID", "LabName", "FacilityID"],
    )

    with VACCINE_CSV.open(encoding="utf-8-sig", newline="") as handle:
        vaccine_rows = list(csv.DictReader(handle))
    write_csv(
        CLEAN_VACCINE_CSV,
        vaccine_rows,
        ["code", "display", "definition", "code_system", "version"],
    )

    manifest_rows = [
        {
            "catalog_row": 114,
            "source": "DGHS Active Facility Registry",
            "raw_file": str(FACILITY_RAW.relative_to(ROOT)),
            "extracted_file": str(FACILITY_CSV.relative_to(ROOT)),
            "extracted_rows": EXPECTED_FACILITIES,
            "cleaned_files": "; ".join(
                [
                    str(CLEAN_FACILITY_CSV.relative_to(ROOT)),
                    str(CLEAN_LAB_CSV.relative_to(ROOT)),
                ]
            ),
            "sql_tables": "HealthFacility; Laboratory",
            "inserted_rows": EXPECTED_FACILITIES + EXPECTED_LABS,
            "status": "loaded",
        },
        {
            "catalog_row": 115,
            "source": "Bangladesh Core FHIR IG v0.4.6",
            "raw_file": str(FHIR_IG_RAW.relative_to(ROOT)),
            "extracted_file": str(FHIR_INVENTORY_CSV.relative_to(ROOT)),
            "extracted_rows": 1529,
            "cleaned_files": "",
            "sql_tables": "",
            "inserted_rows": 0,
            "status": "reference package",
        },
        {
            "catalog_row": 116,
            "source": "Bangladesh ICD-11 Condition ValueSet",
            "raw_file": str(CONDITION_RAW.relative_to(ROOT)),
            "extracted_file": str(CONDITION_CSV.relative_to(ROOT)),
            "extracted_rows": EXPECTED_CONDITIONS,
            "cleaned_files": str(CLEAN_DISEASE_CSV.relative_to(ROOT)),
            "sql_tables": "Disease",
            "inserted_rows": EXPECTED_CONDITIONS,
            "status": "loaded",
        },
        {
            "catalog_row": 117,
            "source": "Bangladesh Vaccine Value Set",
            "raw_file": str(VACCINE_CODE_SYSTEM_RAW.relative_to(ROOT)),
            "extracted_file": str(VACCINE_CSV.relative_to(ROOT)),
            "extracted_rows": 10,
            "cleaned_files": str(CLEAN_VACCINE_CSV.relative_to(ROOT)),
            "sql_tables": "",
            "inserted_rows": 0,
            "status": "reference only: no patient event fields",
        },
        {
            "catalog_row": 118,
            "source": "Bangladesh Open Data Doctor Directory",
            "raw_file": str(DOCTOR_RAW.relative_to(ROOT)),
            "extracted_file": str(DOCTOR_CSV.relative_to(ROOT)),
            "extracted_rows": 199,
            "cleaned_files": str(CLEAN_DESIGNATION_CSV.relative_to(ROOT)),
            "sql_tables": "Designation",
            "inserted_rows": EXPECTED_CLEAN_NEW_POSTS,
            "status": "designations loaded; providers excluded because Gender is absent",
        },
    ]
    write_csv(
        PIPELINE_MANIFEST,
        manifest_rows,
        [
            "catalog_row",
            "source",
            "raw_file",
            "extracted_file",
            "extracted_rows",
            "cleaned_files",
            "sql_tables",
            "inserted_rows",
            "status",
        ],
    )


def read_cleaned_rows(path: Path, columns: tuple[str, ...]) -> list[tuple[object, ...]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        records = list(csv.DictReader(handle))
    rows: list[tuple[object, ...]] = []
    for record in records:
        values: list[object] = []
        for index, column in enumerate(columns):
            value = record[column].strip()
            values.append(int(value) if index == 0 or column.endswith("ID") else value)
        rows.append(tuple(values))
    return rows


def load_mapping_outputs():
    """Read the cleaned mapping layer that directly feeds migration SQL."""

    designation_rows = read_cleaned_rows(
        CLEAN_DESIGNATION_CSV, ("DesignationID", "DesignationName")
    )
    disease_rows = read_cleaned_rows(
        CLEAN_DISEASE_CSV, ("DiseaseID", "DiseaseName", "ICDCode")
    )
    facility_rows = read_cleaned_rows(
        CLEAN_FACILITY_CSV,
        ("FacilityID", "FacilityType", "FacilityName", "RegionID"),
    )
    laboratory_rows = read_cleaned_rows(
        CLEAN_LAB_CSV, ("LabID", "LabName", "FacilityID")
    )
    assert len(designation_rows) == EXPECTED_CLEAN_NEW_POSTS
    assert len(disease_rows) == EXPECTED_CONDITIONS
    assert len(facility_rows) == EXPECTED_FACILITIES
    assert len(laboratory_rows) == EXPECTED_LABS
    return designation_rows, disease_rows, facility_rows, laboratory_rows


def strip_generated_blocks(sql: str) -> str:
    pattern = re.compile(
        r"\n-- BEGIN GENERATED 006 [^\n]+\n.*?\n-- END GENERATED 006 [^\n]+\n",
        re.DOTALL,
    )
    return pattern.sub("\n", sql)


def inject_generated_rows(
    sql: str,
    table: str,
    columns: tuple[str, ...],
    rows: list[tuple[object, ...]],
) -> str:
    anchor = f"/*!40000 ALTER TABLE `{table}` ENABLE KEYS */;"
    assert sql.count(anchor) == 1, table
    body = insert_statements(table, columns, rows, upsert=False)
    block = (
        f"-- BEGIN GENERATED 006 {table}\n"
        f"{body}\n"
        f"-- END GENERATED 006 {table}\n"
    )
    return sql.replace(anchor, block + anchor)


def set_auto_increment(sql: str, table: str, next_id: int) -> str:
    pattern = re.compile(
        rf"(CREATE TABLE `{re.escape(table)}` \(.*?\) ENGINE=InnoDB AUTO_INCREMENT=)\d+",
        re.DOTALL,
    )
    updated, count = pattern.subn(rf"\g<1>{next_id}", sql, count=1)
    assert count == 1, table
    return updated


def build_migration(
    designation_rows,
    disease_rows,
    facility_rows,
    laboratory_rows,
) -> str:
    sections = [
        "-- Bangladesh-only national-scale expansion for the existing 21-table schema.",
        "-- Sources: DGHS Facility Registry, DGHS/MoHFW Bangladesh Core FHIR/OCL,",
        "-- and Bangladesh Open Data Doctor Directory. See DATA_PROVENANCE.md.",
        "-- ICD-11 content is copyright World Health Organization and is used under",
        "-- the licensing notice published by the Bangladesh Core FHIR guide.",
        "SET NAMES utf8mb4;",
        "START TRANSACTION;",
        insert_statements(
            "Designation",
            ("DesignationID", "DesignationName"),
            designation_rows,
            upsert=True,
        ),
        insert_statements(
            "Disease",
            ("DiseaseID", "DiseaseName", "ICDCode"),
            disease_rows,
            upsert=True,
        ),
        insert_statements(
            "HealthFacility",
            ("FacilityID", "FacilityType", "FacilityName", "RegionID"),
            facility_rows,
            upsert=True,
        ),
        insert_statements(
            "Laboratory",
            ("LabID", "LabName", "FacilityID"),
            laboratory_rows,
            upsert=True,
        ),
        "COMMIT;",
        "",
        "SELECT 'source_006_designations' AS check_name, COUNT(*) AS row_count FROM `Designation` WHERE `DesignationID` BETWEEN 400001 AND 400054;",
        "SELECT 'source_006_conditions' AS check_name, COUNT(*) AS row_count FROM `Disease` WHERE `DiseaseID` BETWEEN 300001 AND 318508;",
        "SELECT 'source_006_facilities' AS check_name, COUNT(*) AS row_count FROM `HealthFacility` WHERE `FacilityID` BETWEEN 100001 AND 199999;",
        "SELECT 'source_006_laboratories' AS check_name, COUNT(*) AS row_count FROM `Laboratory` WHERE `LabID` BETWEEN 200001 AND 299999;",
    ]
    return "\n\n".join(sections) + "\n"


def parse_insert_counts(sql: str) -> Counter[str]:
    counts: Counter[str] = Counter()
    pattern = re.compile(r"INSERT INTO `([^`]+)`(?: \([^;]*?\))? VALUES\s*", re.DOTALL)
    for match in pattern.finditer(sql):
        table = match.group(1)
        index = match.end()
        quoted = False
        escaped = False
        count = 0
        while index < len(sql):
            char = sql[index]
            if escaped:
                escaped = False
            elif char == "\\" and quoted:
                escaped = True
            elif char == "'":
                quoted = not quoted
            elif char == ";" and not quoted:
                break
            elif char == "(" and not quoted:
                count += 1
            index += 1
        counts[table] += count
    return counts


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    extract_source_tables()
    original_full_dump = strip_generated_blocks(FULL_DUMP.read_text(encoding="utf-8"))
    mapped_designations, mapped_diseases, mapped_facilities, mapped_laboratories, condition_source = (
        source_rows(original_full_dump)
    )
    write_mapping_outputs(
        mapped_designations,
        mapped_diseases,
        mapped_facilities,
        mapped_laboratories,
    )
    designation_rows, disease_rows, facility_rows, laboratory_rows = (
        load_mapping_outputs()
    )

    migration = build_migration(
        designation_rows, disease_rows, facility_rows, laboratory_rows
    )
    MIGRATION.write_text(migration, encoding="utf-8")

    full_dump = original_full_dump
    full_dump = inject_generated_rows(
        full_dump,
        "Designation",
        ("DesignationID", "DesignationName"),
        designation_rows,
    )
    full_dump = inject_generated_rows(
        full_dump,
        "Disease",
        ("DiseaseID", "DiseaseName", "ICDCode"),
        disease_rows,
    )
    full_dump = inject_generated_rows(
        full_dump,
        "HealthFacility",
        ("FacilityID", "FacilityType", "FacilityName", "RegionID"),
        facility_rows,
    )
    full_dump = inject_generated_rows(
        full_dump,
        "Laboratory",
        ("LabID", "LabName", "FacilityID"),
        laboratory_rows,
    )

    next_ids = {
        "Designation": max(row[0] for row in designation_rows) + 1,
        "Disease": max(row[0] for row in disease_rows) + 1,
        "HealthFacility": max(row[0] for row in facility_rows) + 1,
        "Laboratory": max(row[0] for row in laboratory_rows) + 1,
    }
    for table, next_id in next_ids.items():
        full_dump = set_auto_increment(full_dump, table, next_id)
    FULL_DUMP.write_text(full_dump, encoding="utf-8")

    schema = SCHEMA_DUMP.read_text(encoding="utf-8")
    for table, next_id in next_ids.items():
        schema = set_auto_increment(schema, table, next_id)
    SCHEMA_DUMP.write_text(schema, encoding="utf-8")

    counts = parse_insert_counts(full_dump)
    expected = {
        "AdministrativeRegion": 8,
        "Biopsy": 12,
        "CancerCase": 12,
        "Covid19": 20,
        "Dengue": 15,
        "Designation": 31 + EXPECTED_CLEAN_NEW_POSTS,
        "Diarrhea": 15,
        "Disease": 9 + EXPECTED_CONDITIONS,
        "HealthFacility": 180 + EXPECTED_FACILITIES,
        "HealthWorker": 12,
        "HIV": 15,
        "HospitalBed": 60,
        "Laboratory": 15 + EXPECTED_LABS,
        "Malnutrition": 15,
        "MaternalHealth": 12,
        "Measles": 15,
        "Newborn": 10,
        "Patient": 15,
        "PopulationGroup": 8,
        "TelemedicineCenter": 10,
        "Vaccination": 6,
    }
    assert dict(counts) == expected, (counts, expected)
    expected_total = BASELINE_TOTAL_ROWS + sum(
        (EXPECTED_FACILITIES, EXPECTED_LABS, EXPECTED_CONDITIONS, EXPECTED_CLEAN_NEW_POSTS)
    )
    assert sum(counts.values()) == expected_total

    concept_classes = Counter(str(row["concept_class"]) for row in condition_source)
    facility_regions = Counter(row[3] for row in facility_rows)
    facility_region_by_id = {facility[0]: facility[3] for facility in facility_rows}
    lab_regions = Counter(facility_region_by_id[lab[2]] for lab in laboratory_rows)

    lines = [
        "BANGLADESH NATIONAL-SCALE STATIC VALIDATION",
        "",
        f"baseline_rows={BASELINE_TOTAL_ROWS}",
        f"added_designations={len(designation_rows)}",
        f"added_conditions={len(disease_rows)}",
        f"added_facilities={len(facility_rows)}",
        f"added_laboratories={len(laboratory_rows)}",
        f"final_total_rows={sum(counts.values())}",
        "",
        "TABLE COUNTS",
    ]
    lines.extend(f"{table}={expected[table]}" for table in sorted(expected))
    lines.extend(
        [
            "",
            "SOURCE CHECKS",
            "facility_blank_required_fields=0",
            "facility_duplicate_ids=0",
            "facility_unmapped_divisions=0",
            "laboratory_orphan_facility_ids=0",
            "condition_blank_codes=0",
            "condition_blank_names=0",
            "condition_duplicate_codes=0",
            "pipeline_catalog_rows=5",
            "pipeline_raw_source_entries_archived=5",
            "pipeline_raw_files_archived=6",
            "pipeline_extracted_tables=5",
            "pipeline_sql_tables_loaded=4",
            "facility_extracted_rows=39434",
            "fhir_package_inventory_rows=1529",
            "condition_extracted_rows=18508",
            "vaccine_reference_rows_not_imported=10",
            "doctor_directory_extracted_rows=199",
            "source_006_sql_rows_inserted=67690",
            f"condition_class_Diagnosis={concept_classes['Diagnosis']}",
            f"condition_class_Finding={concept_classes['Finding']}",
            "doctor_directory_provider_rows_not_imported=199",
            "doctor_directory_reason=HealthWorker.Gender is required but absent from source",
            "",
            "FACILITY COUNTS BY REGION ID",
        ]
    )
    lines.extend(f"region_{region_id}={facility_regions[region_id]}" for region_id in range(1, 9))
    lines.append("")
    lines.append("LABORATORY COUNTS BY REGION ID")
    lines.extend(f"region_{region_id}={lab_regions[region_id]}" for region_id in range(1, 9))
    lines.extend(
        [
            "",
            "ARCHIVE SHA256",
            f"facility_xlsx={sha256(ROOT / 'source_datasets' / 'dghs_active_facility_registry_2026-09-01.xlsx')}",
            f"facility_csv={sha256(FACILITY_CSV)}",
            f"condition_json={sha256(CONDITION_RAW)}",
            f"doctor_xls={sha256(ROOT / 'source_datasets' / 'bangladesh_open_data_doctor_directory_2016.xls')}",
            f"doctor_csv={sha256(DOCTOR_CSV)}",
            f"fhir_full_ig_zip={sha256(ROOT / 'source_datasets' / 'bd_core_fhir_ig_0.4.6_full.zip')}",
            f"vaccine_valueset_json={sha256(ROOT / 'source_datasets' / 'bd_vaccine_valueset_0.4.6.json')}",
            f"vaccine_code_system_json={sha256(ROOT / 'source_datasets' / 'bd_vaccine_code_system_0.4.6.json')}",
            f"pipeline_manifest={sha256(PIPELINE_MANIFEST)}",
            "",
            "NOTE: This is deterministic source/dump validation, not a live MySQL restore test.",
            "Run the documented isolated restore before commit/push.",
        ]
    )
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    relational_export = runpy.run_path(
        str(ROOT / "scripts" / "12_export_verified_relational_tables.py"),
        run_name="verified_relational_export_module",
    )
    relational_export["main"]()
    print("\n".join(lines[:14]))


if __name__ == "__main__":
    main()
