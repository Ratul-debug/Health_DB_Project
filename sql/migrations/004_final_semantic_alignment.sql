-- Health DB Project
-- Final idempotent database-readiness migration for the demonstration data.
-- Keeps the same 21 entities, 21 primary keys, and 25 foreign keys.
-- Target: MySQL 8.0+

USE `health_db`;

-- ---------------------------------------------------------------------------
-- 1. Complete and align the existing demonstration rows.
-- ---------------------------------------------------------------------------

START TRANSACTION;

UPDATE `Disease`
SET `ICDCode` = CASE LOWER(`DiseaseName`)
    WHEN 'cancer' THEN 'C80.9'
    WHEN 'diabetes' THEN 'E14.9'
    WHEN 'dengue' THEN 'A90'
    WHEN 'covid-19' THEN 'U07.1'
    WHEN 'measles' THEN 'B05.9'
    WHEN 'hiv' THEN 'B20'
    WHEN 'diarrhea' THEN 'A09'
    WHEN 'cholera (diarrheal infection)' THEN 'A00.9'
    WHEN 'tuberculosis (pulmonary tb)' THEN 'A15.0'
    ELSE `ICDCode`
END;

-- Ovarian/cervical cases must link to Female patients; prostate cases to Male.
UPDATE `CancerCase`
SET `PatientID` = 9
WHERE `CancerID` = 8 AND LOWER(`CancerType`) = 'ovarian';

UPDATE `CancerCase`
SET `PatientID` = 8
WHERE `CancerID` = 9 AND LOWER(`CancerType`) = 'prostate';

-- Resolve recognizable facility locations to their Bangladesh division.
SET @dhaka_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'dhaka' LIMIT 1);
SET @chattogram_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'chattogram' LIMIT 1);
SET @rajshahi_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'rajshahi' LIMIT 1);
SET @khulna_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'khulna' LIMIT 1);
SET @barishal_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'barishal' LIMIT 1);
SET @sylhet_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'sylhet' LIMIT 1);
SET @rangpur_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'rangpur' LIMIT 1);
SET @mymensingh_region := (SELECT `RegionID` FROM `AdministrativeRegion` WHERE LOWER(`RegionName`) = 'mymensingh' LIMIT 1);

UPDATE `HealthFacility`
SET `RegionID` = CASE
    -- Put the explicit Barisal/Barishal location first so a road name such as
    -- "Bogra Road, Barisal" is not misclassified as Rajshahi division.
    WHEN LOWER(`FacilityName`) REGEXP 'barisal|barishal|barguna|pirojpur'
        THEN @barishal_region
    WHEN LOWER(`FacilityName`) REGEXP 'rajshahi|natore|bogra|joypurhat|sirajganj|bonpara'
        THEN @rajshahi_region
    WHEN LOWER(`FacilityName`) REGEXP 'khulna|magura|satkhira|chuadanga|jhenaidah'
        THEN @khulna_region
    WHEN LOWER(`FacilityName`) REGEXP 'chittagong|chattogram|noakhali|feni|maijdee|begumganj|hathazari|cox.s bazar'
        THEN @chattogram_region
    WHEN LOWER(`FacilityName`) REGEXP 'mymensingh|netrakona|kishoreganj'
        THEN @mymensingh_region
    WHEN LOWER(`FacilityName`) REGEXP 'rangpur|saidpur|nilphamari'
        THEN @rangpur_region
    WHEN LOWER(`FacilityName`) REGEXP 'sylhet'
        THEN @sylhet_region
    WHEN LOWER(`FacilityName`) REGEXP 'dhaka|gazipur|narsingdi|narayanganj|munshiganj|savar|tongi|uttara'
        THEN @dhaka_region
    ELSE `RegionID`
END;

-- The linked patients are adults; use plausible adult height/BMI values and
-- keep the malnutrition label consistent with adult BMI cut-offs.
UPDATE `Malnutrition`
SET `Height` = 150.00 + MOD(`MalnutritionID` * 7, 31),
    `BMI` = ROUND(15.20 + MOD(`MalnutritionID` * 7, 32) / 10.0, 2);

UPDATE `Malnutrition`
SET `MalnutritionType` = CASE
    WHEN `BMI` < 16.00 THEN 'Severe Thinness'
    WHEN `BMI` < 17.00 THEN 'Moderate Thinness'
    ELSE 'Mild Thinness'
END;

COMMIT;

-- ---------------------------------------------------------------------------
-- 2. Prevent future NULL values. All existing rows are populated before these
--    idempotent definitions are applied. MySQL ALTER TABLE performs implicit
--    commits, so the data transaction above is deliberately completed first.
-- ---------------------------------------------------------------------------

ALTER TABLE `AdministrativeRegion`
    MODIFY `Population` bigint NOT NULL,
    MODIFY `RegionType` varchar(50) NOT NULL;

