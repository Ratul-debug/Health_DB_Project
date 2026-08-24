-- Health DB Project
-- Final idempotent cleanup for the mixed-source demonstration dataset.
-- This migration changes data only. It does not change the 21-table schema,
-- primary keys, foreign keys, ERD, or repository paths.
-- Target: MySQL 8.0+

USE `health_db`;

START TRANSACTION;

-- ---------------------------------------------------------------------------
-- 1. Complete missing facility-region links and synchronize region population.
-- ---------------------------------------------------------------------------

SET @region_count := (SELECT COUNT(*) FROM `AdministrativeRegion`);

UPDATE `HealthFacility` AS facility
JOIN (
    SELECT `RegionID`, ROW_NUMBER() OVER (ORDER BY `RegionID`) AS rn
    FROM `AdministrativeRegion`
) AS region_parent
  ON region_parent.rn = MOD(facility.`FacilityID` - 1, @region_count) + 1
SET facility.`RegionID` = region_parent.`RegionID`
WHERE facility.`RegionID` IS NULL;

UPDATE `AdministrativeRegion` AS region_row
LEFT JOIN (
    SELECT `RegionID`, SUM(`Population`) AS total_population
    FROM `PopulationGroup`
    GROUP BY `RegionID`
) AS population_total
  ON population_total.`RegionID` = region_row.`RegionID`
SET region_row.`Population` = population_total.total_population
WHERE population_total.total_population IS NOT NULL;

-- Replace six PDF sentence fragments that were incorrectly loaded as facilities.
UPDATE `HealthFacility`
SET `FacilityName` = CASE `FacilityID`
    WHEN 46 THEN 'Cox''s Bazar Community Clinic'
    WHEN 47 THEN 'Primary Care Clinic'
    WHEN 48 THEN 'Upazila Health Complex'
    WHEN 49 THEN 'IOM Coordination Clinic'
    WHEN 50 THEN 'Community Health Clinic'
    WHEN 51 THEN 'Government Community Clinic'
    ELSE `FacilityName`
END
WHERE `FacilityID` BETWEEN 46 AND 51;

-- ---------------------------------------------------------------------------
-- 2. Keep Designation as a role lookup and align workers with plausible roles.
-- ---------------------------------------------------------------------------

INSERT INTO `Designation` (`DesignationID`, `DesignationName`)
SELECT 19, 'Medical Officer'
WHERE NOT EXISTS (
    SELECT 1 FROM `Designation` WHERE `DesignationID` = 19
);

UPDATE `Designation`
SET `DesignationName` = 'Medical Officer'
WHERE `DesignationID` = 19;

UPDATE `HealthWorker`
SET `DesignationID` = CASE
    WHEN LOWER(`WorkerName`) LIKE '%associate professor%' THEN 8
    WHEN LOWER(`WorkerName`) LIKE '%assistant professor%' THEN 9
    ELSE 19
END;

UPDATE `HealthWorker`
SET `WorkerName` = CASE `WorkID`
    WHEN 1 THEN 'Dr. Prasanta Kumar Chakraborty'
    WHEN 2 THEN 'Dr. Neelufar Rahman'
    WHEN 3 THEN 'Dr. Sadat Khondakar'
    WHEN 4 THEN 'Dr. Md. Ehsanul Alam'
    WHEN 5 THEN 'Dr. Md. Mozaharul Islam'
    ELSE `WorkerName`
END
WHERE `WorkID` BETWEEN 1 AND 5;

-- Rows 20-60 were extracted person-name strings, not designation names.
DELETE FROM `Designation`
WHERE `DesignationID` BETWEEN 20 AND 60;

-- ---------------------------------------------------------------------------
-- 3. Link maternal records only to the synthetic Female patient pool.
-- ---------------------------------------------------------------------------

SET @female_patient_count := (
    SELECT COUNT(*) FROM `Patient` WHERE LOWER(`Gender`) = 'female'
);

