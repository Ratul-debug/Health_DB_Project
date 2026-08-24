-- Health DB Project: final integrity and demonstration queries

USE `health_db`;

-- Expected: 21 tables, 21 primary-key columns, 25 foreign-key columns,
-- and zero nullable columns.
SELECT COUNT(*) AS total_tables
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE';

SELECT COUNT(*) AS total_primary_key_columns
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() AND CONSTRAINT_NAME = 'PRIMARY';

SELECT COUNT(*) AS total_foreign_keys
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL;

SELECT COUNT(*) AS total_nullable_columns
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND IS_NULLABLE = 'YES';

-- Row counts for all 21 tables.
SELECT 'AdministrativeRegion' AS table_name, COUNT(*) AS row_count FROM `AdministrativeRegion`
UNION ALL SELECT 'Biopsy', COUNT(*) FROM `Biopsy`
UNION ALL SELECT 'CancerCase', COUNT(*) FROM `CancerCase`
UNION ALL SELECT 'Covid19', COUNT(*) FROM `Covid19`
UNION ALL SELECT 'Dengue', COUNT(*) FROM `Dengue`
UNION ALL SELECT 'Designation', COUNT(*) FROM `Designation`
UNION ALL SELECT 'Diarrhea', COUNT(*) FROM `Diarrhea`
UNION ALL SELECT 'Disease', COUNT(*) FROM `Disease`
UNION ALL SELECT 'HealthFacility', COUNT(*) FROM `HealthFacility`
UNION ALL SELECT 'HealthWorker', COUNT(*) FROM `HealthWorker`
UNION ALL SELECT 'HIV', COUNT(*) FROM `HIV`
UNION ALL SELECT 'HospitalBed', COUNT(*) FROM `HospitalBed`
UNION ALL SELECT 'Laboratory', COUNT(*) FROM `Laboratory`
UNION ALL SELECT 'Malnutrition', COUNT(*) FROM `Malnutrition`
UNION ALL SELECT 'MaternalHealth', COUNT(*) FROM `MaternalHealth`
UNION ALL SELECT 'Measles', COUNT(*) FROM `Measles`
UNION ALL SELECT 'Newborn', COUNT(*) FROM `Newborn`
UNION ALL SELECT 'Patient', COUNT(*) FROM `Patient`
UNION ALL SELECT 'PopulationGroup', COUNT(*) FROM `PopulationGroup`
UNION ALL SELECT 'TelemedicineCenter', COUNT(*) FROM `TelemedicineCenter`
UNION ALL SELECT 'Vaccination', COUNT(*) FROM `Vaccination`
ORDER BY table_name;

-- Expected after migration 005: 495 total demonstration rows and zero empty tables.
SELECT SUM(row_count) AS total_demonstration_rows,
       SUM(row_count = 0) AS empty_tables
FROM (
    SELECT COUNT(*) AS row_count FROM `AdministrativeRegion`
    UNION ALL SELECT COUNT(*) FROM `Biopsy`
    UNION ALL SELECT COUNT(*) FROM `CancerCase`
    UNION ALL SELECT COUNT(*) FROM `Covid19`
    UNION ALL SELECT COUNT(*) FROM `Dengue`
    UNION ALL SELECT COUNT(*) FROM `Designation`
    UNION ALL SELECT COUNT(*) FROM `Diarrhea`
    UNION ALL SELECT COUNT(*) FROM `Disease`
    UNION ALL SELECT COUNT(*) FROM `HealthFacility`
    UNION ALL SELECT COUNT(*) FROM `HealthWorker`
    UNION ALL SELECT COUNT(*) FROM `HIV`
    UNION ALL SELECT COUNT(*) FROM `HospitalBed`
    UNION ALL SELECT COUNT(*) FROM `Laboratory`
    UNION ALL SELECT COUNT(*) FROM `Malnutrition`
    UNION ALL SELECT COUNT(*) FROM `MaternalHealth`
    UNION ALL SELECT COUNT(*) FROM `Measles`
    UNION ALL SELECT COUNT(*) FROM `Newborn`
    UNION ALL SELECT COUNT(*) FROM `Patient`
    UNION ALL SELECT COUNT(*) FROM `PopulationGroup`
    UNION ALL SELECT COUNT(*) FROM `TelemedicineCenter`
    UNION ALL SELECT COUNT(*) FROM `Vaccination`
) AS table_counts;

