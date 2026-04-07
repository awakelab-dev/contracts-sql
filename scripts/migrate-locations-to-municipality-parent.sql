-- One-time migration for existing databases that still use:
-- districts(code VARCHAR, name)
-- municipalities(code VARCHAR, district_code VARCHAR, name)
-- students.{district_code, municipality_code} as VARCHAR FKs.
--
-- Target model:
-- municipalities(code INT, name UNIQUE)
-- districts(code INT, municipality_code INT, name)
-- students.{district_code, municipality_code} as INT FKs.

USE contracts_app;

SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS _municipality_name_map;
DROP TABLE IF EXISTS _municipality_code_map;
DROP TABLE IF EXISTS _district_pair_map;
DROP TABLE IF EXISTS _district_unique_map;
DROP TABLE IF EXISTS _students_location_map;
DROP TABLE IF EXISTS municipalities_new;
DROP TABLE IF EXISTS districts_new;

CREATE TABLE _municipality_name_map AS
SELECT
  src.name,
  ROW_NUMBER() OVER (ORDER BY src.name) AS new_code
FROM (
  SELECT DISTINCT name
  FROM municipalities
) AS src;

CREATE TABLE _municipality_code_map AS
SELECT
  old_m.code AS old_code,
  map.new_code
FROM municipalities old_m
JOIN _municipality_name_map map
  ON map.name = old_m.name;

CREATE TABLE _district_pair_map AS
SELECT
  m.code AS old_municipality_code,
  d.code AS old_district_code,
  d.name AS district_name,
  cm.new_code AS municipality_new_code,
  ROW_NUMBER() OVER (ORDER BY cm.new_code, d.name, m.code) AS new_code
FROM municipalities m
JOIN districts d
  ON d.code = m.district_code
JOIN _municipality_code_map cm
  ON cm.old_code = m.code;

CREATE TABLE _district_unique_map AS
SELECT
  old_district_code,
  MIN(new_code) AS new_code,
  COUNT(*) AS pair_count
FROM _district_pair_map
GROUP BY old_district_code;

CREATE TABLE _students_location_map AS
SELECT
  s.id AS student_id,
  cm.new_code AS municipality_new_code,
  COALESCE(
    d_exact.new_code,
    d_from_municipality.new_code,
    CASE WHEN du.pair_count = 1 THEN du.new_code ELSE NULL END
  ) AS district_new_code
FROM students s
LEFT JOIN _municipality_code_map cm
  ON cm.old_code = s.municipality_code
LEFT JOIN _district_pair_map d_exact
  ON d_exact.old_district_code = s.district_code
 AND d_exact.old_municipality_code = s.municipality_code
LEFT JOIN _district_pair_map d_from_municipality
  ON d_from_municipality.old_municipality_code = s.municipality_code
LEFT JOIN _district_unique_map du
  ON du.old_district_code = s.district_code;

CREATE TABLE municipalities_new (
  code INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  PRIMARY KEY (code),
  UNIQUE KEY uq_municipalities_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO municipalities_new (code, name)
SELECT new_code, name
FROM _municipality_name_map
ORDER BY new_code;

CREATE TABLE districts_new (
  code INT UNSIGNED NOT NULL,
  municipality_code INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  PRIMARY KEY (code),
  UNIQUE KEY uq_districts_municipality_name (municipality_code, name),
  KEY idx_districts_municipality_code (municipality_code),
  CONSTRAINT fk_districts_municipality_code
    FOREIGN KEY (municipality_code) REFERENCES municipalities_new(code)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO districts_new (code, municipality_code, name)
SELECT
  new_code,
  municipality_new_code,
  district_name
FROM _district_pair_map
ORDER BY new_code;

ALTER TABLE students
  DROP FOREIGN KEY fk_students_municipality_code,
  DROP FOREIGN KEY fk_students_district_code;

ALTER TABLE students
  ADD COLUMN municipality_code_new INT UNSIGNED NULL AFTER municipality_code,
  ADD COLUMN district_code_new INT UNSIGNED NULL AFTER district_code;

UPDATE students s
JOIN _students_location_map map
  ON map.student_id = s.id
SET
  s.municipality_code_new = map.municipality_new_code,
  s.district_code_new = map.district_new_code;

ALTER TABLE students
  DROP COLUMN municipality_code,
  DROP COLUMN district_code,
  CHANGE COLUMN municipality_code_new municipality_code INT UNSIGNED NULL,
  CHANGE COLUMN district_code_new district_code INT UNSIGNED NULL;

ALTER TABLE students
  ADD INDEX idx_students_municipality_code (municipality_code),
  ADD INDEX idx_students_district_code (district_code);

DROP TABLE municipalities;
DROP TABLE districts;

RENAME TABLE
  municipalities_new TO municipalities,
  districts_new TO districts;

ALTER TABLE students
  ADD CONSTRAINT fk_students_municipality_code
    FOREIGN KEY (municipality_code) REFERENCES municipalities(code)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  ADD CONSTRAINT fk_students_district_code
    FOREIGN KEY (district_code) REFERENCES districts(code)
    ON UPDATE CASCADE
    ON DELETE SET NULL;

DROP TABLE _students_location_map;
DROP TABLE _district_unique_map;
DROP TABLE _district_pair_map;
DROP TABLE _municipality_code_map;
DROP TABLE _municipality_name_map;

SET FOREIGN_KEY_CHECKS=1;

SELECT
  (SELECT COUNT(*) FROM municipalities) AS municipalities_total,
  (SELECT COUNT(*) FROM districts) AS districts_total,
  (SELECT COUNT(*) FROM students WHERE municipality_code IS NOT NULL) AS students_with_municipality,
  (SELECT COUNT(*) FROM students WHERE district_code IS NOT NULL) AS students_with_district,
  (SELECT COUNT(*)
   FROM students s
   LEFT JOIN districts d ON d.code = s.district_code
   WHERE s.district_code IS NOT NULL AND d.code IS NULL) AS district_fk_mismatches,
  (SELECT COUNT(*)
   FROM students s
   LEFT JOIN municipalities m ON m.code = s.municipality_code
   WHERE s.municipality_code IS NOT NULL AND m.code IS NULL) AS municipality_fk_mismatches,
  (SELECT COUNT(*)
   FROM students s
   JOIN districts d ON d.code = s.district_code
   WHERE s.municipality_code IS NOT NULL AND d.municipality_code <> s.municipality_code) AS hierarchy_mismatches;
