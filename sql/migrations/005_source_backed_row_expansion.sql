-- Health DB Project
-- Source-backed row expansion from Health Bulletin 2023.
-- Keeps the same 21 entities, 89 columns, 21 primary keys, and 25 foreign keys.
-- Permanent additions: 80 facilities, 8 laboratories, and 12 designations.
-- Target: MySQL 8.0+

USE `health_db`;

START TRANSACTION;

SET @facilities_before := (SELECT COUNT(*) FROM `HealthFacility`);
SET @laboratories_before := (SELECT COUNT(*) FROM `Laboratory`);
SET @designations_before := (SELECT COUNT(*) FROM `Designation`);

-- Temporary staging tables are used only while this migration runs. They do
-- not alter the permanent schema or the submitted 21-entity ERD.
DROP TEMPORARY TABLE IF EXISTS `tmp_source_facility_2023`;
CREATE TEMPORARY TABLE `tmp_source_facility_2023` (
    `FacilityName` varchar(255) NOT NULL,
    `FacilityType` varchar(150) NOT NULL,
    `RegionName` varchar(150) NOT NULL,
    PRIMARY KEY (`FacilityName`)
) ENGINE=InnoDB;

-- Health Bulletin 2023, Tables 5.4 and 5.5. Line-break and OCR artefacts in
-- the extracted CSV have been normalized without changing facility identity.
INSERT INTO `tmp_source_facility_2023`
    (`FacilityName`, `FacilityType`, `RegionName`)
