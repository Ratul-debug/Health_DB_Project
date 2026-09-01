#!/usr/bin/env python3
"""Download and validate the five Bangladesh-only catalog source entries."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import requests


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "source_datasets"
TIMEOUT = 120

FACILITY_URL = "https://hrm.dghs.gov.bd/public/facility-registry/reports/organization-list?is_active=1&submit=Run&columns_csv=id%2Cname%2Cname_bn%2Ccode%2Cemail_1%2Cfacility_agency_name%2Cfacility_type_name%2Cdivision_name%2Cdistrict_name%2Ccity_corporation_name%2Cupazila_name%2Cpaurasava_name%2Cunion_name%2Cis_private&alias_columns_csv=ID%2CName%2CName+%28Bangla%29%2CCode%2CEmail%2CAgency%2CType%2CDivision%2CDistrict%2CCity+Corporation%2CUpazila%2CPaurasava%2CUnion%2CPrivate&ret=excel"
FHIR_IG_URL = "https://fhir.dghs.gov.bd/core/full-ig.zip"
CONDITION_URL = "https://tr.ocl.dghs.gov.bd/api/orgs/MoHFW/collections/bd-condition-icd11-diagnosis-valueset/HEAD/expansions/autoexpand-HEAD/concepts/"
VACCINE_VALUESET_URL = "https://fhir.dghs.gov.bd/core/ValueSet-bd-vaccine-valueset.json"
VACCINE_CODE_SYSTEM_URL = "https://fhir.dghs.gov.bd/core/CodeSystem-bd-vaccine-code.json"
DOCTOR_URL = "https://data.gov.bd/sites/default/files/data-resource/2016/10/18/Doctor-Directory.xls"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def save_validated_binary(url: str, destination: Path, signature: bytes) -> None:
    response = requests.get(url, timeout=TIMEOUT)
    response.raise_for_status()
    content = response.content
    if not content.startswith(signature):
        raise ValueError(f"Unexpected file signature from {url}")
    temporary = destination.with_suffix(destination.suffix + ".part")
    temporary.write_bytes(content)
    temporary.replace(destination)


def save_validated_json(url: str, destination: Path) -> None:
    response = requests.get(url, timeout=TIMEOUT)
    response.raise_for_status()
    payload = response.json()
    temporary = destination.with_suffix(destination.suffix + ".part")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(destination)


def download_condition_expansion(destination: Path) -> int:
    concepts: list[dict[str, object]] = []
    page = 1
    while True:
        response = requests.get(
            CONDITION_URL,
            params={"limit": 1000, "page": page},
            timeout=TIMEOUT,
        )
        response.raise_for_status()
        batch = response.json()
        if not isinstance(batch, list):
            raise ValueError("Condition API returned a non-list payload")
        concepts.extend(batch)
        if len(batch) < 1000:
            break
        page += 1

    codes = [str(item.get("id", "")).strip() for item in concepts]
    names = [str(item.get("display_name", "")).strip() for item in concepts]
    if len(concepts) != 18_508:
        raise ValueError(f"Expected 18,508 Condition concepts; received {len(concepts):,}")
    if not all(codes) or not all(names) or len(set(codes)) != len(codes):
        raise ValueError("Condition expansion contains blank or duplicate codes/names")

    temporary = destination.with_suffix(destination.suffix + ".part")
    temporary.write_text(
        json.dumps(concepts, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(destination)
    return len(concepts)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    targets = {
        "facility": OUTPUT / "dghs_active_facility_registry_2026-09-01.xlsx",
        "fhir_ig": OUTPUT / "bd_core_fhir_ig_0.4.6_full.zip",
        "condition": OUTPUT / "bd_condition_icd11_2025_01_ocl.json",
        "vaccine_valueset": OUTPUT / "bd_vaccine_valueset_0.4.6.json",
        "vaccine_code_system": OUTPUT / "bd_vaccine_code_system_0.4.6.json",
        "doctor": OUTPUT / "bangladesh_open_data_doctor_directory_2016.xls",
    }

    save_validated_binary(FACILITY_URL, targets["facility"], b"PK")
    save_validated_binary(FHIR_IG_URL, targets["fhir_ig"], b"PK")
    condition_count = download_condition_expansion(targets["condition"])
    save_validated_json(VACCINE_VALUESET_URL, targets["vaccine_valueset"])
    save_validated_json(VACCINE_CODE_SYSTEM_URL, targets["vaccine_code_system"])
    save_validated_binary(DOCTOR_URL, targets["doctor"], bytes.fromhex("D0CF11E0"))

    print(f"Downloaded source entries: 5")
    print(f"Archived raw files       : {len(targets)}")
    print(f"Condition concepts       : {condition_count}")
    for label, path in targets.items():
        print(f"{label}_sha256={sha256(path)}")


if __name__ == "__main__":
    main()
