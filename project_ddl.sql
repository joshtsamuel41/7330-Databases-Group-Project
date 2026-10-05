-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 ;
USE `mydb` ;

-- -----------------------------------------------------
-- Table `mydb`.`Book`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`Book` (
  `book_id` INT NOT NULL,
  `title` VARCHAR(45) NULL,
  `author` VARCHAR(45) NULL,
  `genre` VARCHAR(45) NULL,
  `publication_date` DATE NULL,
  PRIMARY KEY (`book_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`Book_copy`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`Book_copy` (
  `copy_id` INT NOT NULL,
  `acquisition_date` DATE NULL,
  `condition` VARCHAR(45) NULL,
  `status` VARCHAR(45) NULL,
  `Book_book_id` INT NOT NULL,
  PRIMARY KEY (`copy_id`, `Book_book_id`),
  INDEX `fk_Book_copy_Book_idx` (`Book_book_id` ASC) VISIBLE,
  CONSTRAINT `fk_Book_copy_Book`
    FOREIGN KEY (`Book_book_id`)
    REFERENCES `mydb`.`Book` (`book_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`Member`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`Member` (
  `member_id` INT NOT NULL,
  `first_name` VARCHAR(45) NULL,
  `last_name` VARCHAR(45) NULL,
  `phone_num` VARCHAR(45) NULL,
  `member_date` DATE NULL,
  PRIMARY KEY (`member_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`Loan`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`Loan` (
  `loan_id` INT NOT NULL,
  `date_out` DATE NULL,
  `due_date` DATE NULL,
  `status` VARCHAR(45) NULL,
  `return_date` DATE NULL,
  `Book_copy_copy_id` INT NOT NULL,
  `Member_member_id` INT NOT NULL,
  PRIMARY KEY (`loan_id`, `Book_copy_copy_id`, `Member_member_id`),
  INDEX `fk_Loan_Book_copy1_idx` (`Book_copy_copy_id` ASC) VISIBLE,
  INDEX `fk_Loan_Member1_idx` (`Member_member_id` ASC) VISIBLE,
  CONSTRAINT `fk_Loan_Book_copy1`
    FOREIGN KEY (`Book_copy_copy_id`)
    REFERENCES `mydb`.`Book_copy` (`copy_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Loan_Member1`
    FOREIGN KEY (`Member_member_id`)
    REFERENCES `mydb`.`Member` (`member_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`Transaction_log`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`Transaction_log` (
  `tx_id` INT NOT NULL,
  `operation_type` VARCHAR(45) NULL,
  `timestamp` DATETIME NULL,
  `isolation_level` VARCHAR(45) NULL,
  `strategy` VARCHAR(45) NULL,
  `success_flag` VARCHAR(45) NULL,
  `conflict_flag` VARCHAR(45) NULL,
  `deadlock_flag` VARCHAR(45) NULL,
  PRIMARY KEY (`tx_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`Conflict_log`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`Conflict_log` (
  `conflict_id` INT NOT NULL,
  `old_version` VARCHAR(45) NULL,
  `attempted_version` VARCHAR(45) NULL,
  `timestamp` VARCHAR(45) NULL,
  PRIMARY KEY (`conflict_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`deadlock_log`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`deadlock_log` (
  `deadlock_id` INT NOT NULL,
  `tx1_id` INT NULL,
  `tx2_id` INT NULL,
  `timestamp` DATETIME NULL,
  `description` VARCHAR(45) NULL,
  PRIMARY KEY (`deadlock_id`))
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
