-- Health DB Project: final integrity and demonstration queries

USE `health_db`;

-- Expected: 21 tables, 21 primary-key columns, 25 foreign-key columns.
SELECT COUNT(*) AS total_tables
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE';

SELECT COUNT(*) AS total_primary_key_columns
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() AND CONSTRAINT_NAME = 'PRIMARY';

SELECT COUNT(*) AS total_foreign_keys
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL;

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

-- Every result should be zero.
SELECT 'HealthFacility.RegionID' AS relationship_name, COUNT(*) AS orphan_rows
FROM `HealthFacility` c LEFT JOIN `AdministrativeRegion` p ON p.`RegionID` = c.`RegionID`
WHERE c.`RegionID` IS NOT NULL AND p.`RegionID` IS NULL
UNION ALL SELECT 'HealthWorker.FacilityID', COUNT(*)
FROM `HealthWorker` c LEFT JOIN `HealthFacility` p ON p.`FacilityID` = c.`FacilityID`
WHERE c.`FacilityID` IS NOT NULL AND p.`FacilityID` IS NULL
UNION ALL SELECT 'HealthWorker.DesignationID', COUNT(*)
FROM `HealthWorker` c LEFT JOIN `Designation` p ON p.`DesignationID` = c.`DesignationID`
WHERE c.`DesignationID` IS NOT NULL AND p.`DesignationID` IS NULL
UNION ALL SELECT 'HospitalBed.FacilityID', COUNT(*)
FROM `HospitalBed` c LEFT JOIN `HealthFacility` p ON p.`FacilityID` = c.`FacilityID`
WHERE p.`FacilityID` IS NULL
UNION ALL SELECT 'Laboratory.FacilityID', COUNT(*)
FROM `Laboratory` c LEFT JOIN `HealthFacility` p ON p.`FacilityID` = c.`FacilityID`
WHERE p.`FacilityID` IS NULL
UNION ALL SELECT 'Patient.BedID', COUNT(*)
FROM `Patient` c LEFT JOIN `HospitalBed` p ON p.`BedID` = c.`BedID`
WHERE c.`BedID` IS NOT NULL AND p.`BedID` IS NULL
UNION ALL SELECT 'MaternalHealth.PatientID', COUNT(*)
FROM `MaternalHealth` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE p.`PatientID` IS NULL
UNION ALL SELECT 'Newborn.MotherID', COUNT(*)
FROM `Newborn` c LEFT JOIN `MaternalHealth` p ON p.`MotherID` = c.`MotherID`
WHERE p.`MotherID` IS NULL
UNION ALL SELECT 'PopulationGroup.RegionID', COUNT(*)
FROM `PopulationGroup` c LEFT JOIN `AdministrativeRegion` p ON p.`RegionID` = c.`RegionID`
WHERE c.`RegionID` IS NOT NULL AND p.`RegionID` IS NULL
UNION ALL SELECT 'TelemedicineCenter.PatientID', COUNT(*)
FROM `TelemedicineCenter` c LEFT JOIN `Patient` p ON p.`PatientID` = c.`PatientID`
WHERE c.`PatientID` IS NOT NULL AND p.`PatientID` IS NULL
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
