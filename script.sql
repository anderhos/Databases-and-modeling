-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema WESH_sampler
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema WESH_sampler
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `WESH_sampler` DEFAULT CHARACTER SET utf8 ;
USE `WESH_sampler` ;

# Raw tables
DROP TABLE IF EXISTS samples_taken, analysis_done, test_groups_raw;

CREATE TABLE samples_taken(
sample_id INT,
tests_to_run VARCHAR(30),
sample_time DATETIME,
operator_id INT,
name VARCHAR(30),
role VARCHAR(30),
PRIMARY KEY (sample_id));
 
LOAD DATA LOCAL INFILE "PATH/samples_taken.csv"
INTO TABLE samples_taken
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE analysis_done(
analysis_id INT,
analysis_time DATETIME,
test_name VARCHAR(30),
analysis_result FLOAT,
sample_id INT,
name VARCHAR(30),
role VARCHAR(30),
PRIMARY KEY (analysis_id));

LOAD DATA LOCAL INFILE "PATH/analysis_done.csv"
INTO TABLE analysis_done
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE test_groups_raw(
test_group VARCHAR(30),
test_name VARCHAR(30),
test_id INT,
test_description VARCHAR(300),
PRIMARY KEY (test_group, test_id));

LOAD DATA LOCAL INFILE "PATH/test_groups.csv"
INTO TABLE test_groups_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM test_groups_raw;
SELECT * FROM samples_taken;


-- -----------------------------------------------------
-- Table `WESH_sampler`.`operators`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `WESH_sampler`.`operators` ;

CREATE TABLE IF NOT EXISTS `WESH_sampler`.`operators` (
  `operator_id` INT NOT NULL,
  `name` VARCHAR(30) NULL,
  `role` VARCHAR(20) NULL,
  PRIMARY KEY (`operator_id`),
  UNIQUE INDEX `operator_id_UNIQUE` (`operator_id` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `WESH_sampler`.`available_tests`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `WESH_sampler`.`available_tests` ;

CREATE TABLE IF NOT EXISTS `WESH_sampler`.`available_tests` (
  `test_id` INT NOT NULL,
  `test_name` VARCHAR(45) NULL,
  `test_description` VARCHAR(300) NULL,
  PRIMARY KEY (`test_id`),
  UNIQUE INDEX `test_id_UNIQUE` (`test_id` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `WESH_sampler`.`test_groups`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `WESH_sampler`.`test_groups` ;

CREATE TABLE IF NOT EXISTS `WESH_sampler`.`test_groups` (
  `sample_type` VARCHAR(30) NOT NULL,
  `test_id` INT NOT NULL,
  PRIMARY KEY (`sample_type`, `test_id`),
  INDEX `fk_test_groups_available_tests1_idx` (`test_id` ASC) VISIBLE,
  CONSTRAINT `fk_test_groups_available_tests1`
    FOREIGN KEY (`test_id`)
    REFERENCES `WESH_sampler`.`available_tests` (`test_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `WESH_sampler`.`samples`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `WESH_sampler`.`samples` ;

CREATE TABLE IF NOT EXISTS `WESH_sampler`.`samples` (
  `QR_code` INT NOT NULL,
  `sample_type` VARCHAR(30) NOT NULL,
  `sample_time` DATETIME NOT NULL COMMENT 'Edit format',
  `operator_id` INT NOT NULL,
  PRIMARY KEY (`QR_code`),
  INDEX `fk_samples_operators_idx` (`operator_id` ASC) VISIBLE,
  INDEX `fk_samples_test_group_samples1_idx` (`sample_type` ASC) VISIBLE,
  UNIQUE INDEX `QR_code_UNIQUE` (`QR_code` ASC) VISIBLE,
  CONSTRAINT `fk_samples_operators`
    FOREIGN KEY (`operator_id`)
    REFERENCES `WESH_sampler`.`operators` (`operator_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_samples_test_group_samples1`
    FOREIGN KEY (`sample_type`)
    REFERENCES `WESH_sampler`.`test_groups` (`sample_type`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `WESH_sampler`.`analysis_results`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `WESH_sampler`.`analysis_results` ;

CREATE TABLE IF NOT EXISTS `WESH_sampler`.`analysis_results` (
  `analysis_id` INT NOT NULL,
  `QR_code` INT NOT NULL,
  `analysis_time` DATETIME NULL COMMENT 'Need formatting time',
  `analysis_result` VARCHAR(45) NOT NULL COMMENT 'Format?',
  `operator_id` INT NOT NULL,
  PRIMARY KEY (`analysis_id`),
  INDEX `fk_analysis_results_samples1_idx` (`QR_code` ASC) VISIBLE,
  INDEX `fk_analysis_results_operators1_idx` (`operator_id` ASC) VISIBLE,
  UNIQUE INDEX `analysis_id_UNIQUE` (`analysis_id` ASC) VISIBLE,
  CONSTRAINT `fk_analysis_results_samples1`
    FOREIGN KEY (`QR_code`)
    REFERENCES `WESH_sampler`.`samples` (`QR_code`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_analysis_results_operators1`
    FOREIGN KEY (`operator_id`)
    REFERENCES `WESH_sampler`.`operators` (`operator_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

# insert data into operators table, samples, test groups and available tests

INSERT INTO operators
SELECT DISTINCT operator_id, name, role FROM samples_taken;

INSERT INTO available_tests
SELECT DISTINCT test_id, test_name, test_description FROM test_groups_raw;

INSERT INTO test_groups
SELECT test_group, test_id FROM test_groups_raw;

INSERT INTO samples
SELECT DISTINCT sample_id, tests_to_run, sample_time, operator_id FROM samples_taken;