-- Every result should be zero.
SELECT 'HealthFacility.RegionID' AS relationship_name, COUNT(*) AS orphan_rows
FROM `HealthFacility` c LEFT JOIN `AdministrativeRegion` p ON p.`RegionID` = c.`RegionID`
WHERE p.`RegionID` IS NULL
UNION ALL SELECT 'HealthWorker.FacilityID', COUNT(*)
FROM `HealthWorker` c LEFT JOIN `HealthFacility` p ON p.`FacilityID` = c.`FacilityID`
WHERE p.`FacilityID` IS NULL
UNION ALL SELECT 'HealthWorker.DesignationID', COUNT(*)
FROM `HealthWorker` c LEFT JOIN `Designation` p ON p.`DesignationID` = c.`DesignationID`
WHERE p.`DesignationID` IS NULL
UNION ALL SELECT 'HospitalBed.FacilityID', COUNT(*)
FROM `HospitalBed` c LEFT JOIN `HealthFacility` p ON p.`FacilityID` = c.`FacilityID`
WHERE p.`FacilityID` IS NULL
UNION ALL SELECT 'Laboratory.FacilityID', COUNT(*)
FROM `Laboratory` c LEFT JOIN `HealthFacility` p ON p.`FacilityID` = c.`FacilityID`
WHERE p.`FacilityID` IS NULL
UNION ALL SELECT 'Patient.BedID', COUNT(*)
FROM `Patient` c LEFT JOIN `HospitalBed` p ON p.`BedID` = c.`BedID`
WHERE p.`BedID` IS NULL
UNION ALL SELECT 'MaternalHealth.PatientID', COUNT(*)
FROM `MaternalHealth` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'Newborn.MotherID', COUNT(*)
FROM `Newborn` c LEFT JOIN `MaternalHealth` p ON p.`MotherID` = c.`MotherID`
WHERE p.`MotherID` IS NULL
UNION ALL SELECT 'PopulationGroup.RegionID', COUNT(*)
FROM `PopulationGroup` c LEFT JOIN `AdministrativeRegion` p ON p.`RegionID` = c.`RegionID`
WHERE p.`RegionID` IS NULL
UNION ALL SELECT 'TelemedicineCenter.PatientID', COUNT(*)
FROM `TelemedicineCenter` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'Vaccination.PatientID', COUNT(*)
FROM `Vaccination` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'Malnutrition.PatientID', COUNT(*)
FROM `Malnutrition` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'CancerCase.PatientID', COUNT(*)
FROM `CancerCase` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'CancerCase.LabID', COUNT(*)
FROM `CancerCase` c LEFT JOIN `Laboratory` p ON p.`LabID` = c.`LabID`
WHERE p.`LabID` IS NULL
UNION ALL SELECT 'Biopsy.CancerCaseID', COUNT(*)
FROM `Biopsy` c LEFT JOIN `CancerCase` p ON p.`CancerID` = c.`CancerCaseID`
WHERE p.`CancerID` IS NULL
UNION ALL SELECT 'Dengue.DiseaseID', COUNT(*)
FROM `Dengue` c LEFT JOIN `Disease` p ON p.`DiseaseID` = c.`DiseaseID`
WHERE p.`DiseaseID` IS NULL
UNION ALL SELECT 'Dengue.PatientID', COUNT(*)
FROM `Dengue` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'Covid19.DiseaseID', COUNT(*)
FROM `Covid19` c LEFT JOIN `Disease` p ON p.`DiseaseID` = c.`DiseaseID`
WHERE p.`DiseaseID` IS NULL
UNION ALL SELECT 'Covid19.PatientID', COUNT(*)
FROM `Covid19` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'Measles.DiseaseID', COUNT(*)
FROM `Measles` c LEFT JOIN `Disease` p ON p.`DiseaseID` = c.`DiseaseID`
WHERE p.`DiseaseID` IS NULL
UNION ALL SELECT 'Measles.PatientID', COUNT(*)
FROM `Measles` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'HIV.DiseaseID', COUNT(*)
FROM `HIV` c LEFT JOIN `Disease` p ON p.`DiseaseID` = c.`DiseaseID`
WHERE p.`DiseaseID` IS NULL
UNION ALL SELECT 'HIV.PatientID', COUNT(*)
FROM `HIV` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'Diarrhea.DiseaseID', COUNT(*)
FROM `Diarrhea` c LEFT JOIN `Disease` p ON p.`DiseaseID` = c.`DiseaseID`
WHERE p.`DiseaseID` IS NULL
UNION ALL SELECT 'Diarrhea.PatientID', COUNT(*)
FROM `Diarrhea` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL;