VALUES
    ('Bangabandhu Sheikh Mujib Medical College Hospital, Faridpur', 'Government Medical College Hospital', 'Dhaka'),
    ('Chattogram Medical College Hospital', 'Government Medical College Hospital', 'Chattogram'),
    ('Colonel Malek Medical College Hospital', 'Government Medical College Hospital', 'Dhaka'),
    ('Cumilla Medical College Hospital', 'Government Medical College Hospital', 'Chattogram'),
    ('Dhaka Medical College Hospital', 'Government Medical College Hospital', 'Dhaka'),
    ('Khulna Medical College Hospital', 'Government Medical College Hospital', 'Khulna'),
    ('M. Abdur Rahim Medical College Hospital', 'Government Medical College Hospital', 'Rangpur'),
    ('Mugda Medical College Hospital, Dhaka', 'Government Medical College Hospital', 'Dhaka'),
    ('Mymensingh Medical College Hospital', 'Government Medical College Hospital', 'Mymensingh'),
    ('Rajshahi Medical College Hospital', 'Government Medical College Hospital', 'Rajshahi'),
    ('Rangpur Medical College Hospital', 'Government Medical College Hospital', 'Rangpur'),
    ('Satkhira Medical College Hospital', 'Government Medical College Hospital', 'Khulna'),
    ('Shaheed M. Monsur Ali Medical College Hospital', 'Government Medical College Hospital', 'Rajshahi'),
    ('Shaheed Suhrawardy Medical College Hospital', 'Government Medical College Hospital', 'Dhaka'),
    ('Shaheed Taj Uddin Ahmad Medical College Hospital', 'Government Medical College Hospital', 'Dhaka'),
    ('Shaheed Ziaur Rahman Medical College Hospital, Bogura', 'Government Medical College Hospital', 'Rajshahi'),
    ('Shahid Syed Nazrul Islam Medical College Hospital', 'Government Medical College Hospital', 'Mymensingh'),
    ('Sheikh Hasina Medical College Hospital, Tangail', 'Government Medical College Hospital', 'Dhaka'),
    ('Sher-e-Bangla Medical College Hospital', 'Government Medical College Hospital', 'Barishal'),
    ('Sir Salimullah Medical College Hospital', 'Government Medical College Hospital', 'Dhaka'),
    ('Sylhet MAG Osmani Medical College Hospital', 'Government Medical College Hospital', 'Sylhet'),
    ('Bagerhat District Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Bandarban 250-bed District Hospital, Bandarban', 'Government District/General Hospital', 'Chattogram'),
    ('Barguna District Hospital', 'Government District/General Hospital', 'Barishal'),
    ('Barishal General Hospital', 'Government District/General Hospital', 'Barishal'),
    ('Bhola 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Barishal'),
    ('Bogura 250-bed Mohammad Ali District Hospital', 'Government District/General Hospital', 'Rajshahi'),
    ('Brahmanbaria 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Chandpur 250-bed General Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Chapainawabganj 250-bed District Hospital', 'Government District/General Hospital', 'Rajshahi'),
    ('Chittagong 250-bed General Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Chuadanga District Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Cox''s Bazar 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Cumilla General Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Dinajpur 250-bed General Hospital', 'Government District/General Hospital', 'Rangpur'),
    ('Faridpur General Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Feni 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Gaibandha 250-bed District Hospital', 'Government District/General Hospital', 'Rangpur'),
    ('Gopalganj 250-bed General Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Habiganj 250-bed District Hospital', 'Government District/General Hospital', 'Sylhet'),
    ('Jamalpur 250-bed General Hospital', 'Government District/General Hospital', 'Mymensingh'),
    ('Jashore 250-bed General Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Jhalokathi District Hospital', 'Government District/General Hospital', 'Barishal'),
    ('Jhenaidah 250-bed General Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Joypurhat 250-bed District Hospital', 'Government District/General Hospital', 'Rajshahi'),
    ('Khagrachhari District Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Khulna 250-bed General Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Kishoreganj 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Mymensingh'),
    ('Kurigram 250-bed District Hospital', 'Government District/General Hospital', 'Rangpur'),
    ('Kushtia 250-bed General Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Lakshmipur District Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Lalmonirhat District Hospital', 'Government District/General Hospital', 'Rangpur'),
    ('Madaripur District Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Magura 250-bed District Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Manikganj 250-bed District Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Maulvibazar 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Sylhet'),
    ('Meherpur 250-bed District Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Munshiganj 250-bed District Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Naogaon 250-bed District Hospital', 'Government District/General Hospital', 'Rajshahi'),
    ('Narail District Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Narayanganj 300-bed Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Narayanganj General (Victoria) Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Narsingdi 100-bed Zila Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Narsingdi District Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Natore District Hospital', 'Government District/General Hospital', 'Rajshahi'),
    ('Netrakona District Hospital', 'Government District/General Hospital', 'Mymensingh'),
    ('Nilphamari 250-bed District Hospital', 'Government District/General Hospital', 'Rangpur'),
    ('Noakhali 250-bed General Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Pabna 250-bed General Hospital', 'Government District/General Hospital', 'Rajshahi'),
    ('Panchagarh District Hospital', 'Government District/General Hospital', 'Rangpur'),
    ('Patuakhali 250-bed Sadar Hospital', 'Government District/General Hospital', 'Barishal'),
    ('Pirojpur District Hospital', 'Government District/General Hospital', 'Barishal'),
    ('Rajbari District Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Rangamati General Hospital', 'Government District/General Hospital', 'Chattogram'),
    ('Satkhira District Hospital', 'Government District/General Hospital', 'Khulna'),
    ('Shaheed Ahsan Ullah Master General Hospital, Tongi, Gazipur', 'Government District/General Hospital', 'Dhaka'),
    ('Shariatpur District Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Sherpur 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Mymensingh'),
    ('Sirajganj 250-bed Bangamata Sheikh Fazilatunnesa Mujib General Hospital', 'Government District/General Hospital', 'Rajshahi'),
    ('Sunamganj 250-bed District Sadar Hospital', 'Government District/General Hospital', 'Sylhet'),
    ('Sylhet Shahid Shamsuddin Ahmed District Hospital', 'Government District/General Hospital', 'Sylhet'),
    ('Tangail 250-bed District Hospital', 'Government District/General Hospital', 'Dhaka'),
    ('Thakurgaon District Hospital', 'Government District/General Hospital', 'Rangpur'),
    -- Health Bulletin 2023, Table 4.7.3.
    ('Institute of Public Health (IPH), Mohakhali, Dhaka', 'Public Health Institute', 'Dhaka');

-- Normalize two existing aliases so the source facility is not duplicated.
UPDATE `HealthFacility` old_facility
LEFT JOIN `HealthFacility` canonical_facility
  ON LOWER(TRIM(canonical_facility.`FacilityName`)) = LOWER('Mugda Medical College Hospital, Dhaka')
SET old_facility.`FacilityName` = 'Mugda Medical College Hospital, Dhaka'
WHERE LOWER(TRIM(old_facility.`FacilityName`)) = LOWER('Mugda 500-bed General Hospital, Dhaka')
  AND canonical_facility.`FacilityID` IS NULL;

