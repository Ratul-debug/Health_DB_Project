-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: health_db
-- ------------------------------------------------------
-- Server version	8.0.46-0ubuntu0.24.04.3

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `health_db`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `health_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `health_db`;

--
-- Table structure for table `AdministrativeRegion`
--

DROP TABLE IF EXISTS `AdministrativeRegion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AdministrativeRegion` (
  `RegionID` int NOT NULL AUTO_INCREMENT,
  `RegionName` varchar(150) NOT NULL,
  `Population` bigint DEFAULT NULL,
  `RegionType` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`RegionID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Biopsy`
--

DROP TABLE IF EXISTS `Biopsy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Biopsy` (
  `BiopsyID` int NOT NULL AUTO_INCREMENT,
  `CancerCaseID` int NOT NULL,
  `ProcedureDate` date DEFAULT NULL,
  PRIMARY KEY (`BiopsyID`),
  KEY `idx_biopsy_cancercase` (`CancerCaseID`),
  CONSTRAINT `fk_biopsy_cancercase` FOREIGN KEY (`CancerCaseID`) REFERENCES `CancerCase` (`CancerID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `CancerCase`
--

DROP TABLE IF EXISTS `CancerCase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CancerCase` (
  `CancerID` int NOT NULL AUTO_INCREMENT,
  `PatientID` int NOT NULL,
  `LabID` int NOT NULL,
  `CancerType` varchar(255) DEFAULT NULL,
  `TestResult` varchar(255) DEFAULT NULL,
  `CancerStage` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`CancerID`),
  KEY `idx_cancercase_patient` (`PatientID`),
  KEY `idx_cancercase_lab` (`LabID`),
  CONSTRAINT `fk_cancercase_laboratory` FOREIGN KEY (`LabID`) REFERENCES `Laboratory` (`LabID`),
  CONSTRAINT `fk_cancercase_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Covid19`
--

DROP TABLE IF EXISTS `Covid19`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Covid19` (
  `CovidID` int NOT NULL AUTO_INCREMENT,
  `DiseaseID` int NOT NULL,
  `PatientID` int NOT NULL,
  `TestResult` varchar(255) DEFAULT NULL,
  `Temperature` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`CovidID`),
  KEY `idx_covid19_disease` (`DiseaseID`),
  KEY `idx_covid19_patient` (`PatientID`),
  CONSTRAINT `fk_covid19_disease` FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
  CONSTRAINT `fk_covid19_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Dengue`
--

DROP TABLE IF EXISTS `Dengue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Dengue` (
  `DengueID` int NOT NULL AUTO_INCREMENT,
  `DiseaseID` int NOT NULL,
  `PatientID` int NOT NULL,
  `Age` int DEFAULT NULL,
  `Gender` varchar(30) DEFAULT NULL,
  `DengueType` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`DengueID`),
  KEY `idx_dengue_disease` (`DiseaseID`),
  KEY `idx_dengue_patient` (`PatientID`),
  CONSTRAINT `fk_dengue_disease` FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
  CONSTRAINT `fk_dengue_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Designation`
--

DROP TABLE IF EXISTS `Designation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Designation` (
  `DesignationID` int NOT NULL AUTO_INCREMENT,
  `DesignationName` varchar(255) NOT NULL,
  PRIMARY KEY (`DesignationID`)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Diarrhea`
--