-- Semantic checks for the mixed-source demonstration data.
-- Every result should be zero.
SET @dhaka_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'dhaka' LIMIT 1);
SET @chattogram_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'chattogram' LIMIT 1);
SET @rajshahi_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'rajshahi' LIMIT 1);
SET @khulna_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'khulna' LIMIT 1);
SET @barishal_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'barishal' LIMIT 1);
SET @sylhet_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'sylhet' LIMIT 1);
SET @rangpur_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'rangpur' LIMIT 1);
SET @mymensingh_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'mymensingh' LIMIT 1);

SELECT 'facilities_without_region' AS quality_check, COUNT(*) AS issue_count
FROM `HealthFacility` WHERE `RegionID` IS NULL
UNION ALL
SELECT 'maternal_links_to_non_female_patient', COUNT(*)
FROM `MaternalHealth` m
JOIN `Patient` p ON p.`PatientID` = m.`PatientID`
WHERE LOWER(p.`Gender`) <> 'female'
UNION ALL
SELECT 'dengue_gender_mismatch', COUNT(*)
FROM `Dengue` d
JOIN `Patient` p ON p.`PatientID` = d.`PatientID`
WHERE LOWER(d.`Gender`) <> LOWER(p.`Gender`)
UNION ALL
SELECT 'designation_person_name_fragments', COUNT(*)
FROM `Designation`
WHERE LOWER(`DesignationName`) REGEXP '^(dr|ms|md|mst)[.]?[[:space:]]'
UNION ALL
SELECT 'laboratory_legend_fragments', COUNT(*)
FROM `Laboratory` WHERE `LabName` LIKE 'LAB=%'
UNION ALL
SELECT 'dirty_disease_fragment_ids', COUNT(*)
FROM `Disease` WHERE `DiseaseID` BETWEEN 1 AND 11
UNION ALL
SELECT 'cancer_cases_without_stage', COUNT(*)
FROM `CancerCase` WHERE `CancerStage` IS NULL
UNION ALL
SELECT 'diseases_without_icd_code', COUNT(*)
FROM `Disease`
WHERE `ICDCode` IS NULL OR TRIM(`ICDCode`) = ''
UNION ALL
SELECT 'sex_specific_cancer_mismatch', COUNT(*)
FROM `CancerCase` c
JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE (LOWER(c.`CancerType`) IN ('ovarian', 'cervical') AND LOWER(p.`Gender`) <> 'female')
   OR (LOWER(c.`CancerType`) = 'prostate' AND LOWER(p.`Gender`) <> 'male')
