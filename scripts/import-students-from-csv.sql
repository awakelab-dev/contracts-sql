-- Import students from:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Alumnos).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-students-from-csv.sql

USE contracts_app;

SET @has_expediente := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'students'
    AND column_name = 'expediente'
);
SET @sql := IF(
  @has_expediente = 0,
  'ALTER TABLE students ADD COLUMN expediente VARCHAR(64) NULL AFTER id',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_age := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'students'
    AND column_name = 'age'
);
SET @sql := IF(
  @has_age = 0,
  'ALTER TABLE students ADD COLUMN age SMALLINT UNSIGNED NULL AFTER birth_date',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_sex := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'students'
    AND column_name = 'sex'
);
SET @sql := IF(
  @has_sex = 0,
  'ALTER TABLE students ADD COLUMN sex ENUM(''mujer'',''hombre'',''other'',''unknown'') NOT NULL DEFAULT ''unknown'' AFTER age',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_district_code := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'students'
    AND column_name = 'district_code'
);
SET @sql := IF(
  @has_district_code = 0,
  'ALTER TABLE students ADD COLUMN district_code INT UNSIGNED NULL AFTER sex',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_municipality_code := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'students'
    AND column_name = 'municipality_code'
);
SET @sql := IF(
  @has_municipality_code = 0,
  'ALTER TABLE students ADD COLUMN municipality_code INT UNSIGNED NULL AFTER district_code',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS municipalities (
  code INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  PRIMARY KEY (code),
  UNIQUE KEY uq_municipalities_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS districts (
  code INT UNSIGNED NOT NULL,
  municipality_code INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  PRIMARY KEY (code),
  UNIQUE KEY uq_districts_municipality_name (municipality_code, name),
  INDEX idx_districts_municipality_code (municipality_code),
  CONSTRAINT fk_districts_municipality_code
    FOREIGN KEY (municipality_code) REFERENCES municipalities(code)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

UPDATE students
SET expediente = CONCAT('LEGACY-', LPAD(id, 6, '0'))
WHERE expediente IS NULL OR TRIM(expediente) = '';

ALTER TABLE students
  MODIFY COLUMN expediente VARCHAR(64) NOT NULL;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'students'
    AND index_name = 'uq_students_expediente'
);
SET @create_idx_sql := IF(
  @idx_exists = 0,
  'CREATE UNIQUE INDEX uq_students_expediente ON students (expediente)',
  'SELECT 1'
);
PREPARE create_idx_stmt FROM @create_idx_sql;
EXECUTE create_idx_stmt;
DEALLOCATE PREPARE create_idx_stmt;

CREATE TABLE IF NOT EXISTS students_import_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  expediente_raw TEXT NULL,
  first_names_raw TEXT NULL,
  last_names_raw TEXT NULL,
  birth_date_raw TEXT NULL,
  age_raw TEXT NULL,
  sex_raw TEXT NULL,
  dni_nie_raw TEXT NULL,
  phone_raw TEXT NULL,
  email_raw TEXT NULL,
  notes_raw TEXT NULL,
  district_raw TEXT NULL,
  municipality_raw TEXT NULL,
  social_security_number_raw TEXT NULL
) ENGINE=InnoDB;

TRUNCATE TABLE students_import_stage;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Alumnos).csv'
INTO TABLE students_import_stage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  expediente_raw,
  first_names_raw,
  last_names_raw,
  birth_date_raw,
  age_raw,
  sex_raw,
  dni_nie_raw,
  phone_raw,
  email_raw,
  notes_raw,
  district_raw,
  municipality_raw,
  social_security_number_raw
);

DROP TEMPORARY TABLE IF EXISTS tmp_students_base;

