DROP DATABASE IF EXISTS health_db;

CREATE DATABASE health_db;

USE health_db;

-- ==================================================
-- DIVISION
-- ==================================================

CREATE TABLE division (
    division_id INT AUTO_INCREMENT PRIMARY KEY,
    division_name VARCHAR(100) UNIQUE
);

-- ==================================================
-- HOSPITAL
-- ==================================================

CREATE TABLE hospital (
    hospital_id INT AUTO_INCREMENT PRIMARY KEY,
    division_id INT,
    hospital_name VARCHAR(255),
    current_beds INT,
    development_beds INT,
    proposed_beds INT,
    bed_increase INT,

    FOREIGN KEY (division_id)
        REFERENCES division(division_id)
);

-- ==================================================
-- DISEASE
-- ==================================================

CREATE TABLE disease (
    disease_id INT AUTO_INCREMENT PRIMARY KEY,
    disease_name VARCHAR(255) UNIQUE
);

-- ==================================================
-- AGE GROUP
-- ==================================================

CREATE TABLE age_group (
    age_group_id INT AUTO_INCREMENT PRIMARY KEY,
    age_group_name VARCHAR(50) UNIQUE
);

-- ==================================================
-- DISEASE STATISTICS
-- ==================================================

CREATE TABLE disease_statistics (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,

    disease_id INT,
    age_group_id INT,

    male_count INT,
    female_count INT,

    report_year INT,

    FOREIGN KEY (disease_id)
        REFERENCES disease(disease_id),

    FOREIGN KEY (age_group_id)
        REFERENCES age_group(age_group_id)
);

-- ==================================================
-- DESIGNATION
-- ==================================================

CREATE TABLE designation (
    designation_id INT AUTO_INCREMENT PRIMARY KEY,
    designation_name VARCHAR(255) UNIQUE
);

-- ==================================================
-- HUMAN RESOURCE
-- ==================================================

CREATE TABLE human_resource (
    hr_id INT AUTO_INCREMENT PRIMARY KEY,

    designation_id INT,

    sanctioned_post INT,
    existing_male INT,
    existing_female INT,
    existing_total INT,
    vacant_post INT,

    FOREIGN KEY (designation_id)
        REFERENCES designation(designation_id)
);

-- ==================================================
-- HEALTH PROGRAM
-- ==================================================

CREATE TABLE health_program (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    program_name VARCHAR(255)
);

-- ==================================================
-- HEALTH PROGRAM BUDGET
-- ==================================================

CREATE TABLE health_program_budget (
    budget_id INT AUTO_INCREMENT PRIMARY KEY,

    program_id INT,

    allocation_total DECIMAL(15,2),
    expenditure_total DECIMAL(15,2),
    progress_percent DECIMAL(10,2),

    FOREIGN KEY (program_id)
        REFERENCES health_program(program_id)
);

-- ==================================================
-- CANCER SITE
-- ==================================================

CREATE TABLE cancer_site (
    site_id INT AUTO_INCREMENT PRIMARY KEY,
    site_name VARCHAR(255)
);

-- ==================================================
-- CANCER STATISTICS
-- ==================================================

CREATE TABLE cancer_statistics (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,

    site_id INT,

    cases INT,
    percentage DECIMAL(10,2),

    FOREIGN KEY (site_id)
        REFERENCES cancer_site(site_id)
);

-- ==================================================
-- CANCER AGE DISTRIBUTION
-- ==================================================

CREATE TABLE cancer_age_distribution (
    distribution_id INT AUTO_INCREMENT PRIMARY KEY,

    icd_code VARCHAR(50),
    site_name VARCHAR(255),

    age_group VARCHAR(50),

    gender VARCHAR(20),

    cases INT
);