UNION ALL
SELECT 'recognizable_facility_region_mismatch', COUNT(*)
FROM (
    SELECT `RegionID`, CASE
        WHEN LOWER(`FacilityName`) REGEXP 'barisal|barishal|barguna|bhola|jhalokathi|patuakhali|pirojpur|sher-e-bangla' THEN @barishal_region
        WHEN LOWER(`FacilityName`) REGEXP 'rajshahi|natore|bogra|bogura|chapainawabganj|joypurhat|naogaon|pabna|sirajganj|bonpara|monsur ali' THEN @rajshahi_region
        WHEN LOWER(`FacilityName`) REGEXP 'khulna|bagerhat|jashore|kushtia|magura|meherpur|narail|satkhira|chuadanga|jhenaidah' THEN @khulna_region
        WHEN LOWER(`FacilityName`) REGEXP 'chittagong|chattogram|bandarban|brahmanbaria|chandpur|cumilla|khagrachhari|lakshmipur|noakhali|feni|maijdee|begumganj|hathazari|cox.s bazar|rangamati' THEN @chattogram_region
        WHEN LOWER(`FacilityName`) REGEXP 'mymensingh|jamalpur|netrakona|kishoreganj|sherpur|syed nazrul' THEN @mymensingh_region
        WHEN LOWER(`FacilityName`) REGEXP 'rangpur|dinajpur|gaibandha|kurigram|lalmonirhat|saidpur|nilphamari|panchagarh|thakurgaon|abdur rahim' THEN @rangpur_region
        WHEN LOWER(`FacilityName`) REGEXP 'sylhet|habiganj|maulvibazar|sunamganj' THEN @sylhet_region
        WHEN LOWER(`FacilityName`) REGEXP 'dhaka|faridpur|gazipur|gopalganj|madaripur|manikganj|narsingdi|narayanganj|munshiganj|rajbari|shariatpur|tangail|savar|tongi|uttara|colonel malek|salimullah|suhrawardy|taj uddin|institute of public health' THEN @dhaka_region
        ELSE NULL
    END AS expected_region
    FROM `HealthFacility`
) AS facility_location
WHERE expected_region IS NOT NULL AND `RegionID` <> expected_region
UNION ALL
SELECT 'implausible_adult_malnutrition_measurement', COUNT(*)
FROM `Malnutrition`
WHERE `Height` < 140 OR `Height` > 210 OR `BMI` < 10 OR `BMI` >= 18.5
UNION ALL
SELECT 'malnutrition_bmi_classification_mismatch', COUNT(*)
FROM `Malnutrition`
WHERE (`BMI` < 16.00 AND `MalnutritionType` <> 'Severe Thinness')
   OR (`BMI` >= 16.00 AND `BMI` < 17.00 AND `MalnutritionType` <> 'Moderate Thinness')
   OR (`BMI` >= 17.00 AND `BMI` < 18.50 AND `MalnutritionType` <> 'Mild Thinness')
UNION ALL
SELECT 'source_2023_facility_count_mismatch', ABS(CAST(COUNT(*) AS SIGNED) - 84)
FROM `HealthFacility`
WHERE `FacilityType` IN (
    'Government Medical College Hospital',
    'Government District/General Hospital',
    'Public Health Institute'
)
UNION ALL
SELECT 'source_2023_iph_laboratory_count_mismatch', ABS(CAST(COUNT(*) AS SIGNED) - 8)
FROM `Laboratory` laboratory_row
JOIN `HealthFacility` facility_row ON facility_row.`FacilityID` = laboratory_row.`FacilityID`
WHERE LOWER(TRIM(facility_row.`FacilityName`)) =
      LOWER('Institute of Public Health (IPH), Mohakhali, Dhaka')
UNION ALL
SELECT 'source_2023_designation_count_mismatch', ABS(CAST(COUNT(*) AS SIGNED) - 12)
FROM `Designation`
WHERE `DesignationName` IN (
    'Alternative Physician (Homeopathy, Unani and Ayurvedic)',
    'Field Worker',
    'Health Inspector',
    'Medical Technologist (Dental)',
    'Medical Technologist (EPI)',
    'Medical Technologist (Laboratory)',
    'Medical Technologist (Physiotherapy)',
    'Medical Technologist (Radiography)',
    'Medical Technologist (Radiotherapy)',
    'Medical Technologist (Sanitary Inspection)',
    'Medical Technologist (Other Discipline)',
    'Medical Technologist (Unspecified Discipline)'
)
UNION ALL
SELECT 'normalized_duplicate_facility_names', COUNT(*)
FROM (
    SELECT LOWER(TRIM(`FacilityName`))
    FROM `HealthFacility`
    GROUP BY LOWER(TRIM(`FacilityName`))
    HAVING COUNT(*) > 1
) duplicate_rows
UNION ALL
SELECT 'normalized_duplicate_laboratory_names', COUNT(*)
FROM (
    SELECT LOWER(TRIM(`LabName`))
    FROM `Laboratory`
    GROUP BY LOWER(TRIM(`LabName`))
    HAVING COUNT(*) > 1
) duplicate_rows
UNION ALL
SELECT 'normalized_duplicate_designation_names', COUNT(*)
FROM (
    SELECT LOWER(TRIM(`DesignationName`))
    FROM `Designation`
    GROUP BY LOWER(TRIM(`DesignationName`))
    HAVING COUNT(*) > 1
) duplicate_rows;

