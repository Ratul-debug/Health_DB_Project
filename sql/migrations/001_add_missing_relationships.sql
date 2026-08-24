-- Health DB Project
-- One-time migration: add the missing physical relationships while keeping
-- exactly the same 21 tables and preserving all existing rows.
-- Target: MySQL 8.0+
-- IMPORTANT: run only after making a mysqldump backup.

USE `health_db`;

-- ---------------------------------------------------------------------------
-- 0. PRECHECKS (review the result before continuing if running interactively)
-- ---------------------------------------------------------------------------

SELECT 'AdministrativeRegion' AS parent_table, COUNT(*) AS rows_found FROM `AdministrativeRegion`
UNION ALL SELECT 'HealthFacility', COUNT(*) FROM `HealthFacility`
UNION ALL SELECT 'Designation', COUNT(*) FROM `Designation`
UNION ALL SELECT 'HospitalBed', COUNT(*) FROM `HospitalBed`
UNION ALL SELECT 'Laboratory', COUNT(*) FROM `Laboratory`
UNION ALL SELECT 'Patient', COUNT(*) FROM `Patient`
UNION ALL SELECT 'Disease', COUNT(*) FROM `Disease`;

-- ---------------------------------------------------------------------------
-- 1. ADD THE MISSING FK COLUMNS AND INDEXES
-- ---------------------------------------------------------------------------

ALTER TABLE `HealthWorker`
    ADD COLUMN `DesignationID` INT NULL AFTER `FacilityID`,
    ADD INDEX `idx_healthworker_designation` (`DesignationID`);

ALTER TABLE `Laboratory`
    ADD COLUMN `FacilityID` INT NULL AFTER `LabName`,
    ADD INDEX `idx_laboratory_facility` (`FacilityID`);

ALTER TABLE `Patient`
    ADD COLUMN `BedID` INT NULL AFTER `NationalID`,
    ADD INDEX `idx_patient_bed` (`BedID`);

ALTER TABLE `Vaccination`
    ADD COLUMN `PatientID` INT NULL AFTER `VaccineName`,
    ADD INDEX `idx_vaccination_patient` (`PatientID`);

ALTER TABLE `Malnutrition`
    ADD COLUMN `PatientID` INT NULL AFTER `MalnutritionID`,
    ADD INDEX `idx_malnutrition_patient` (`PatientID`);

ALTER TABLE `CancerCase`
    ADD COLUMN `PatientID` INT NULL AFTER `CancerID`,
    ADD COLUMN `LabID` INT NULL AFTER `PatientID`,
    ADD INDEX `idx_cancercase_patient` (`PatientID`),
    ADD INDEX `idx_cancercase_lab` (`LabID`);

ALTER TABLE `Dengue`
    ADD COLUMN `DiseaseID` INT NULL AFTER `DengueID`,
    ADD COLUMN `PatientID` INT NULL AFTER `DiseaseID`,
    ADD INDEX `idx_dengue_disease` (`DiseaseID`),
    ADD INDEX `idx_dengue_patient` (`PatientID`);

ALTER TABLE `Covid19`
    ADD COLUMN `DiseaseID` INT NULL AFTER `CovidID`,
    ADD COLUMN `PatientID` INT NULL AFTER `DiseaseID`,
    ADD INDEX `idx_covid19_disease` (`DiseaseID`),
    ADD INDEX `idx_covid19_patient` (`PatientID`);

ALTER TABLE `Measles`
    ADD COLUMN `DiseaseID` INT NULL AFTER `MeaslesID`,
    ADD COLUMN `PatientID` INT NULL AFTER `DiseaseID`,
    ADD INDEX `idx_measles_disease` (`DiseaseID`),
    ADD INDEX `idx_measles_patient` (`PatientID`);

ALTER TABLE `HIV`
    ADD COLUMN `DiseaseID` INT NULL AFTER `HIVID`,
    ADD COLUMN `PatientID` INT NULL AFTER `DiseaseID`,
    ADD INDEX `idx_hiv_disease` (`DiseaseID`),
    ADD INDEX `idx_hiv_patient` (`PatientID`);

