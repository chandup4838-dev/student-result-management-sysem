-- =============================================================
-- EduResult - Student Result Management System
-- database/eduresult.sql
--
-- HOW TO USE
--   1. Open http://localhost/phpmyadmin
--   2. Click Import, choose this file, click Go
--      (the file creates the `eduresult` database itself)
--
-- Demo logins
--   Admin    : admin      / admin123
--   Student  : CSE2021001 / student123   (all students use student123)
-- =============================================================

CREATE DATABASE IF NOT EXISTS `eduresult`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `eduresult`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `results`;
DROP TABLE IF EXISTS `semesters`;
DROP TABLE IF EXISTS `subjects`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `admin`;
SET FOREIGN_KEY_CHECKS = 1;

-- -------------------------------------------------------------
-- 1. admin : examination cell accounts
-- -------------------------------------------------------------
CREATE TABLE `admin` (
  `id`       INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50)  NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL          -- bcrypt hash from password_hash()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
-- 2. users : students
-- -------------------------------------------------------------
CREATE TABLE `users` (
  `id`         INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` VARCHAR(20)  NOT NULL UNIQUE,   -- roll number, used for login
  `name`       VARCHAR(100) NOT NULL,
  `email`      VARCHAR(100) NOT NULL UNIQUE,
  `phone`      VARCHAR(20)  DEFAULT NULL,
  `department` VARCHAR(80)  NOT NULL,
  `year`       TINYINT      NOT NULL DEFAULT 1,
  `semester`   TINYINT      NOT NULL DEFAULT 1,
  `password`   VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
-- 3. subjects
-- -------------------------------------------------------------
CREATE TABLE `subjects` (
  `id`           INT AUTO_INCREMENT PRIMARY KEY,
  `subject_code` VARCHAR(20)  NOT NULL UNIQUE,
  `subject_name` VARCHAR(120) NOT NULL,
  `credits`      TINYINT      NOT NULL DEFAULT 3,
  `department`   VARCHAR(80)  NOT NULL,
  `semester`     TINYINT      NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
-- 4. results : one row per student per subject
-- -------------------------------------------------------------
CREATE TABLE `results` (
  `id`             INT AUTO_INCREMENT PRIMARY KEY,
  `student_id`     VARCHAR(20) NOT NULL,
  `subject_id`     INT         NOT NULL,
  `semester`       TINYINT     NOT NULL,
  `internal_marks` TINYINT     NOT NULL DEFAULT 0,   -- out of 25
  `external_marks` TINYINT     NOT NULL DEFAULT 0,   -- out of 75
  `total_marks`    SMALLINT    NOT NULL DEFAULT 0,   -- internal + external
  `grade`          VARCHAR(2)  NOT NULL DEFAULT 'F',
  `grade_point`    TINYINT     NOT NULL DEFAULT 0,
  `status`         ENUM('Draft','Published') NOT NULL DEFAULT 'Draft',
  UNIQUE KEY `uniq_student_subject` (`student_id`,`subject_id`),
  CONSTRAINT `fk_result_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`student_id`)
     ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_result_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`)
     ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
-- 5. semesters : SGPA / CGPA / percentage per semester
--    (rewritten by recalculateStudent() whenever marks change)
-- -------------------------------------------------------------
CREATE TABLE `semesters` (
  `id`         INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` VARCHAR(20)  NOT NULL,
  `semester`   TINYINT      NOT NULL,
  `sgpa`       DECIMAL(4,2) NOT NULL DEFAULT 0.00,
  `cgpa`       DECIMAL(4,2) NOT NULL DEFAULT 0.00,
  `percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  UNIQUE KEY `uniq_student_sem` (`student_id`,`semester`),
  CONSTRAINT `fk_sem_student` FOREIGN KEY (`student_id`) REFERENCES `users`(`student_id`)
     ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================
-- SAMPLE DATA
-- =============================================================

-- admin account (password: admin123)
INSERT INTO `admin` (`id`,`username`,`password`) VALUES
  (1,'admin','$2y$10$PO9xlq099TFHN4Gtn9f4AOujgsP2iG4xHdDl4VezTi54DQMQNDNSG');

-- students (password for every student: student123)
INSERT INTO `users` (`id`,`student_id`,`name`,`email`,`phone`,`department`,`year`,`semester`,`password`) VALUES
  (1,'CSE2021001','Aarav Sharma','aarav.sharma@eduresult.edu.in','9876543210','Computer Science & Engineering',2,4,'$2y$10$hhQSZr04W3TomRl2bqMX2OwW1D.gLkhLyqJNT1wE1HGuqhtgDnrBq'),
  (2,'CSE2021002','Diya Patel','diya.patel@eduresult.edu.in','9876543211','Computer Science & Engineering',2,4,'$2y$10$kqRFzykhyurM07SoCNFl3.54WnJY5m0hOuhS1zH7m5xoPAp1vQFdS'),
  (3,'CSE2021003','Rohan Verma','rohan.verma@eduresult.edu.in','9876543212','Computer Science & Engineering',2,4,'$2y$10$n2VSYxOR5K0N/R.0sPn2OOomn08MlYWgvPBilQZck2ZLxByUMrlki'),
  (4,'AID2021004','Sneha Reddy','sneha.reddy@eduresult.edu.in','9876543213','AI & Data Science',2,4,'$2y$10$MF8Yg0qzHOlQ4zeWKN7Qiul5YfUdxbUY4tiT3yocgUjnRRQpyYPqa'),
  (5,'ECE2021005','Karthik Nair','karthik.nair@eduresult.edu.in','9876543214','Electronics & Communication',2,3,'$2y$10$WhgIkKo9FY0Fl34tMcCBmucEiE23I0/CwUywT5l97yczKmtSQbPz6'),
  (6,'EEE2021006','Ananya Iyer','ananya.iyer@eduresult.edu.in','9876543215','Electrical & Electronics',2,3,'$2y$10$eslZmSAztCVcaD/YoMJy7urZezgD2ZwZWNO2c5zfdM3TwZPY0bRk2');

-- subjects
INSERT INTO `subjects` (`id`,`subject_code`,`subject_name`,`credits`,`department`,`semester`) VALUES
  (1,'CSE101','Engineering Mathematics I',4,'Computer Science & Engineering',1),
  (2,'CSE102','Engineering Physics',4,'Computer Science & Engineering',1),
  (3,'CSE103','Problem Solving using C',3,'Computer Science & Engineering',1),
  (4,'CSE104','Basic Electrical Engineering',3,'Computer Science & Engineering',1),
  (5,'CSE105','Communication Skills',2,'Computer Science & Engineering',1),
  (6,'CSE201','Engineering Mathematics II',4,'Computer Science & Engineering',2),
  (7,'CSE202','Data Structures',4,'Computer Science & Engineering',2),
  (8,'CSE203','Digital Logic Design',3,'Computer Science & Engineering',2),
  (9,'CSE204','Object Oriented Programming',3,'Computer Science & Engineering',2),
  (10,'CSE205','Environmental Science',2,'Computer Science & Engineering',2),
  (11,'CSE301','Discrete Mathematics',4,'Computer Science & Engineering',3),
  (12,'CSE302','Design and Analysis of Algorithms',4,'Computer Science & Engineering',3),
  (13,'CSE303','Database Management Systems',3,'Computer Science & Engineering',3),
  (14,'CSE304','Computer Organization',3,'Computer Science & Engineering',3),
  (15,'CSE305','Java Programming Lab',2,'Computer Science & Engineering',3),
  (16,'CSE401','Computer Networks',4,'Computer Science & Engineering',4),
  (17,'CSE402','Machine Learning',4,'Computer Science & Engineering',4),
  (18,'CSE403','Web Technology',3,'Computer Science & Engineering',4),
  (19,'CSE404','Software Engineering',3,'Computer Science & Engineering',4),
  (20,'CSE405','Operating Systems',2,'Computer Science & Engineering',4),
  (21,'AID101','Engineering Mathematics I',4,'AI & Data Science',1),
  (22,'AID102','Engineering Physics',4,'AI & Data Science',1),
  (23,'AID103','Python Programming',3,'AI & Data Science',1),
  (24,'AID104','Basic Electrical Engineering',3,'AI & Data Science',1),
  (25,'AID105','Communication Skills',2,'AI & Data Science',1),
  (26,'AID201','Engineering Mathematics II',4,'AI & Data Science',2),
  (27,'AID202','Data Structures using Python',4,'AI & Data Science',2),
  (28,'AID203','Digital Logic Design',3,'AI & Data Science',2),
  (29,'AID204','Probability and Statistics',3,'AI & Data Science',2),
  (30,'AID205','Environmental Science',2,'AI & Data Science',2),
  (31,'AID301','Linear Algebra for AI',4,'AI & Data Science',3),
  (32,'AID302','Data Mining',4,'AI & Data Science',3),
  (33,'AID303','Database Management Systems',3,'AI & Data Science',3),
  (34,'AID304','Artificial Intelligence',3,'AI & Data Science',3),
  (35,'AID305','Data Visualisation Lab',2,'AI & Data Science',3),
  (36,'AID401','Machine Learning',4,'AI & Data Science',4),
  (37,'AID402','Deep Learning',4,'AI & Data Science',4),
  (38,'AID403','Big Data Analytics',3,'AI & Data Science',4),
  (39,'AID404','Natural Language Processing',3,'AI & Data Science',4),
  (40,'AID405','Data Engineering Lab',2,'AI & Data Science',4),
  (41,'ECE101','Engineering Mathematics I',4,'Electronics & Communication',1),
  (42,'ECE102','Engineering Physics',4,'Electronics & Communication',1),
  (43,'ECE103','Programming for Engineers',3,'Electronics & Communication',1),
  (44,'ECE104','Basic Electrical Engineering',3,'Electronics & Communication',1),
  (45,'ECE105','Communication Skills',2,'Electronics & Communication',1),
  (46,'ECE201','Engineering Mathematics II',4,'Electronics & Communication',2),
  (47,'ECE202','Electronic Devices and Circuits',4,'Electronics & Communication',2),
  (48,'ECE203','Digital Electronics',3,'Electronics & Communication',2),
  (49,'ECE204','Network Analysis',3,'Electronics & Communication',2),
  (50,'ECE205','Environmental Science',2,'Electronics & Communication',2),
  (51,'ECE301','Signals and Systems',4,'Electronics & Communication',3),
  (52,'ECE302','Analog Communication',4,'Electronics & Communication',3),
  (53,'ECE303','Microprocessors',3,'Electronics & Communication',3),
  (54,'ECE304','Electromagnetic Field Theory',3,'Electronics & Communication',3),
  (55,'ECE305','Electronics Design Lab',2,'Electronics & Communication',3),
  (56,'ECE401','Digital Communication',4,'Electronics & Communication',4),
  (57,'ECE402','VLSI Design',4,'Electronics & Communication',4),
  (58,'ECE403','Control Systems',3,'Electronics & Communication',4),
  (59,'ECE404','Antennas and Wave Propagation',3,'Electronics & Communication',4),
  (60,'ECE405','Embedded Systems Lab',2,'Electronics & Communication',4),
  (61,'EEE101','Engineering Mathematics I',4,'Electrical & Electronics',1),
  (62,'EEE102','Engineering Physics',4,'Electrical & Electronics',1),
  (63,'EEE103','Programming for Engineers',3,'Electrical & Electronics',1),
  (64,'EEE104','Electrical Circuit Analysis',3,'Electrical & Electronics',1),
  (65,'EEE105','Communication Skills',2,'Electrical & Electronics',1),
  (66,'EEE201','Engineering Mathematics II',4,'Electrical & Electronics',2),
  (67,'EEE202','Electrical Machines I',4,'Electrical & Electronics',2),
  (68,'EEE203','Digital Electronics',3,'Electrical & Electronics',2),
  (69,'EEE204','Electromagnetic Fields',3,'Electrical & Electronics',2),
  (70,'EEE205','Environmental Science',2,'Electrical & Electronics',2),
  (71,'EEE301','Electrical Machines II',4,'Electrical & Electronics',3),
  (72,'EEE302','Power Systems I',4,'Electrical & Electronics',3),
  (73,'EEE303','Control Systems',3,'Electrical & Electronics',3),
  (74,'EEE304','Measurements and Instrumentation',3,'Electrical & Electronics',3),
  (75,'EEE305','Machines Lab',2,'Electrical & Electronics',3),
  (76,'EEE401','Power Electronics',4,'Electrical & Electronics',4),
  (77,'EEE402','Power Systems II',4,'Electrical & Electronics',4),
  (78,'EEE403','Microcontrollers',3,'Electrical & Electronics',4),
  (79,'EEE404','Renewable Energy Systems',3,'Electrical & Electronics',4),
  (80,'EEE405','Power Systems Lab',2,'Electrical & Electronics',4);

-- results (total, grade and grade point follow the grading table in includes/config.php)
INSERT INTO `results` (`id`,`student_id`,`subject_id`,`semester`,`internal_marks`,`external_marks`,`total_marks`,`grade`,`grade_point`,`status`) VALUES
  (1,'CSE2021001',1,1,20,59,79,'A',8,'Published'),
  (2,'CSE2021001',2,1,23,60,83,'A+',9,'Published'),
  (3,'CSE2021001',3,1,18,64,82,'A+',9,'Published'),
  (4,'CSE2021001',4,1,20,59,79,'A',8,'Published'),
  (5,'CSE2021001',5,1,23,69,92,'O',10,'Published'),
  (6,'CSE2021001',6,2,25,69,94,'O',10,'Published'),
  (7,'CSE2021001',7,2,20,63,83,'A+',9,'Published'),
  (8,'CSE2021001',8,2,24,68,92,'O',10,'Published'),
  (9,'CSE2021001',9,2,19,58,77,'A',8,'Published'),
  (10,'CSE2021001',10,2,18,60,78,'A',8,'Published'),
  (11,'CSE2021001',11,3,22,74,96,'O',10,'Published'),
  (12,'CSE2021001',12,3,20,67,87,'A+',9,'Published'),
  (13,'CSE2021001',13,3,21,72,93,'O',10,'Published'),
  (14,'CSE2021001',14,3,25,68,93,'O',10,'Published'),
  (15,'CSE2021001',15,3,22,72,94,'O',10,'Published'),
  (16,'CSE2021001',16,4,23,68,91,'O',10,'Published'),
  (17,'CSE2021001',17,4,21,66,87,'A+',9,'Published'),
  (18,'CSE2021001',18,4,24,69,93,'O',10,'Published'),
  (19,'CSE2021001',19,4,20,66,86,'A+',9,'Published'),
  (20,'CSE2021001',20,4,25,67,92,'O',10,'Published'),
  (21,'CSE2021002',1,1,21,68,89,'A+',9,'Published'),
  (22,'CSE2021002',2,1,25,67,92,'O',10,'Published'),
  (23,'CSE2021002',3,1,21,70,91,'O',10,'Published'),
  (24,'CSE2021002',4,1,25,73,98,'O',10,'Published'),
  (25,'CSE2021002',5,1,19,64,83,'A+',9,'Published'),
  (26,'CSE2021002',6,2,21,64,85,'A+',9,'Published'),
  (27,'CSE2021002',7,2,23,61,84,'A+',9,'Published'),
  (28,'CSE2021002',8,2,21,71,92,'O',10,'Published'),
  (29,'CSE2021002',9,2,24,74,98,'O',10,'Published'),
  (30,'CSE2021002',10,2,25,73,98,'O',10,'Published'),
  (31,'CSE2021002',11,3,22,67,89,'A+',9,'Published'),
  (32,'CSE2021002',12,3,21,64,85,'A+',9,'Published'),
  (33,'CSE2021002',13,3,23,75,98,'O',10,'Published'),
  (34,'CSE2021002',14,3,21,66,87,'A+',9,'Published'),
  (35,'CSE2021002',15,3,22,75,97,'O',10,'Published'),
  (36,'CSE2021002',16,4,24,66,90,'O',10,'Published'),
  (37,'CSE2021002',17,4,21,68,89,'A+',9,'Published'),
  (38,'CSE2021002',18,4,21,72,93,'O',10,'Published'),
  (39,'CSE2021002',19,4,25,73,98,'O',10,'Published'),
  (40,'CSE2021002',20,4,25,73,98,'O',10,'Published'),
  (41,'CSE2021003',1,1,21,54,75,'A',8,'Published'),
  (42,'CSE2021003',2,1,16,42,58,'B',6,'Published'),
  (43,'CSE2021003',3,1,17,58,75,'A',8,'Published'),
  (44,'CSE2021003',4,1,19,53,72,'A',8,'Published'),
  (45,'CSE2021003',5,1,17,54,71,'A',8,'Published'),
  (46,'CSE2021003',6,2,18,53,71,'A',8,'Published'),
  (47,'CSE2021003',7,2,17,46,63,'B+',7,'Published'),
  (48,'CSE2021003',8,2,17,56,73,'A',8,'Published'),
  (49,'CSE2021003',9,2,18,53,71,'A',8,'Published'),
  (50,'CSE2021003',10,2,18,45,63,'B+',7,'Published'),
  (51,'CSE2021003',11,3,18,53,71,'A',8,'Published'),
  (52,'CSE2021003',12,3,13,47,60,'B+',7,'Published'),
  (53,'CSE2021003',13,3,19,50,69,'B+',7,'Published'),
  (54,'CSE2021003',14,3,17,50,67,'B+',7,'Published'),
  (55,'CSE2021003',15,3,17,51,68,'B+',7,'Published'),
  (56,'CSE2021003',16,4,14,50,64,'B+',7,'Draft'),
  (57,'CSE2021003',17,4,21,59,80,'A+',9,'Draft'),
  (58,'CSE2021003',18,4,16,47,63,'B+',7,'Draft'),
  (59,'CSE2021003',19,4,22,58,80,'A+',9,'Draft'),
  (60,'CSE2021003',20,4,17,50,67,'B+',7,'Draft'),
  (61,'AID2021004',21,1,22,58,80,'A+',9,'Published'),
  (62,'AID2021004',22,1,21,63,84,'A+',9,'Published'),
  (63,'AID2021004',23,1,20,54,74,'A',8,'Published'),
  (64,'AID2021004',24,1,23,62,85,'A+',9,'Published'),
  (65,'AID2021004',25,1,21,56,77,'A',8,'Published'),
  (66,'AID2021004',26,2,20,68,88,'A+',9,'Published'),
  (67,'AID2021004',27,2,18,56,74,'A',8,'Published'),
  (68,'AID2021004',28,2,22,63,85,'A+',9,'Published'),
  (69,'AID2021004',29,2,18,61,79,'A',8,'Published'),
  (70,'AID2021004',30,2,19,57,76,'A',8,'Published'),
  (71,'AID2021004',31,3,20,62,82,'A+',9,'Published'),
  (72,'AID2021004',32,3,20,56,76,'A',8,'Published'),
  (73,'AID2021004',33,3,22,69,91,'O',10,'Published'),
  (74,'AID2021004',34,3,24,63,87,'A+',9,'Published'),
  (75,'AID2021004',35,3,22,64,86,'A+',9,'Published'),
  (76,'AID2021004',36,4,18,61,79,'A',8,'Published'),
  (77,'AID2021004',37,4,20,66,86,'A+',9,'Published'),
  (78,'AID2021004',38,4,20,58,78,'A',8,'Published'),
  (79,'AID2021004',39,4,24,68,92,'O',10,'Published'),
  (80,'AID2021004',40,4,18,57,75,'A',8,'Published'),
  (81,'ECE2021005',41,1,10,35,45,'C',5,'Published'),
  (82,'ECE2021005',42,1,14,44,58,'B',6,'Published'),
  (83,'ECE2021005',43,1,14,48,62,'B+',7,'Published'),
  (84,'ECE2021005',44,1,14,34,48,'C',5,'Published'),
  (85,'ECE2021005',45,1,10,38,48,'C',5,'Published'),
  (86,'ECE2021005',46,2,12,44,56,'B',6,'Published'),
  (87,'ECE2021005',47,2,9,26,35,'F',0,'Published'),
  (88,'ECE2021005',48,2,14,48,62,'B+',7,'Published'),
  (89,'ECE2021005',49,2,14,47,61,'B+',7,'Published'),
  (90,'ECE2021005',50,2,15,49,64,'B+',7,'Published'),
  (91,'ECE2021005',51,3,17,42,59,'B',6,'Published'),
  (92,'ECE2021005',52,3,17,47,64,'B+',7,'Published'),
  (93,'ECE2021005',53,3,15,42,57,'B',6,'Published'),
  (94,'ECE2021005',54,3,14,35,49,'C',5,'Published'),
  (95,'ECE2021005',55,3,13,35,48,'C',5,'Published'),
  (96,'EEE2021006',61,1,18,48,66,'B+',7,'Published'),
  (97,'EEE2021006',62,1,22,59,81,'A+',9,'Published'),
  (98,'EEE2021006',63,1,18,61,79,'A',8,'Published'),
  (99,'EEE2021006',64,1,20,58,78,'A',8,'Published'),
  (100,'EEE2021006',65,1,18,46,64,'B+',7,'Published'),
  (101,'EEE2021006',66,2,17,55,72,'A',8,'Published'),
  (102,'EEE2021006',67,2,19,49,68,'B+',7,'Published'),
  (103,'EEE2021006',68,2,17,56,73,'A',8,'Published'),
  (104,'EEE2021006',69,2,15,52,67,'B+',7,'Published'),
  (105,'EEE2021006',70,2,20,53,73,'A',8,'Published'),
  (106,'EEE2021006',71,3,16,54,70,'A',8,'Published'),
  (107,'EEE2021006',72,3,20,59,79,'A',8,'Published'),
  (108,'EEE2021006',73,3,18,62,80,'A+',9,'Published'),
  (109,'EEE2021006',74,3,20,54,74,'A',8,'Published'),
  (110,'EEE2021006',75,3,20,55,75,'A',8,'Published');

-- semester summary (SGPA / CGPA / percentage)
INSERT INTO `semesters` (`id`,`student_id`,`semester`,`sgpa`,`cgpa`,`percentage`) VALUES
  (1,'CSE2021001',1,8.69,8.69,83.00),
  (2,'CSE2021001',2,9.12,8.91,84.80),
  (3,'CSE2021001',3,9.75,9.19,92.60),
  (4,'CSE2021001',4,9.56,9.28,89.80),
  (5,'CSE2021002',1,9.62,9.62,90.60),
  (6,'CSE2021002',2,9.50,9.56,91.40),
  (7,'CSE2021002',3,9.31,9.48,91.20),
  (8,'CSE2021002',4,9.75,9.55,93.60),
  (9,'CSE2021003',1,7.50,7.50,70.20),
  (10,'CSE2021003',2,7.62,7.56,68.20),
  (11,'CSE2021003',3,7.25,7.46,67.00),
  (12,'CSE2021003',4,7.88,7.56,70.80),
  (13,'AID2021004',1,8.69,8.69,80.00),
  (14,'AID2021004',2,8.44,8.56,80.40),
  (15,'AID2021004',3,8.94,8.69,84.40),
  (16,'AID2021004',4,8.62,8.67,82.00),
  (17,'ECE2021005',1,5.62,5.62,52.20),
  (18,'ECE2021005',2,5.00,5.31,55.60),
  (19,'ECE2021005',3,5.94,5.52,55.40),
  (20,'EEE2021006',1,7.88,7.88,73.60),
  (21,'EEE2021006',2,7.56,7.72,70.60),
  (22,'EEE2021006',3,8.19,7.88,75.60);

-- End of file