CREATE TEMPORARY TABLE tmp_students_base AS
WITH cleaned AS (
  SELECT
    row_id,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(expediente_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS expediente,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(first_names_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS first_names,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(last_names_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS last_names,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(birth_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS birth_date_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(age_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS age_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(sex_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS sex_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(dni_nie_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS dni_nie_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS phone_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(email_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS email_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(notes_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS notes_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(district_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS district_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(municipality_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS municipality_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(social_security_number_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), CHAR(160), ' '), '[[:space:]]+', ' ')), '') AS social_security_number_raw
  FROM students_import_stage
),
normalized AS (
  SELECT
    row_id,
    UPPER(expediente) AS expediente,
    first_names,
    last_names,
    CASE
      WHEN birth_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(birth_date_raw, '%Y-%m-%d')
      WHEN birth_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
        STR_TO_DATE(birth_date_raw, '%m/%e/%Y'),
        STR_TO_DATE(birth_date_raw, '%e/%m/%Y')
      )
      ELSE NULL
    END AS birth_date,
    CASE
      WHEN age_raw REGEXP '^[0-9]{1,3}$' AND CAST(age_raw AS UNSIGNED) BETWEEN 1 AND 120 THEN CAST(age_raw AS UNSIGNED)
      ELSE NULL
    END AS age,
    CASE
      WHEN LOWER(sex_raw) IN ('mujer', 'female', 'f') THEN 'mujer'
      WHEN LOWER(sex_raw) IN ('hombre', 'male', 'm') THEN 'hombre'
      WHEN LOWER(sex_raw) IN ('other', 'otro', 'otra', 'no-binario', 'no binario', 'non-binary') THEN 'other'
      ELSE 'unknown'
    END AS sex,
    UPPER(REPLACE(dni_nie_raw, ' ', '')) AS dni_nie,
    phone_raw AS phone,
    LOWER(email_raw) AS email,
    notes_raw AS notes,
    district_raw AS district,
    municipality_raw AS municipality,
    social_security_number_raw AS social_security_number
  FROM cleaned
),
dedupe_doc AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY dni_nie ORDER BY row_id DESC) AS rn_doc
  FROM normalized
  WHERE expediente IS NOT NULL
    AND first_names IS NOT NULL
    AND last_names IS NOT NULL
    AND dni_nie IS NOT NULL
),
dedupe_expediente AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY expediente ORDER BY row_id DESC) AS rn_expediente
  FROM dedupe_doc
  WHERE rn_doc = 1
)
SELECT
  expediente,
  first_names,
  last_names,
  dni_nie,
  social_security_number,
  birth_date,
  age,
  sex,
  district,
  municipality,
  phone,
  email,
  notes
FROM dedupe_expediente
WHERE rn_expediente = 1;

SET @next_municipality_code := (SELECT COALESCE(MAX(code), 0) FROM municipalities);

INSERT INTO municipalities (code, name)
SELECT
  @next_municipality_code := @next_municipality_code + 1 AS code,
  src.name
FROM (
  SELECT DISTINCT municipality AS name
  FROM tmp_students_base
  WHERE municipality IS NOT NULL
) AS src
LEFT JOIN municipalities m ON m.name = src.name
WHERE m.code IS NULL
ORDER BY src.name;

SET @next_district_code := (SELECT COALESCE(MAX(code), 0) FROM districts);

INSERT INTO districts (code, municipality_code, name)
SELECT
  @next_district_code := @next_district_code + 1 AS code,
  src.municipality_code,
  src.name
FROM (
  SELECT DISTINCT
    m.code AS municipality_code,
    b.district AS name
  FROM tmp_students_base b
  JOIN municipalities m ON m.name = b.municipality
  WHERE b.district IS NOT NULL
    AND b.municipality IS NOT NULL
) AS src
LEFT JOIN districts d
  ON d.municipality_code = src.municipality_code
 AND d.name = src.name
WHERE d.code IS NULL
ORDER BY src.municipality_code, src.name;

DROP TEMPORARY TABLE IF EXISTS tmp_students_import;

CREATE TEMPORARY TABLE tmp_students_import AS
SELECT
  b.expediente,
  b.first_names,
  b.last_names,
  b.dni_nie,
  b.social_security_number,
  b.birth_date,
  b.age,
  b.sex,
  d.code AS district_code,
  m.code AS municipality_code,
  b.phone,
  b.email,
  b.notes
FROM tmp_students_base b
LEFT JOIN municipalities m
  ON m.name = b.municipality
LEFT JOIN districts d
  ON d.municipality_code = m.code
 AND d.name = b.district;

INSERT INTO students (
  expediente,
  first_names,
  last_names,
  dni_nie,
  social_security_number,
  birth_date,
  age,
  sex,
  district_code,
  municipality_code,
  phone,
  email,
  notes
)
SELECT
  expediente,
  first_names,
  last_names,
  dni_nie,
  social_security_number,
  birth_date,
  age,
  sex,
  district_code,
  municipality_code,
  phone,
  email,
  notes
FROM tmp_students_import
ON DUPLICATE KEY UPDATE
  first_names = VALUES(first_names),
  last_names = VALUES(last_names),
  social_security_number = VALUES(social_security_number),
  birth_date = VALUES(birth_date),
  age = VALUES(age),
  sex = VALUES(sex),
  district_code = VALUES(district_code),
  municipality_code = VALUES(municipality_code),
  phone = VALUES(phone),
  email = VALUES(email),
  notes = VALUES(notes);

SELECT
  (SELECT COUNT(*) FROM students_import_stage) AS staged_rows,
  (SELECT COUNT(*) FROM municipalities) AS municipalities_total,
  (SELECT COUNT(*) FROM districts) AS districts_total,
  (SELECT COUNT(*) FROM students) AS students_total;
