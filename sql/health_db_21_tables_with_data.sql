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
-- Dumping data for table `AdministrativeRegion`
--

LOCK TABLES `AdministrativeRegion` WRITE;
/*!40000 ALTER TABLE `AdministrativeRegion` DISABLE KEYS */;
INSERT INTO `AdministrativeRegion` VALUES (1,'Dhaka',1000000,'Division'),(2,'Chattogram',1500000,'Division'),(3,'Rajshahi',1200000,'Division'),(4,'Khulna',900000,'Division'),(5,'Barishal',700000,'Division'),(6,'Sylhet',800000,'Division'),(7,'Rangpur',1100000,'Division'),(8,'Mymensingh',950000,'Division');
/*!40000 ALTER TABLE `AdministrativeRegion` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Biopsy`
--

LOCK TABLES `Biopsy` WRITE;
/*!40000 ALTER TABLE `Biopsy` DISABLE KEYS */;
INSERT INTO `Biopsy` VALUES (1,1,'2023-03-01'),(2,2,'2023-03-11'),(3,3,'2023-03-21'),(4,4,'2023-03-31'),(5,5,'2023-04-10'),(6,6,'2023-04-20'),(7,7,'2023-04-30'),(8,8,'2023-05-10'),(9,9,'2023-05-20'),(10,10,'2023-05-30'),(11,11,'2023-06-09'),(12,12,'2023-06-19');
/*!40000 ALTER TABLE `Biopsy` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `CancerCase`
--

LOCK TABLES `CancerCase` WRITE;
/*!40000 ALTER TABLE `CancerCase` DISABLE KEYS */;
INSERT INTO `CancerCase` VALUES (1,1,1,'Lung','Confirmed','Stage I'),(2,2,2,'Colorectal','Confirmed','Stage II'),(3,3,3,'Ovarian','Confirmed','Stage III'),(4,4,4,'Oral','Confirmed','Stage IV'),(5,5,5,'Leukemia','Confirmed','Stage I'),(6,6,6,'Breast','Confirmed','Stage II'),(7,7,7,'Cervical','Confirmed','Stage III'),(8,8,1,'Ovarian','Confirmed','Stage IV'),(9,9,2,'Prostate','Confirmed','Stage I'),(10,10,3,'Esophagus','Confirmed','Stage II'),(11,11,4,'Esophagus','Confirmed','Stage III'),(12,12,5,'Stomach','Confirmed','Stage IV');
/*!40000 ALTER TABLE `CancerCase` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Covid19`
--

LOCK TABLES `Covid19` WRITE;
/*!40000 ALTER TABLE `Covid19` DISABLE KEYS */;
INSERT INTO `Covid19` VALUES (1,15,1,'Positive',98.10),(2,15,2,'Negative',98.50),(3,15,3,'Negative',98.90),(4,15,4,'Negative',99.30),(5,15,5,'Positive',99.70),(6,15,6,'Negative',100.10),(7,15,7,'Negative',98.10),(8,15,8,'Negative',98.50),(9,15,9,'Positive',98.90),(10,15,10,'Negative',99.30),(11,15,11,'Negative',99.70),(12,15,12,'Negative',100.10),(13,15,13,'Positive',98.10),(14,15,14,'Negative',98.50),(15,15,15,'Negative',98.90),(16,15,1,'Negative',99.30),(17,15,2,'Positive',99.70),(18,15,3,'Negative',100.10),(19,15,4,'Negative',98.10),(20,15,5,'Negative',98.50);
/*!40000 ALTER TABLE `Covid19` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Dengue`
--

LOCK TABLES `Dengue` WRITE;
/*!40000 ALTER TABLE `Dengue` DISABLE KEYS */;
INSERT INTO `Dengue` VALUES (1,14,1,47,'Female','Dengue with Warning Signs'),(2,14,2,45,'Male','Dengue Fever'),(3,14,3,44,'Female','Dengue Fever'),(4,14,4,43,'Male','Dengue with Warning Signs'),(5,14,5,42,'Female','Dengue Fever'),(6,14,6,41,'Male','Dengue Fever'),(7,14,7,40,'Female','Dengue with Warning Signs'),(8,14,8,39,'Male','Dengue Fever'),(9,14,9,38,'Female','Dengue Fever'),(10,14,10,37,'Male','Dengue with Warning Signs'),(11,14,11,36,'Female','Dengue Fever'),(12,14,12,35,'Male','Dengue Fever'),(13,14,13,34,'Female','Dengue with Warning Signs'),(14,14,14,33,'Male','Dengue Fever'),(15,14,15,32,'Female','Dengue Fever');
/*!40000 ALTER TABLE `Dengue` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Designation`
--

LOCK TABLES `Designation` WRITE;
/*!40000 ALTER TABLE `Designation` DISABLE KEYS */;
INSERT INTO `Designation` VALUES (1,'Director General'),(2,'Addl. Director General/equivalent'),(3,'Director/ Principal/ Vice Principal/OSD/equivalent'),(4,'Deputy Director/OSD/equivalent'),(5,'Assistant Director/Civil surgeon/OSD/equivalent'),(6,'Deputy civil surgeon/UHFPO/OSD'),(7,'Professor'),(8,'Associate professor'),(9,'Assistant professor'),(10,'Senior consultant'),(11,'Senior Lecturer'),(12,'Junior Lecturer'),(13,'Junior consultant'),(14,'Assistant surgeon/OSD/equivalent'),(15,'Sub Assistant Community Medical Officer (SACMO)'),(16,'Assistant Health Inspector'),(17,'Health Assistant'),(18,'Medical Technologist'),(19,'Medical Officer');
/*!40000 ALTER TABLE `Designation` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Diarrhea`
--

LOCK TABLES `Diarrhea` WRITE;
/*!40000 ALTER TABLE `Diarrhea` DISABLE KEYS */;
INSERT INTO `Diarrhea` VALUES (1,18,1,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-02-01'),(2,18,2,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-02-06'),(3,18,3,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-02-11'),(4,18,4,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-02-16'),(5,18,5,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-02-21'),(6,18,6,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-02-26'),(7,18,7,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-03-03'),(8,18,8,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-03-08'),(9,18,9,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-03-13'),(10,18,10,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-03-18'),(11,18,11,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-03-23'),(12,18,12,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-03-28'),(13,18,13,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-04-02'),(14,18,14,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-04-07'),(15,18,15,'Diarrhea and abdominal discomfort','Clinical diagnosis','2023-04-12');
/*!40000 ALTER TABLE `Diarrhea` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Disease`
--

LOCK TABLES `Disease` WRITE;
/*!40000 ALTER TABLE `Disease` DISABLE KEYS */;
INSERT INTO `Disease` VALUES (12,'Cancer',NULL),(13,'Diabetes',NULL),(14,'Dengue','A90'),(15,'COVID-19','U07.1'),(16,'Measles','B05.9'),(17,'HIV',NULL),(18,'Diarrhea',NULL),(19,'Cholera (Diarrheal Infection)','A00.9'),(20,'Tuberculosis (Pulmonary TB)','A15.0');
/*!40000 ALTER TABLE `Disease` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `HIV`
--

LOCK TABLES `HIV` WRITE;
/*!40000 ALTER TABLE `HIV` DISABLE KEYS */;
INSERT INTO `HIV` VALUES (1,17,1,'2022-01-15','Positive','Reactive'),(2,17,2,'2022-01-30','Negative','Non-reactive'),(3,17,3,'2022-02-14','Negative','Non-reactive'),(4,17,4,'2022-03-01','Positive','Reactive'),(5,17,5,'2022-03-16','Negative','Non-reactive'),(6,17,6,'2022-03-31','Negative','Non-reactive'),(7,17,7,'2022-04-15','Positive','Reactive'),(8,17,8,'2022-04-30','Negative','Non-reactive'),(9,17,9,'2022-05-15','Negative','Non-reactive'),(10,17,10,'2022-05-30','Positive','Reactive'),(11,17,11,'2022-06-14','Negative','Non-reactive'),(12,17,12,'2022-06-29','Negative','Non-reactive'),(13,17,13,'2022-07-14','Positive','Reactive'),(14,17,14,'2022-07-29','Negative','Non-reactive'),(15,17,15,'2022-08-13','Negative','Non-reactive');
/*!40000 ALTER TABLE `HIV` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `HealthFacility`
--

LOCK TABLES `HealthFacility` WRITE;
/*!40000 ALTER TABLE `HealthFacility` DISABLE KEYS */;
INSERT INTO `HealthFacility` VALUES (1,'Health Facility','Dr. Moklessur Clinic, Sadar Road, Barisal',1),(2,'Hospital','Damien Foundation. Netrakona TB & Leprosy Hospital, Anantapur, Netrakona',2),(3,'Hospital','Dastagir Private Hospital, Narsingdi',3),(4,'Hospital','Desh Eye Hospital, Gazipur Sadar',4),(5,'Hospital','Dhaka Community Hospital, Dhaka',1),(6,'Hospital','Dhaka Hospital, icddr,b',1),(7,'Hospital','Dobir Uddin Hospital, Kasiadanga, Rajshahi',3),(8,'Hospital','Doctors Care Clinic and Hospital, Barguna, Barisal',8),(9,'Health Facility','Dolphin Clinic, Bornalimur, Rajshahi',3),(10,'Health Facility','Dr.Khadem Hossain Clinic, Bangla Bazar, Barisal',2),(11,'Hospital','Dream Hospital, Begumganj, Noakhali',3),(12,'Hospital','East West Medical College Hospital, Uttara, Dhaka',1),(13,'Hospital','Ebnee Hashman (Pvt.) Hospital, Feni, Chittagong',5),(14,'Hospital','Ehsan Genaral Hospital, Magura',6),(15,'Hospital','Ekushey Hospital (Pvt), Mymensingh Sadar',8),(16,'Health Facility','Fair Health Clinic, Barisal',8),(17,'Hospital','Faruk Al-Nasir Hospital, Kazipur, Sirajganj',1),(18,'Health Facility','Farzina Clinic, Kazipur, Sirajganj',2),(19,'Hospital','Good Heal Hospital, Maijdee, Noakhali',3),(20,'Health Facility','Gorib Shah Clinic, Magura',4),(21,'Health Facility','Gorib-E-Nawaz Clinic, Talaimari, Rajshahi',3),(22,'Health Facility','Hasina Clinic & Nursing Home, Magura',6),(23,'Hospital','Hathazari Adhunic Hospital, Chittagong',7),(24,'Health Facility','Health Care Clinic, Parara Road, Barisal',8),(25,'Health Facility','Impact Masudul Haque Community Health Centre, Chuadanga',1),(26,'Hospital','Islami Bank Hospital, Chandmary, Barisal',2),(27,'Hospital','Islami Bank Hospital, Dhaka',1),(28,'Hospital','Islami Bank Hospital, Laxmipur, Rajshahi',3),(29,'Hospital','Islami General Hospital, Keshorhat, Rajshahi',3),(30,'Hospital','Islami General Hospital, Nowhata, Rajshahi',3),(31,'Health Facility','Islamia Poly Clinic, Bangla Bazar, Barisal',7),(32,'Health Facility','Jahangir Health Complex, Mymensingh Sadar',8),(33,'Hospital','Jalalabad Ragib-Rabeya Hospital, Sylhet',6),(34,'Health Facility','Jam-Jam Islami Clinic, Laxmipur, Rajshahi',3),(35,'Hospital','Jamuna (Pvt.) Hospital, Mymensingh Sadar',8),(36,'Health Facility','Jamuna Clinic, Kaliganj, Satkhira',4),(37,'Health Facility','Jamuna Clinic, Laxmipur, Rajshahi',3),(38,'Health Facility','Janani Clinic, Jiban Nagar, Chuadanga, Khulna',4),(39,'Hospital','Janani General Hospital, Noakhali Sadar',7),(40,'Health Facility','Janaseba Clinic & Nursing Home, Magura',8),(41,'Health Facility','Janaseba Clinic, Assasuni, Satkhira',1),(42,'Health Facility','Janata Clinic & Nursing Home, Magura',2),(43,'Health Facility','Janata Clinic, Shipaipara, Rajshahi',3),(44,'Hospital','Jayeda Hospital, Bonpara, Natore',4),(45,'Hospital','Kaisar Memorial Hospital, Uposhahor, Chittagong',5),(46,'Health Facility','Cox\'s Bazar Community Clinic',6),(47,'Health Facility','Primary Care Clinic',7),(48,'Health Facility','Upazila Health Complex',8),(49,'Health Facility','IOM Coordination Clinic',1),(50,'Health Facility','Community Health Clinic',2),(51,'Health Facility','Government Community Clinic',3),(52,'Health Facility','Primary Health Center',4),(53,'Health Facility','Community Clinic (MOH)',5),(54,'Hospital','Field Hospital',6),(55,'Hospital','Upazila HC and Sadar Hospital',7),(56,'Health Facility','Chest disease clinic',8),(57,'Hospital','Chest hospital',1),(58,'Hospital','District-level hospital (District/ General Hospital)',2),(59,'Hospital','Dental college hospital',3),(60,'Hospital','Hospital of alternative medicine',4),(61,'Hospital','Infectious disease hospital',5),(62,'Hospital','Leprosy hospital',6),(63,'Hospital','Medical college hospital',7),(64,'Health Facility','Specialized Health Center',8),(65,'Hospital','Specialized hospital',1),(66,'Hospital','Specialty postgraduate institute and hospital',2),(67,'Hospital','Other hospitals',3),(68,'Hospital','Kurmitola 500-bed General Hospital, Dhaka',1),(69,'Hospital','Mugda 500-bed General Hospital, Dhaka',1),(70,'Hospital','Narayanganj 300-bed Hospital',6),(71,'Hospital','Narsingdi 100-bed Hospital',7),(72,'Hospital','Shaheed Ahsan Ullah Master General Hospital, Tongi, Gazipur',8),(73,'Hospital','Bangladesh-Korea Moitree Hospital, Savar, Dhaka',1),(74,'Hospital','Kuwait-Bangladesh Friendship Govt. Hospital, Uttara, Dhaka',1),(75,'Hospital','Saidpur 100-bed Hospital, Nilphamari',3),(76,'Hospital','A K Eye Hospital, Magura',4),(77,'Hospital','Ad-Din Medical College Hospital, Dhaka',1),(78,'Hospital','Ahamedia General Hospital, Mymensingh',8),(79,'Health Facility','Ahsania Clinic, Debhata, Satkhira',7),(80,'Health Facility','Akota Clinic & Diagnostic Center, Rajshahi',3),(81,'Health Facility','Akota Clinic, Satkhira Sadar',1),(82,'Hospital','Al Hera Private Hospital, Magura',2),(83,'Hospital','Al Modina Genaral Hospital, Kishoreganj',3),(84,'Hospital','Al Safa (Pvt.) Hospital, Mymensingh Sadar',8),(85,'Hospital','Al Zannat (Pvt.) Hospital, Mymensingh Sadar',8),(86,'Health Facility','Albaraka Clinic, Laxmipur, Rajshahi',3),(87,'Health Facility','Al-Baraka Clinic, Magura',7),(88,'Health Facility','Al-Modina Clinic, Magura',8),(89,'Health Facility','Al-Shefa Clinic, Joypurhat',1),(90,'Hospital','Ambia Hospital, Bogra Road, Barisal',2),(91,'Hospital','Ambia Hospital, Pirojpur, Barisal',3),(92,'Health Facility','Amena Clinic, Talaimari, Rajshahi',3),(93,'Hospital','Amina Hospital, Bonpara, Natore',5),(94,'Health Facility','Anowara Clinic, Satkhira Sadar',6),(95,'Hospital','Anwara Private Hospital, Jhenaidah',7),(96,'Hospital','Apollo Hospital &Diagnostic Complex, Maijdee Bazar, Noakhali',8),(97,'Hospital','Apollo Hospitals, Dhaka',1),(98,'Health Facility','Arafat Clinic &Diagnostic, Munshiganj',2),(99,'Health Facility','Aroggo Clinic, Magura',3),(100,'Hospital','Asha (Pvt.) Hospital, Mymensingh Sadar',8);
/*!40000 ALTER TABLE `HealthFacility` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `HealthWorker`
--

LOCK TABLES `HealthWorker` WRITE;
/*!40000 ALTER TABLE `HealthWorker` DISABLE KEYS */;
INSERT INTO `HealthWorker` VALUES (1,'Dr. Prasanta Kumar Chakraborty',1,19,'Male'),(2,'Dr. Neelufar Rahman',2,19,'Male'),(3,'Dr. Sadat Khondakar',3,19,'Male'),(4,'Dr. Md. Ehsanul Alam',4,19,'Male'),(5,'Dr. Md. Mozaharul Islam',5,19,'Male'),(6,'Dr. Ahsan Rahman',6,19,'Male'),(7,'Dr. Nusrat Sultana',7,19,'Female'),(8,'Dr. Farzana Ahmed',8,19,'Female'),(9,'Dr. Md. Saiful Islam',9,19,'Male'),(10,'Dr. Tanvir Hasan',10,19,'Male'),(11,'Dr. Sadia Rahman',11,19,'Female'),(12,'Dr. Nazmul Islam',12,19,'Male');
/*!40000 ALTER TABLE `HealthWorker` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `HospitalBed`
--

LOCK TABLES `HospitalBed` WRITE;
/*!40000 ALTER TABLE `HospitalBed` DISABLE KEYS */;
INSERT INTO `HospitalBed` VALUES (1,1,'General','Occupied'),(2,2,'ICU','Available'),(3,3,'Emergency','Available'),(4,4,'General','Available'),(5,5,'ICU','Occupied'),(6,6,'Emergency','Available'),(7,7,'General','Available'),(8,8,'ICU','Available'),(9,9,'Emergency','Occupied'),(10,10,'General','Available'),(11,11,'ICU','Available'),(12,12,'Emergency','Available'),(13,13,'General','Occupied'),(14,14,'ICU','Available'),(15,15,'Emergency','Available'),(16,16,'General','Available'),(17,17,'ICU','Occupied'),(18,18,'Emergency','Available'),(19,19,'General','Available'),(20,20,'ICU','Available'),(21,21,'Emergency','Occupied'),(22,22,'General','Available'),(23,23,'ICU','Available'),(24,24,'Emergency','Available'),(25,25,'General','Occupied'),(26,26,'ICU','Available'),(27,27,'Emergency','Available'),(28,28,'General','Available'),(29,29,'ICU','Occupied'),(30,30,'Emergency','Available'),(31,31,'General','Available'),(32,32,'ICU','Available'),(33,33,'Emergency','Occupied'),(34,34,'General','Available'),(35,35,'ICU','Available'),(36,36,'Emergency','Available'),(37,37,'General','Occupied'),(38,38,'ICU','Available'),(39,39,'Emergency','Available'),(40,40,'General','Available'),(41,41,'ICU','Occupied'),(42,42,'Emergency','Available'),(43,43,'General','Available'),(44,44,'ICU','Available'),(45,45,'Emergency','Occupied'),(46,46,'General','Available'),(47,47,'ICU','Available'),(48,48,'Emergency','Available'),(49,49,'General','Occupied'),(50,50,'ICU','Available'),(51,51,'Emergency','Available'),(52,52,'General','Available'),(53,53,'ICU','Occupied'),(54,54,'Emergency','Available'),(55,55,'General','Available'),(56,56,'ICU','Available'),(57,57,'Emergency','Occupied'),(58,58,'General','Available'),(59,59,'ICU','Available'),(60,60,'Emergency','Available');
/*!40000 ALTER TABLE `HospitalBed` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Laboratory`
--

LOCK TABLES `Laboratory` WRITE;
/*!40000 ALTER TABLE `Laboratory` DISABLE KEYS */;
INSERT INTO `Laboratory` VALUES (1,'Pathology Laboratory/ Diagnostic',1),(2,'PCR Lab',2),(3,'RT PCR Lab (Govt.)',3),(4,'RT PCR Lab (Pvt.)',4),(5,'General Diagnostic Laboratory',5),(6,'Imaging and Radiology Laboratory',6),(7,'Physiotherapy and Allied Health Laboratory',7);
/*!40000 ALTER TABLE `Laboratory` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Malnutrition`
--

LOCK TABLES `Malnutrition` WRITE;
/*!40000 ALTER TABLE `Malnutrition` DISABLE KEYS */;
INSERT INTO `Malnutrition` VALUES (1,1,90.00,14.20,'Underweight'),(2,2,92.40,14.70,'Stunting'),(3,3,94.80,15.20,'Wasting'),(4,4,97.20,15.70,'Underweight'),(5,5,99.60,16.20,'Stunting'),(6,6,102.00,16.70,'Wasting'),(7,7,104.40,17.20,'Underweight'),(8,8,106.80,14.20,'Stunting'),(9,9,109.20,14.70,'Wasting'),(10,10,111.60,15.20,'Underweight'),(11,11,114.00,15.70,'Stunting'),(12,12,116.40,16.20,'Wasting'),(13,13,118.80,16.70,'Underweight'),(14,14,121.20,17.20,'Stunting'),(15,15,123.60,14.20,'Wasting');
/*!40000 ALTER TABLE `Malnutrition` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `MaternalHealth`
--

LOCK TABLES `MaternalHealth` WRITE;
/*!40000 ALTER TABLE `MaternalHealth` DISABLE KEYS */;
INSERT INTO `MaternalHealth` VALUES (1,1,'2023-01-01'),(2,3,'2023-01-21'),(3,5,'2023-02-10'),(4,7,'2023-03-02'),(5,9,'2023-03-22'),(6,11,'2023-04-11'),(7,13,'2023-05-01'),(8,15,'2023-05-21'),(9,1,'2023-06-10'),(10,3,'2023-06-30'),(11,5,'2023-07-20'),(12,7,'2023-08-09');
/*!40000 ALTER TABLE `MaternalHealth` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Measles`
--

LOCK TABLES `Measles` WRITE;
/*!40000 ALTER TABLE `Measles` DISABLE KEYS */;
INSERT INTO `Measles` VALUES (1,16,1,'Fever and rash','Yes','2023-01-10'),(2,16,2,'Fever and rash','Yes','2023-01-22'),(3,16,3,'Fever and rash','Yes','2023-02-03'),(4,16,4,'Fever and rash','Yes','2023-02-15'),(5,16,5,'Fever and rash','Yes','2023-02-27'),(6,16,6,'Fever and rash','Yes','2023-03-11'),(7,16,7,'Fever and rash','Yes','2023-03-23'),(8,16,8,'Fever and rash','Yes','2023-04-04'),(9,16,9,'Fever and rash','Yes','2023-04-16'),(10,16,10,'Fever and rash','Yes','2023-04-28'),(11,16,11,'Fever and rash','Yes','2023-05-10'),(12,16,12,'Fever and rash','Yes','2023-05-22'),(13,16,13,'Fever and rash','Yes','2023-06-03'),(14,16,14,'Fever and rash','Yes','2023-06-15'),(15,16,15,'Fever and rash','Yes','2023-06-27');
/*!40000 ALTER TABLE `Measles` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Newborn`
--

LOCK TABLES `Newborn` WRITE;
/*!40000 ALTER TABLE `Newborn` DISABLE KEYS */;
INSERT INTO `Newborn` VALUES (1,1,'2023-02-01'),(2,2,'2023-02-12'),(3,3,'2023-02-23'),(4,4,'2023-03-06'),(5,5,'2023-03-17'),(6,6,'2023-03-28'),(7,7,'2023-04-08'),(8,8,'2023-04-19'),(9,9,'2023-04-30'),(10,10,'2023-05-11');
/*!40000 ALTER TABLE `Newborn` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Patient`
--

LOCK TABLES `Patient` WRITE;
/*!40000 ALTER TABLE `Patient` DISABLE KEYS */;
INSERT INTO `Patient` VALUES (1,'Amena Khatun','1979-01-01','Female','DEMO-NID-000001',1),(2,'Rahim Uddin','1980-02-02','Male','DEMO-NID-000002',2),(3,'Nasrin Akter','1981-03-03','Female','DEMO-NID-000003',3),(4,'Md. Hasan Ali','1982-04-04','Male','DEMO-NID-000004',4),(5,'Shamima Sultana','1983-05-05','Female','DEMO-NID-000005',5),(6,'Rafiq Islam','1984-06-06','Male','DEMO-NID-000006',6),(7,'Salma Begum','1985-07-07','Female','DEMO-NID-000007',7),(8,'Kamrul Hasan','1986-08-08','Male','DEMO-NID-000008',8),(9,'Farzana Yasmin','1987-09-09','Female','DEMO-NID-000009',9),(10,'Tanvir Ahmed','1988-10-10','Male','DEMO-NID-000010',10),(11,'Sadia Rahman','1989-11-11','Female','DEMO-NID-000011',11),(12,'Mahmudul Hasan','1990-12-12','Male','DEMO-NID-000012',12),(13,'Nusrat Jahan','1991-01-13','Female','DEMO-NID-000013',13),(14,'Jahidul Islam','1992-02-14','Male','DEMO-NID-000014',14),(15,'Mim Akter','1993-03-15','Female','DEMO-NID-000015',15);
/*!40000 ALTER TABLE `Patient` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `PopulationGroup`
--

LOCK TABLES `PopulationGroup` WRITE;
/*!40000 ALTER TABLE `PopulationGroup` DISABLE KEYS */;
INSERT INTO `PopulationGroup` VALUES (1,1,1000000),(2,2,1500000),(3,3,1200000),(4,4,900000),(5,5,700000),(6,6,800000),(7,7,1100000),(8,8,950000);
/*!40000 ALTER TABLE `PopulationGroup` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `TelemedicineCenter`
--

LOCK TABLES `TelemedicineCenter` WRITE;
/*!40000 ALTER TABLE `TelemedicineCenter` DISABLE KEYS */;
INSERT INTO `TelemedicineCenter` VALUES (1,'CONS-0001',1),(2,'CONS-0002',2),(3,'CONS-0003',3),(4,'CONS-0004',4),(5,'CONS-0005',5),(6,'CONS-0006',6),(7,'CONS-0007',7),(8,'CONS-0008',8),(9,'CONS-0009',9),(10,'CONS-0010',10);
/*!40000 ALTER TABLE `TelemedicineCenter` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `Vaccination`
--

LOCK TABLES `Vaccination` WRITE;
/*!40000 ALTER TABLE `Vaccination` DISABLE KEYS */;
INSERT INTO `Vaccination` VALUES (1,'BCG',1),(2,'OPV',2),(3,'Pentavalent',3),(4,'PCV',4),(5,'IPV',5),(6,'MR',6);
/*!40000 ALTER TABLE `Vaccination` ENABLE KEYS */;
UNLOCK TABLES;

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

-- Dump completed on 2026-08-24 19:45:18
