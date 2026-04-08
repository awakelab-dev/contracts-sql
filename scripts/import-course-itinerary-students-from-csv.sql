-- Import course_itinerary_students relation from:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Cursos-Alumnos).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-course-itinerary-students-from-csv.sql
USE contracts_app;

DROP TABLE IF EXISTS course_itinerary_students;
CREATE TABLE course_itinerary_students (
  course_code VARCHAR(50) NOT NULL,
  expediente VARCHAR(64) NOT NULL,
  dni_nie VARCHAR(50) NOT NULL,
  PRIMARY KEY (expediente),
  INDEX idx_course_itinerary_students_course_code (course_code),
  INDEX idx_course_itinerary_students_dni_nie (dni_nie),
  CONSTRAINT fk_course_itinerary_students_course_code
    FOREIGN KEY (course_code) REFERENCES course_itineraries(course_code)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_course_itinerary_students_dni_nie
    FOREIGN KEY (dni_nie) REFERENCES students(dni_nie)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TEMPORARY TABLE IF EXISTS tmp_course_itinerary_students_stage;
CREATE TEMPORARY TABLE tmp_course_itinerary_students_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  course_code_raw TEXT NULL,
  expediente_raw TEXT NULL,
  dni_nie_raw TEXT NULL
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Cursos-Alumnos).csv'
INTO TABLE tmp_course_itinerary_students_stage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  course_code_raw,
  expediente_raw,
  dni_nie_raw
);

DROP TEMPORARY TABLE IF EXISTS tmp_course_itinerary_students_normalized;
CREATE TEMPORARY TABLE tmp_course_itinerary_students_normalized AS
SELECT
  row_id,
  UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(course_code_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS course_code,
  UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(expediente_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS expediente,
  UPPER(REPLACE(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(dni_nie_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), ''), ' ', '')) AS dni_nie
FROM tmp_course_itinerary_students_stage
WHERE NULLIF(TRIM(course_code_raw), '') IS NOT NULL
  AND NULLIF(TRIM(expediente_raw), '') IS NOT NULL
  AND NULLIF(TRIM(dni_nie_raw), '') IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_course_itinerary_students_clean;
CREATE TEMPORARY TABLE tmp_course_itinerary_students_clean AS
SELECT
  ranked.course_code,
  ranked.expediente,
  ranked.dni_nie
FROM (
  SELECT
    n.*,
    ROW_NUMBER() OVER (PARTITION BY n.expediente ORDER BY n.row_id DESC) AS rn
  FROM tmp_course_itinerary_students_normalized n
) AS ranked
WHERE ranked.rn = 1;

INSERT INTO course_itinerary_students (course_code, expediente, dni_nie)
SELECT
  t.course_code,
  t.expediente,
  s.dni_nie
FROM tmp_course_itinerary_students_clean t
INNER JOIN course_itineraries ci ON ci.course_code = t.course_code
INNER JOIN students s ON s.dni_nie = t.dni_nie
ORDER BY t.course_code, t.expediente;

SELECT COUNT(*) AS csv_rows
FROM tmp_course_itinerary_students_stage;

SELECT COUNT(*) AS normalized_rows
FROM tmp_course_itinerary_students_normalized;

SELECT COUNT(*) AS duplicate_expedientes
FROM (
  SELECT expediente
  FROM tmp_course_itinerary_students_normalized
  GROUP BY expediente
  HAVING COUNT(*) > 1
) duplicates;

SELECT COUNT(*) AS missing_courses
FROM tmp_course_itinerary_students_clean t
LEFT JOIN course_itineraries ci ON ci.course_code = t.course_code
WHERE ci.course_code IS NULL;

SELECT COUNT(*) AS missing_students
FROM tmp_course_itinerary_students_clean t
LEFT JOIN students s ON s.dni_nie = t.dni_nie
WHERE s.dni_nie IS NULL;

SELECT COUNT(*) AS inserted_rows
FROM course_itinerary_students;