ALTER TABLE `Biopsy`
    MODIFY `ProcedureDate` date NOT NULL;

ALTER TABLE `CancerCase`
    MODIFY `CancerType` varchar(255) NOT NULL,
    MODIFY `TestResult` varchar(255) NOT NULL,
    MODIFY `CancerStage` varchar(100) NOT NULL;

ALTER TABLE `Covid19`
    MODIFY `TestResult` varchar(255) NOT NULL,
    MODIFY `Temperature` decimal(5,2) NOT NULL;

ALTER TABLE `Dengue`
    MODIFY `Age` int NOT NULL,
    MODIFY `Gender` varchar(30) NOT NULL,
    MODIFY `DengueType` varchar(100) NOT NULL;

ALTER TABLE `Diarrhea`
    MODIFY `Symptoms` text NOT NULL,
    MODIFY `TestResult` varchar(255) NOT NULL,
    MODIFY `AdmissionDate` date NOT NULL;

ALTER TABLE `Disease`
    MODIFY `ICDCode` varchar(100) NOT NULL;

ALTER TABLE `HIV`
    MODIFY `DiagnosisDate` date NOT NULL,
    MODIFY `HIVStatus` varchar(100) NOT NULL,
    MODIFY `TestResult` varchar(255) NOT NULL;

ALTER TABLE `HealthFacility`
    MODIFY `FacilityType` varchar(150) NOT NULL,
    MODIFY `RegionID` int NOT NULL;

ALTER TABLE `HealthWorker`
    MODIFY `FacilityID` int NOT NULL,
    MODIFY `Gender` varchar(30) NOT NULL;

ALTER TABLE `HospitalBed`
    MODIFY `BedType` varchar(100) NOT NULL,
    MODIFY `Status` varchar(100) NOT NULL;

ALTER TABLE `Malnutrition`
    MODIFY `Height` decimal(8,2) NOT NULL,
    MODIFY `BMI` decimal(8,2) NOT NULL,
    MODIFY `MalnutritionType` varchar(100) NOT NULL;

ALTER TABLE `MaternalHealth`
    MODIFY `StartDate` date NOT NULL;

ALTER TABLE `Measles`
    MODIFY `Symptoms` text NOT NULL,
    MODIFY `Fever` varchar(50) NOT NULL,
    MODIFY `DiagnosisDate` date NOT NULL;

ALTER TABLE `Newborn`
    MODIFY `BirthDate` date NOT NULL;

ALTER TABLE `Patient`
    MODIFY `FullName` varchar(255) NOT NULL,
    MODIFY `DateOfBirth` date NOT NULL,
    MODIFY `Gender` varchar(30) NOT NULL,
    MODIFY `NationalID` varchar(50) NOT NULL,
    MODIFY `BedID` int NOT NULL;

ALTER TABLE `PopulationGroup`
    MODIFY `RegionID` int NOT NULL,
    MODIFY `Population` bigint NOT NULL;

ALTER TABLE `TelemedicineCenter`
    MODIFY `ConsultationID` varchar(100) NOT NULL,
    MODIFY `PatientID` int NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Post-migration checks. Every issue_count must be zero.
-- ---------------------------------------------------------------------------

SELECT 'nullable_columns' AS quality_check, COUNT(*) AS issue_count
FROM information_schema.COLUMNS
WHERE `TABLE_SCHEMA` = DATABASE() AND `IS_NULLABLE` = 'YES'
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
        WHEN LOWER(`FacilityName`) REGEXP 'barisal|barishal|barguna|pirojpur' THEN @barishal_region
        WHEN LOWER(`FacilityName`) REGEXP 'rajshahi|natore|bogra|joypurhat|sirajganj|bonpara' THEN @rajshahi_region
        WHEN LOWER(`FacilityName`) REGEXP 'khulna|magura|satkhira|chuadanga|jhenaidah' THEN @khulna_region
        WHEN LOWER(`FacilityName`) REGEXP 'chittagong|chattogram|noakhali|feni|maijdee|begumganj|hathazari|cox.s bazar' THEN @chattogram_region
        WHEN LOWER(`FacilityName`) REGEXP 'mymensingh|netrakona|kishoreganj' THEN @mymensingh_region
        WHEN LOWER(`FacilityName`) REGEXP 'rangpur|saidpur|nilphamari' THEN @rangpur_region
        WHEN LOWER(`FacilityName`) REGEXP 'sylhet' THEN @sylhet_region
        WHEN LOWER(`FacilityName`) REGEXP 'dhaka|gazipur|narsingdi|narayanganj|munshiganj|savar|tongi|uttara' THEN @dhaka_region
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
   OR (`BMI` >= 17.00 AND `BMI` < 18.50 AND `MalnutritionType` <> 'Mild Thinness');

-- Scan every column in all 21 tables for SQL NULL and blank text values.
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