UPDATE `HealthFacility` old_facility
LEFT JOIN `HealthFacility` canonical_facility
  ON LOWER(TRIM(canonical_facility.`FacilityName`)) = LOWER('Narsingdi 100-bed Zila Hospital')
SET old_facility.`FacilityName` = 'Narsingdi 100-bed Zila Hospital'
WHERE LOWER(TRIM(old_facility.`FacilityName`)) = LOWER('Narsingdi 100-bed Hospital')
  AND canonical_facility.`FacilityID` IS NULL;

-- Insert only genuinely missing facilities, then align all source rows to the
-- documented type and division. This makes repeated execution safe.
INSERT INTO `HealthFacility` (`FacilityType`, `FacilityName`, `RegionID`)
SELECT source_row.`FacilityType`, source_row.`FacilityName`, region_row.`RegionID`
FROM `tmp_source_facility_2023` source_row
JOIN `AdministrativeRegion` region_row
  ON LOWER(TRIM(region_row.`RegionName`)) = LOWER(source_row.`RegionName`)
LEFT JOIN `HealthFacility` existing_row
  ON LOWER(TRIM(existing_row.`FacilityName`)) = LOWER(source_row.`FacilityName`)
WHERE existing_row.`FacilityID` IS NULL;

UPDATE `HealthFacility` facility_row
JOIN `tmp_source_facility_2023` source_row
  ON LOWER(TRIM(facility_row.`FacilityName`)) = LOWER(source_row.`FacilityName`)
JOIN `AdministrativeRegion` region_row
  ON LOWER(TRIM(region_row.`RegionName`)) = LOWER(source_row.`RegionName`)
SET facility_row.`FacilityType` = source_row.`FacilityType`,
    facility_row.`RegionID` = region_row.`RegionID`;

DROP TEMPORARY TABLE IF EXISTS `tmp_source_laboratory_2023`;
CREATE TEMPORARY TABLE `tmp_source_laboratory_2023` (
    `LabName` varchar(255) NOT NULL,
    PRIMARY KEY (`LabName`)
) ENGINE=InnoDB;

-- Health Bulletin 2023, Table 4.7.3.
INSERT INTO `tmp_source_laboratory_2023` (`LabName`)
VALUES
    ('Microbiology Laboratories (MBL)'),
    ('BSL2++ Virology Laboratories'),
    ('BSL2++ Bacteriology Laboratories'),
    ('Clinical Chemistry Laboratories'),
    ('Clinical Pathology and Immunology Laboratories'),
    ('Public Health Laboratory (PHL)'),
    ('National Food Safety Laboratory (NFSL)'),
    ('Quality Control Laboratory');

SET @iph_facility_id := (
    SELECT `FacilityID`
    FROM `HealthFacility`
    WHERE LOWER(TRIM(`FacilityName`)) = LOWER('Institute of Public Health (IPH), Mohakhali, Dhaka')
    LIMIT 1
);

INSERT INTO `Laboratory` (`LabName`, `FacilityID`)
SELECT source_row.`LabName`, @iph_facility_id
FROM `tmp_source_laboratory_2023` source_row
LEFT JOIN `Laboratory` existing_row
  ON LOWER(TRIM(existing_row.`LabName`)) = LOWER(source_row.`LabName`)
WHERE existing_row.`LabID` IS NULL;

UPDATE `Laboratory` laboratory_row
JOIN `tmp_source_laboratory_2023` source_row
  ON LOWER(TRIM(laboratory_row.`LabName`)) = LOWER(source_row.`LabName`)
SET laboratory_row.`FacilityID` = @iph_facility_id;

DROP TEMPORARY TABLE IF EXISTS `tmp_source_designation_2023`;
CREATE TEMPORARY TABLE `tmp_source_designation_2023` (
    `DesignationName` varchar(255) NOT NULL,
    PRIMARY KEY (`DesignationName`)
) ENGINE=InnoDB;