DROP TABLE IF EXISTS `Diarrhea`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Diarrhea` (
  `DiarrheaID` int NOT NULL AUTO_INCREMENT,
  `DiseaseID` int NOT NULL,
  `PatientID` int NOT NULL,
  `Symptoms` text,
  `TestResult` varchar(255) DEFAULT NULL,
  `AdmissionDate` date DEFAULT NULL,
  PRIMARY KEY (`DiarrheaID`),
  KEY `idx_diarrhea_disease` (`DiseaseID`),
  KEY `idx_diarrhea_patient` (`PatientID`),
  CONSTRAINT `fk_diarrhea_disease` FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
  CONSTRAINT `fk_diarrhea_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Disease`
--

DROP TABLE IF EXISTS `Disease`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Disease` (
  `DiseaseID` int NOT NULL AUTO_INCREMENT,
  `DiseaseName` varchar(255) NOT NULL,
  `ICDCode` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`DiseaseID`),
  KEY `idx_disease_name` (`DiseaseName`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `HIV`
--

DROP TABLE IF EXISTS `HIV`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `HIV` (
  `HIVID` int NOT NULL AUTO_INCREMENT,
  `DiseaseID` int NOT NULL,
  `PatientID` int NOT NULL,
  `DiagnosisDate` date DEFAULT NULL,
  `HIVStatus` varchar(100) DEFAULT NULL,
  `TestResult` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`HIVID`),
  KEY `idx_hiv_disease` (`DiseaseID`),
  KEY `idx_hiv_patient` (`PatientID`),
  CONSTRAINT `fk_hiv_disease` FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
  CONSTRAINT `fk_hiv_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `HealthFacility`
--

DROP TABLE IF EXISTS `HealthFacility`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `HealthFacility` (
  `FacilityID` int NOT NULL AUTO_INCREMENT,
  `FacilityType` varchar(150) DEFAULT NULL,
  `FacilityName` varchar(255) NOT NULL,
  `RegionID` int DEFAULT NULL,
  PRIMARY KEY (`FacilityID`),
  KEY `idx_healthfacility_region` (`RegionID`),
  CONSTRAINT `fk_healthfacility_region` FOREIGN KEY (`RegionID`) REFERENCES `AdministrativeRegion` (`RegionID`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `HealthWorker`
--

DROP TABLE IF EXISTS `HealthWorker`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `HealthWorker` (
  `WorkID` int NOT NULL AUTO_INCREMENT,
  `WorkerName` varchar(255) NOT NULL,
  `FacilityID` int DEFAULT NULL,
  `DesignationID` int NOT NULL,
  `Gender` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`WorkID`),
  KEY `idx_healthworker_facility` (`FacilityID`),
  KEY `idx_healthworker_designation` (`DesignationID`),
  CONSTRAINT `fk_healthworker_designation` FOREIGN KEY (`DesignationID`) REFERENCES `Designation` (`DesignationID`),
  CONSTRAINT `fk_healthworker_facility` FOREIGN KEY (`FacilityID`) REFERENCES `HealthFacility` (`FacilityID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `HospitalBed`
--

DROP TABLE IF EXISTS `HospitalBed`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `HospitalBed` (
  `BedID` int NOT NULL AUTO_INCREMENT,
  `FacilityID` int NOT NULL,
  `BedType` varchar(100) DEFAULT NULL,
  `Status` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`BedID`),
  KEY `idx_hospitalbed_facility` (`FacilityID`),
  CONSTRAINT `fk_hospitalbed_facility` FOREIGN KEY (`FacilityID`) REFERENCES `HealthFacility` (`FacilityID`)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Laboratory`
--

DROP TABLE IF EXISTS `Laboratory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Laboratory` (
  `LabID` int NOT NULL AUTO_INCREMENT,
  `LabName` varchar(255) NOT NULL,
  `FacilityID` int NOT NULL,
  PRIMARY KEY (`LabID`),
  KEY `idx_laboratory_facility` (`FacilityID`),
  CONSTRAINT `fk_laboratory_facility` FOREIGN KEY (`FacilityID`) REFERENCES `HealthFacility` (`FacilityID`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Malnutrition`
--

DROP TABLE IF EXISTS `Malnutrition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Malnutrition` (
  `MalnutritionID` int NOT NULL AUTO_INCREMENT,
  `PatientID` int NOT NULL,
  `Height` decimal(8,2) DEFAULT NULL,
  `BMI` decimal(8,2) DEFAULT NULL,
  `MalnutritionType` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`MalnutritionID`),
  KEY `idx_malnutrition_patient` (`PatientID`),
  CONSTRAINT `fk_malnutrition_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `MaternalHealth`
--

DROP TABLE IF EXISTS `MaternalHealth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MaternalHealth` (
  `MotherID` int NOT NULL AUTO_INCREMENT,
  `PatientID` int NOT NULL,
  `StartDate` date DEFAULT NULL,
  PRIMARY KEY (`MotherID`),
  KEY `idx_maternal_patient` (`PatientID`),
  CONSTRAINT `fk_maternal_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Measles`
--

DROP TABLE IF EXISTS `Measles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Measles` (
  `MeaslesID` int NOT NULL AUTO_INCREMENT,
  `DiseaseID` int NOT NULL,
  `PatientID` int NOT NULL,
  `Symptoms` text,
  `Fever` varchar(50) DEFAULT NULL,
  `DiagnosisDate` date DEFAULT NULL,
  PRIMARY KEY (`MeaslesID`),
  KEY `idx_measles_disease` (`DiseaseID`),
  KEY `idx_measles_patient` (`PatientID`),
  CONSTRAINT `fk_measles_disease` FOREIGN KEY (`DiseaseID`) REFERENCES `Disease` (`DiseaseID`),
  CONSTRAINT `fk_measles_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Newborn`
--

DROP TABLE IF EXISTS `Newborn`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Newborn` (
  `NewbornID` int NOT NULL AUTO_INCREMENT,
  `MotherID` int NOT NULL,
  `BirthDate` date DEFAULT NULL,
  PRIMARY KEY (`NewbornID`),
  KEY `idx_newborn_mother` (`MotherID`),
  CONSTRAINT `fk_newborn_mother` FOREIGN KEY (`MotherID`) REFERENCES `MaternalHealth` (`MotherID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Patient`
--

DROP TABLE IF EXISTS `Patient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Patient` (
  `PatientID` int NOT NULL AUTO_INCREMENT,
  `FullName` varchar(255) DEFAULT NULL,
  `DateOfBirth` date DEFAULT NULL,
  `Gender` varchar(30) DEFAULT NULL,
  `NationalID` varchar(50) DEFAULT NULL,
  `BedID` int DEFAULT NULL,
  PRIMARY KEY (`PatientID`),
  UNIQUE KEY `NationalID` (`NationalID`),
  KEY `idx_patient_nationalid` (`NationalID`),
  KEY `idx_patient_bed` (`BedID`),
  CONSTRAINT `fk_patient_bed` FOREIGN KEY (`BedID`) REFERENCES `HospitalBed` (`BedID`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `PopulationGroup`
--

DROP TABLE IF EXISTS `PopulationGroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PopulationGroup` (
  `PopulationGroupID` int NOT NULL AUTO_INCREMENT,
  `RegionID` int DEFAULT NULL,
  `Population` bigint DEFAULT NULL,
  PRIMARY KEY (`PopulationGroupID`),
  KEY `idx_populationgroup_region` (`RegionID`),
  CONSTRAINT `fk_populationgroup_region` FOREIGN KEY (`RegionID`) REFERENCES `AdministrativeRegion` (`RegionID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TelemedicineCenter`
--

DROP TABLE IF EXISTS `TelemedicineCenter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TelemedicineCenter` (
  `CenterID` int NOT NULL AUTO_INCREMENT,
  `ConsultationID` varchar(100) DEFAULT NULL,
  `PatientID` int DEFAULT NULL,
  PRIMARY KEY (`CenterID`),
  KEY `idx_telemedicine_patient` (`PatientID`),
  CONSTRAINT `fk_telemedicine_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Vaccination`
--

DROP TABLE IF EXISTS `Vaccination`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Vaccination` (
  `VaccineID` int NOT NULL AUTO_INCREMENT,
  `VaccineName` varchar(255) NOT NULL,
  `PatientID` int NOT NULL,
  PRIMARY KEY (`VaccineID`),
  KEY `idx_vaccination_patient` (`PatientID`),
  CONSTRAINT `fk_vaccination_patient` FOREIGN KEY (`PatientID`) REFERENCES `Patient` (`PatientID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'health_db'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-08-24 19:45:07