UPDATE `MaternalHealth` AS maternal
JOIN (
    SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn
    FROM `Patient`
    WHERE LOWER(`Gender`) = 'female'
) AS patient_parent
  ON patient_parent.rn = MOD(maternal.`MotherID` - 1, @female_patient_count) + 1
SET maternal.`PatientID` = patient_parent.`PatientID`;

-- ---------------------------------------------------------------------------
-- 4. Build a concise Disease lookup and preserve the report's sample ICD codes.
-- ---------------------------------------------------------------------------

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Dengue', 'A90'
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'dengue');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'COVID-19', 'U07.1'
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'covid-19');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Measles', 'B05.9'
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'measles');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'HIV', NULL
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'hiv');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Diarrhea', NULL
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'diarrhea');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Cholera (Diarrheal Infection)', 'A00.9'
WHERE NOT EXISTS (
    SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'cholera (diarrheal infection)'
);

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Tuberculosis (Pulmonary TB)', 'A15.0'
WHERE NOT EXISTS (
    SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'tuberculosis (pulmonary tb)'
);

UPDATE `Disease`
SET `ICDCode` = CASE LOWER(`DiseaseName`)
    WHEN 'dengue' THEN 'A90'
    WHEN 'covid-19' THEN 'U07.1'
    WHEN 'measles' THEN 'B05.9'
    WHEN 'cholera (diarrheal infection)' THEN 'A00.9'
    WHEN 'tuberculosis (pulmonary tb)' THEN 'A15.0'
    ELSE `ICDCode`
END;

SET @dengue_id := (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) = 'dengue');
SET @covid_id := (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) = 'covid-19');
SET @measles_id := (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) = 'measles');
SET @hiv_id := (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) = 'hiv');
SET @diarrhea_id := (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) = 'diarrhea');

UPDATE `Dengue` SET `DiseaseID` = @dengue_id;
UPDATE `Covid19` SET `DiseaseID` = @covid_id;
UPDATE `Measles` SET `DiseaseID` = @measles_id;
UPDATE `HIV` SET `DiseaseID` = @hiv_id;
UPDATE `Diarrhea` SET `DiseaseID` = @diarrhea_id;

-- IDs 1-11 were sentence fragments extracted from narrative PDF text.
DELETE FROM `Disease`
WHERE `DiseaseID` BETWEEN 1 AND 11;

-- ---------------------------------------------------------------------------
-- 5. Remove remaining obvious extraction artifacts and demo inconsistencies.
-- ---------------------------------------------------------------------------

UPDATE `Laboratory`
SET `LabName` = CASE `LabID`
    WHEN 5 THEN 'General Diagnostic Laboratory'
    WHEN 6 THEN 'Imaging and Radiology Laboratory'
    WHEN 7 THEN 'Physiotherapy and Allied Health Laboratory'
    ELSE `LabName`
END
WHERE `LabID` BETWEEN 5 AND 7;

UPDATE `CancerCase`
SET `CancerType` = CASE `CancerID`
        WHEN 8 THEN 'Ovarian'
        WHEN 11 THEN 'Esophagus'
        ELSE `CancerType`
    END,
    `CancerStage` = COALESCE(
        `CancerStage`,
        ELT(MOD(`CancerID` - 1, 4) + 1, 'Stage I', 'Stage II', 'Stage III', 'Stage IV')
    );

UPDATE `Dengue` AS dengue_row
JOIN `Patient` AS patient_row
  ON patient_row.`PatientID` = dengue_row.`PatientID`
SET dengue_row.`Gender` = patient_row.`Gender`,
    dengue_row.`Age` = TIMESTAMPDIFF(YEAR, patient_row.`DateOfBirth`, '2026-01-01');

COMMIT;

-- ---------------------------------------------------------------------------
-- 6. Post-migration checks. Every issue_count should be zero.
-- ---------------------------------------------------------------------------

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
FROM `CancerCase` WHERE `CancerStage` IS NULL;