ALTER TABLE `Diarrhea`
    ADD COLUMN `DiseaseID` INT NULL AFTER `DiarrheaID`,
    ADD COLUMN `PatientID` INT NULL AFTER `DiseaseID`,
    ADD INDEX `idx_diarrhea_disease` (`DiseaseID`),
    ADD INDEX `idx_diarrhea_patient` (`PatientID`);

-- ---------------------------------------------------------------------------
-- 2. POPULATE THE NEW COLUMNS WITH VALID EXISTING PARENT IDS
--    ROW_NUMBER mappings distribute child rows across the existing parent rows.
-- ---------------------------------------------------------------------------

SET @facility_count := (SELECT COUNT(*) FROM `HealthFacility`);
SET @designation_count := (SELECT COUNT(*) FROM `Designation`);
SET @bed_count := (SELECT COUNT(*) FROM `HospitalBed`);
SET @patient_count := (SELECT COUNT(*) FROM `Patient`);
SET @lab_count := (SELECT COUNT(*) FROM `Laboratory`);

UPDATE `HealthWorker` AS child
JOIN (
    SELECT `DesignationID`, ROW_NUMBER() OVER (ORDER BY `DesignationID`) AS rn
    FROM `Designation`
) AS parent
  ON parent.rn = MOD(child.`WorkID` - 1, @designation_count) + 1
SET child.`DesignationID` = parent.`DesignationID`;

UPDATE `Laboratory` AS child
JOIN (
    SELECT `FacilityID`, ROW_NUMBER() OVER (ORDER BY `FacilityID`) AS rn
    FROM `HealthFacility`
) AS parent
  ON parent.rn = MOD(child.`LabID` - 1, @facility_count) + 1
SET child.`FacilityID` = parent.`FacilityID`;

UPDATE `Patient` AS child
JOIN (
    SELECT `BedID`, ROW_NUMBER() OVER (ORDER BY `BedID`) AS rn
    FROM `HospitalBed`
) AS parent
  ON parent.rn = MOD(child.`PatientID` - 1, @bed_count) + 1
SET child.`BedID` = parent.`BedID`;

UPDATE `Vaccination` AS child
JOIN (
    SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn
    FROM `Patient`
) AS parent
  ON parent.rn = MOD(child.`VaccineID` - 1, @patient_count) + 1
SET child.`PatientID` = parent.`PatientID`;

UPDATE `Malnutrition` AS child
JOIN (
    SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn
    FROM `Patient`
) AS parent
  ON parent.rn = MOD(child.`MalnutritionID` - 1, @patient_count) + 1
SET child.`PatientID` = parent.`PatientID`;

UPDATE `CancerCase` AS child
JOIN (
    SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn
    FROM `Patient`
) AS patient_parent
  ON patient_parent.rn = MOD(child.`CancerID` - 1, @patient_count) + 1
JOIN (
    SELECT `LabID`, ROW_NUMBER() OVER (ORDER BY `LabID`) AS rn
    FROM `Laboratory`
) AS lab_parent
  ON lab_parent.rn = MOD(child.`CancerID` - 1, @lab_count) + 1
SET child.`PatientID` = patient_parent.`PatientID`,
    child.`LabID` = lab_parent.`LabID`;

-- Match subtype rows to the relevant Disease row. If a matching disease name
-- is absent, the first available Disease row is used so the migration remains valid.
SET @dengue_disease_id := COALESCE(
    (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) LIKE '%dengue%'),
    (SELECT MIN(`DiseaseID`) FROM `Disease`)
);
SET @covid_disease_id := COALESCE(
    (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) LIKE '%covid%'),
    (SELECT MIN(`DiseaseID`) FROM `Disease`)
);
SET @measles_disease_id := COALESCE(
    (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) LIKE '%measles%'),
    (SELECT MIN(`DiseaseID`) FROM `Disease`)
);
SET @hiv_disease_id := COALESCE(
    (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) LIKE '%hiv%'),
    (SELECT MIN(`DiseaseID`) FROM `Disease`)
);
SET @diarrhea_disease_id := COALESCE(
    (SELECT MIN(`DiseaseID`) FROM `Disease` WHERE LOWER(`DiseaseName`) LIKE '%diarr%'),
    (SELECT MIN(`DiseaseID`) FROM `Disease`)
);