-- Scan every column in all 21 tables. The total counts SQL NULL values and
-- empty/whitespace-only text values. Expected: zero.
SET SESSION group_concat_max_len = 1000000;

SELECT GROUP_CONCAT(
    CONCAT(
        'SELECT COUNT(*) AS issue_count FROM `', `TABLE_NAME`,
        '` WHERE `', `COLUMN_NAME`, '` IS NULL',
        CASE
            WHEN `DATA_TYPE` IN ('char', 'varchar', 'tinytext', 'text', 'mediumtext', 'longtext')
            THEN CONCAT(' OR TRIM(`', `COLUMN_NAME`, '`) = ''''')
            ELSE ''
        END
    )
    ORDER BY `TABLE_NAME`, `ORDINAL_POSITION`
    SEPARATOR ' UNION ALL '
) INTO @all_column_checks
FROM information_schema.COLUMNS
WHERE `TABLE_SCHEMA` = DATABASE();

SET @all_blank_sql := CONCAT(
    'SELECT ''all_null_or_blank_values'' AS quality_check, ',
    'SUM(issue_count) AS issue_count FROM (',
    @all_column_checks,
    ') AS all_column_results'
);

PREPARE all_blank_statement FROM @all_blank_sql;
EXECUTE all_blank_statement;
DEALLOCATE PREPARE all_blank_statement;

-- Demonstration joins.
SELECT w.`WorkID`, w.`WorkerName`, d.`DesignationName`, f.`FacilityName`
FROM `HealthWorker` w
JOIN `Designation` d ON d.`DesignationID` = w.`DesignationID`
JOIN `HealthFacility` f ON f.`FacilityID` = w.`FacilityID`
ORDER BY w.`WorkID`;

SELECT c.`CancerID`, p.`FullName`, c.`CancerType`, l.`LabName`, b.`ProcedureDate`
FROM `CancerCase` c
JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
JOIN `Laboratory` l ON l.`LabID` = c.`LabID`
LEFT JOIN `Biopsy` b ON b.`CancerCaseID` = c.`CancerID`
ORDER BY c.`CancerID`;

SELECT n.`NewbornID`, n.`BirthDate`, m.`MotherID`, p.`FullName` AS mother_name
FROM `Newborn` n
JOIN `MaternalHealth` m ON m.`MotherID` = n.`MotherID`
JOIN `Patient` p ON p.`PatientID` = m.`PatientID`
ORDER BY n.`NewbornID`;

-- Source-backed expansion demonstrations.
SELECT region_row.`RegionName`, facility_row.`FacilityType`, COUNT(*) AS facility_count
FROM `HealthFacility` facility_row
JOIN `AdministrativeRegion` region_row
  ON region_row.`RegionID` = facility_row.`RegionID`
WHERE facility_row.`FacilityType` IN (
    'Government Medical College Hospital',
    'Government District/General Hospital',
    'Public Health Institute'
)
GROUP BY region_row.`RegionName`, facility_row.`FacilityType`
ORDER BY region_row.`RegionName`, facility_row.`FacilityType`;

SELECT facility_row.`FacilityName`, laboratory_row.`LabName`
FROM `Laboratory` laboratory_row
JOIN `HealthFacility` facility_row
  ON facility_row.`FacilityID` = laboratory_row.`FacilityID`
WHERE LOWER(TRIM(facility_row.`FacilityName`)) =
      LOWER('Institute of Public Health (IPH), Mohakhali, Dhaka')
ORDER BY laboratory_row.`LabName`;

SELECT `DesignationID`, `DesignationName`
FROM `Designation`
WHERE `DesignationName` IN (
    'Alternative Physician (Homeopathy, Unani and Ayurvedic)',
    'Field Worker',
    'Health Inspector',
    'Medical Technologist (Dental)',
    'Medical Technologist (EPI)',
    'Medical Technologist (Laboratory)',
    'Medical Technologist (Physiotherapy)',
    'Medical Technologist (Radiography)',
    'Medical Technologist (Radiotherapy)',
    'Medical Technologist (Sanitary Inspection)',
    'Medical Technologist (Other Discipline)',
    'Medical Technologist (Unspecified Discipline)'
)
ORDER BY `DesignationName`;