-- Health Bulletin 2023, Table 7. Generic Medical Technologist already exists;
-- the source's explicit disciplines are retained as distinct designations.
INSERT INTO `tmp_source_designation_2023` (`DesignationName`)
VALUES
    ('Alternative Physician (Homeopathy, Unani and Ayurvedic)'),
    ('Field Worker'),
    ('Health Inspector'),
    ('Medical Technologist (Dental)'),
    ('Medical Technologist (EPI)'),
    ('Medical Technologist (Laboratory)'),
    ('Medical Technologist (Physiotherapy)'),
    ('Medical Technologist (Radiography)'),
    ('Medical Technologist (Radiotherapy)'),
    ('Medical Technologist (Sanitary Inspection)'),
    ('Medical Technologist (Other Discipline)'),
    ('Medical Technologist (Unspecified Discipline)');

INSERT INTO `Designation` (`DesignationName`)
SELECT source_row.`DesignationName`
FROM `tmp_source_designation_2023` source_row
LEFT JOIN `Designation` existing_row
  ON LOWER(TRIM(existing_row.`DesignationName`)) = LOWER(source_row.`DesignationName`)
WHERE existing_row.`DesignationID` IS NULL;

COMMIT;

-- ---------------------------------------------------------------------------
-- Post-migration evidence and checks.
-- First result records the additions; every issue_count below must be zero.
-- On the first run: 80 facilities, 8 laboratories, 12 designations.
-- On a repeated run: all added_count values are zero.
-- ---------------------------------------------------------------------------

SELECT 'HealthFacility' AS table_name,
       COUNT(*) AS final_row_count,
       COUNT(*) - @facilities_before AS added_count
FROM `HealthFacility`
UNION ALL
SELECT 'Laboratory', COUNT(*), COUNT(*) - @laboratories_before FROM `Laboratory`
UNION ALL
SELECT 'Designation', COUNT(*), COUNT(*) - @designations_before FROM `Designation`;

SELECT 'source_2023_facilities_missing' AS quality_check, COUNT(*) AS issue_count
FROM `tmp_source_facility_2023` source_row
LEFT JOIN `HealthFacility` facility_row
  ON LOWER(TRIM(facility_row.`FacilityName`)) = LOWER(source_row.`FacilityName`)
WHERE facility_row.`FacilityID` IS NULL;

SELECT 'source_2023_facility_region_mismatch' AS quality_check,
       COUNT(*) AS issue_count
FROM `tmp_source_facility_2023` source_row
JOIN `HealthFacility` facility_row
  ON LOWER(TRIM(facility_row.`FacilityName`)) = LOWER(source_row.`FacilityName`)
JOIN `AdministrativeRegion` region_row ON region_row.`RegionID` = facility_row.`RegionID`
WHERE LOWER(TRIM(region_row.`RegionName`)) <> LOWER(source_row.`RegionName`);

SELECT 'source_2023_laboratories_missing' AS quality_check,
       COUNT(*) AS issue_count
FROM `tmp_source_laboratory_2023` source_row
LEFT JOIN `Laboratory` laboratory_row
  ON LOWER(TRIM(laboratory_row.`LabName`)) = LOWER(source_row.`LabName`)
WHERE laboratory_row.`LabID` IS NULL;

SELECT 'source_2023_laboratory_facility_mismatch' AS quality_check,
       COUNT(*) AS issue_count
FROM `tmp_source_laboratory_2023` source_row
JOIN `Laboratory` laboratory_row
  ON LOWER(TRIM(laboratory_row.`LabName`)) = LOWER(source_row.`LabName`)
WHERE laboratory_row.`FacilityID` <> @iph_facility_id;

SELECT 'source_2023_designations_missing' AS quality_check,
       COUNT(*) AS issue_count
FROM `tmp_source_designation_2023` source_row
LEFT JOIN `Designation` designation_row
  ON LOWER(TRIM(designation_row.`DesignationName`)) = LOWER(source_row.`DesignationName`)
WHERE designation_row.`DesignationID` IS NULL;

SELECT 'normalized_duplicate_facility_names' AS quality_check,
       COUNT(*) AS issue_count
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
) duplicate_rows
UNION ALL
SELECT 'nullable_columns', COUNT(*)
FROM information_schema.COLUMNS
WHERE `TABLE_SCHEMA` = DATABASE() AND `IS_NULLABLE` = 'YES';

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

DROP TEMPORARY TABLE IF EXISTS `tmp_source_designation_2023`;
DROP TEMPORARY TABLE IF EXISTS `tmp_source_laboratory_2023`;
DROP TEMPORARY TABLE IF EXISTS `tmp_source_facility_2023`;
