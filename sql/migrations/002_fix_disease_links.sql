-- Make disease-subtype links semantically valid after the 25-FK migration.
-- Safe to run more than once on MySQL 8.0+.

USE `health_db`;

START TRANSACTION;

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Dengue', NULL
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'dengue');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'COVID-19', NULL
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'covid-19');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Measles', NULL
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'measles');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'HIV', NULL
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'hiv');

INSERT INTO `Disease` (`DiseaseName`, `ICDCode`)
SELECT 'Diarrhea', NULL
WHERE NOT EXISTS (SELECT 1 FROM `Disease` WHERE LOWER(`DiseaseName`) = 'diarrhea');

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

COMMIT;

SELECT 'Dengue' AS subtype, d.`DiseaseName`, COUNT(*) AS linked_rows
FROM `Dengue` s JOIN `Disease` d ON d.`DiseaseID` = s.`DiseaseID`
GROUP BY d.`DiseaseName`
UNION ALL
SELECT 'Covid19', d.`DiseaseName`, COUNT(*)
FROM `Covid19` s JOIN `Disease` d ON d.`DiseaseID` = s.`DiseaseID`
GROUP BY d.`DiseaseName`
UNION ALL
SELECT 'Measles', d.`DiseaseName`, COUNT(*)
FROM `Measles` s JOIN `Disease` d ON d.`DiseaseID` = s.`DiseaseID`
GROUP BY d.`DiseaseName`
UNION ALL
SELECT 'HIV', d.`DiseaseName`, COUNT(*)
FROM `HIV` s JOIN `Disease` d ON d.`DiseaseID` = s.`DiseaseID`
GROUP BY d.`DiseaseName`
UNION ALL
SELECT 'Diarrhea', d.`DiseaseName`, COUNT(*)
FROM `Diarrhea` s JOIN `Disease` d ON d.`DiseaseID` = s.`DiseaseID`
GROUP BY d.`DiseaseName`;