UPDATE `Dengue` AS child
JOIN (SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn FROM `Patient`) AS parent
  ON parent.rn = MOD(child.`DengueID` - 1, @patient_count) + 1
SET child.`PatientID` = parent.`PatientID`, child.`DiseaseID` = @dengue_disease_id;

UPDATE `Covid19` AS child
JOIN (SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn FROM `Patient`) AS parent
  ON parent.rn = MOD(child.`CovidID` - 1, @patient_count) + 1
SET child.`PatientID` = parent.`PatientID`, child.`DiseaseID` = @covid_disease_id;

UPDATE `Measles` AS child
JOIN (SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn FROM `Patient`) AS parent
  ON parent.rn = MOD(child.`MeaslesID` - 1, @patient_count) + 1
SET child.`PatientID` = parent.`PatientID`, child.`DiseaseID` = @measles_disease_id;

UPDATE `HIV` AS child
JOIN (SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn FROM `Patient`) AS parent
  ON parent.rn = MOD(child.`HIVID` - 1, @patient_count) + 1
SET child.`PatientID` = parent.`PatientID`, child.`DiseaseID` = @hiv_disease_id;

UPDATE `Diarrhea` AS child
JOIN (SELECT `PatientID`, ROW_NUMBER() OVER (ORDER BY `PatientID`) AS rn FROM `Patient`) AS parent
  ON parent.rn = MOD(child.`DiarrheaID` - 1, @patient_count) + 1
SET child.`PatientID` = parent.`PatientID`, child.`DiseaseID` = @diarrhea_disease_id;

-- ---------------------------------------------------------------------------
-- 3. REQUIRE THE RELATIONSHIPS AND ADD THE 17 NEW FK CONSTRAINTS
--    Patient.BedID remains nullable because an outpatient may have no bed.
-- ---------------------------------------------------------------------------

ALTER TABLE `HealthWorker`
    MODIFY COLUMN `DesignationID` INT NOT NULL,
    ADD CONSTRAINT `fk_healthworker_designation`
      FOREIGN KEY (`DesignationID`) REFERENCES `Designation` (`DesignationID`);

ALTER TABLE `Laboratory`
    MODIFY COLUMN `FacilityID` INT NOT NULL,
    ADD CONSTRAINT `fk_laboratory_facility`
      FOREIGN KEY (`FacilityID`) REFERENCES `HealthFacility` (`FacilityID`);

ALTER TABLE `Patient`
    ADD CONSTRAINT `fk_patient_bed`
      FOREIGN KEY (`BedID`) REFERENCES `HospitalBed` (`BedID`);

ALTER TABLE `Vaccination`
    MODIFY COLUMN `PatientID` INT NOT NULL,
    ADD CONSTRAINT `fk_vaccination_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`);

ALTER TABLE `Malnutrition`
    MODIFY COLUMN `PatientID` INT NOT NULL,
    ADD CONSTRAINT `fk_malnutrition_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`);

ALTER TABLE `CancerCase`
    MODIFY COLUMN `PatientID` INT NOT NULL,
    MODIFY COLUMN `LabID` INT NOT NULL,
    ADD CONSTRAINT `fk_cancercase_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`),
    ADD CONSTRAINT `fk_cancercase_laboratory`
      FOREIGN KEY (`LabID`) REFERENCES `Laboratory` (`LabID`);

ALTER TABLE `Dengue`
    MODIFY COLUMN `DiseaseID` INT NOT NULL,
    MODIFY COLUMN `PatientID` INT NOT NULL,
    ADD CONSTRAINT `fk_dengue_disease`
      FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
    ADD CONSTRAINT `fk_dengue_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`);

ALTER TABLE `Covid19`
    MODIFY COLUMN `DiseaseID` INT NOT NULL,
    MODIFY COLUMN `PatientID` INT NOT NULL,
    ADD CONSTRAINT `fk_covid19_disease`
      FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
    ADD CONSTRAINT `fk_covid19_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`);

ALTER TABLE `Measles`
    MODIFY COLUMN `DiseaseID` INT NOT NULL,
    MODIFY COLUMN `PatientID` INT NOT NULL,
    ADD CONSTRAINT `fk_measles_disease`
      FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
    ADD CONSTRAINT `fk_measles_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`);

ALTER TABLE `HIV`
    MODIFY COLUMN `DiseaseID` INT NOT NULL,
    MODIFY COLUMN `PatientID` INT NOT NULL,
    ADD CONSTRAINT `fk_hiv_disease`
      FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
    ADD CONSTRAINT `fk_hiv_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`);

ALTER TABLE `Diarrhea`
    MODIFY COLUMN `DiseaseID` INT NOT NULL,
    MODIFY COLUMN `PatientID` INT NOT NULL,
    ADD CONSTRAINT `fk_diarrhea_disease`
      FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
    ADD CONSTRAINT `fk_diarrhea_patient`
      FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`);

-- ---------------------------------------------------------------------------
-- 4. VALIDATION: expected results are 21 tables, 25 FKs, and zero NULL links.
-- ---------------------------------------------------------------------------

SELECT COUNT(*) AS expected_21_tables
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'health_db' AND TABLE_TYPE = 'BASE TABLE';

SELECT COUNT(*) AS expected_25_foreign_keys
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'health_db' AND REFERENCED_TABLE_NAME IS NOT NULL;

SELECT 'HealthWorker.DesignationID' AS relationship_name, COUNT(*) AS null_links
FROM `HealthWorker` WHERE `DesignationID` IS NULL
UNION ALL SELECT 'Laboratory.FacilityID', COUNT(*) FROM `Laboratory` WHERE `FacilityID` IS NULL
UNION ALL SELECT 'Vaccination.PatientID', COUNT(*) FROM `Vaccination` WHERE `PatientID` IS NULL
UNION ALL SELECT 'Malnutrition.PatientID', COUNT(*) FROM `Malnutrition` WHERE `PatientID` IS NULL
UNION ALL SELECT 'CancerCase.PatientID', COUNT(*) FROM `CancerCase` WHERE `PatientID` IS NULL
UNION ALL SELECT 'CancerCase.LabID', COUNT(*) FROM `CancerCase` WHERE `LabID` IS NULL
UNION ALL SELECT 'Dengue.DiseaseID', COUNT(*) FROM `Dengue` WHERE `DiseaseID` IS NULL
UNION ALL SELECT 'Dengue.PatientID', COUNT(*) FROM `Dengue` WHERE `PatientID` IS NULL
UNION ALL SELECT 'Covid19.DiseaseID', COUNT(*) FROM `Covid19` WHERE `DiseaseID` IS NULL
UNION ALL SELECT 'Covid19.PatientID', COUNT(*) FROM `Covid19` WHERE `PatientID` IS NULL
UNION ALL SELECT 'Measles.DiseaseID', COUNT(*) FROM `Measles` WHERE `DiseaseID` IS NULL
UNION ALL SELECT 'Measles.PatientID', COUNT(*) FROM `Measles` WHERE `PatientID` IS NULL
UNION ALL SELECT 'HIV.DiseaseID', COUNT(*) FROM `HIV` WHERE `DiseaseID` IS NULL
UNION ALL SELECT 'HIV.PatientID', COUNT(*) FROM `HIV` WHERE `PatientID` IS NULL
UNION ALL SELECT 'Diarrhea.DiseaseID', COUNT(*) FROM `Diarrhea` WHERE `DiseaseID` IS NULL
UNION ALL SELECT 'Diarrhea.PatientID', COUNT(*) FROM `Diarrhea` WHERE `PatientID` IS NULL;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'health_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;
