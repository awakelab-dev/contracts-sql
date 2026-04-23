-- Import students from:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Alumnos).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-students-from-csv.sql

USE contracts_app;
DROP FUNCTION IF EXISTS normalize_spanish_place_name;
DELIMITER $$
CREATE FUNCTION normalize_spanish_place_name(input_text VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE normalized VARCHAR(255) DEFAULT '';
  DECLARE work VARCHAR(255);
  DECLARE token VARCHAR(255);
  DECLARE token_norm VARCHAR(255);
  DECLARE token_part VARCHAR(255);
  DECLARE word_idx INT DEFAULT 0;
  DECLARE space_pos INT;
  DECLARE hyphen_pos INT;

  IF input_text IS NULL THEN
    RETURN NULL;
  END IF;

  SET work = LOWER(TRIM(REGEXP_REPLACE(input_text, '[[:space:]]+', ' ')));
  SET work = REGEXP_REPLACE(work, '[[:space:]]*-[[:space:]]*', '-');
  IF work = '' THEN
    RETURN NULL;
  END IF;

  IF work IN ('-', '--', 'n/d', 'n.d.', 'nd', 's/d') THEN
    RETURN 'N/D';
  END IF;

  WHILE CHAR_LENGTH(work) > 0 DO
    SET space_pos = LOCATE(' ', work);
    IF space_pos = 0 THEN
      SET token = work;
      SET work = '';
    ELSE
      SET token = SUBSTRING(work, 1, space_pos - 1);
      SET work = SUBSTRING(work, space_pos + 1);
    END IF;

    SET word_idx = word_idx + 1;

    IF token IN ('n/d', 'n.d.', 'nd', 's/d') THEN
      SET token_norm = 'N/D';
    ELSEIF word_idx > 1 AND token IN ('de', 'del', 'la', 'las', 'los', 'y', 'e', 'el', 'al') THEN
      SET token_norm = token;
    ELSE
      SET token_norm = '';
      WHILE CHAR_LENGTH(token) > 0 DO
        SET hyphen_pos = LOCATE('-', token);
        IF hyphen_pos = 0 THEN
          SET token_part = token;
          SET token = '';
        ELSE
          SET token_part = SUBSTRING(token, 1, hyphen_pos - 1);
          SET token = SUBSTRING(token, hyphen_pos + 1);
        END IF;

        IF token_part <> '' THEN
          SET token_part = CONCAT(UPPER(LEFT(token_part, 1)), SUBSTRING(token_part, 2));
        END IF;

        IF token_norm = '' THEN
          SET token_norm = token_part;
        ELSE
          SET token_norm = CONCAT(token_norm, '-', token_part);
        END IF;
      END WHILE;
    END IF;

    IF normalized = '' THEN
      SET normalized = token_norm;
    ELSE
      SET normalized = CONCAT(normalized, ' ', token_norm);
    END IF;
  END WHILE;

  RETURN normalized;
END$$
DELIMITER ;

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

CREATE TABLE IF NOT EXISTS students (
  dni_nie VARCHAR(50) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  first_names VARCHAR(190) NOT NULL,
  last_names VARCHAR(190) NOT NULL,
  social_security_number VARCHAR(50) NULL,
  birth_date DATE NULL,
  sex ENUM('mujer','hombre','other','unknown') NOT NULL DEFAULT 'unknown',
  district_code INT UNSIGNED NULL,
  municipality_code INT UNSIGNED NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(190) NULL,
  tic VARCHAR(3) NOT NULL DEFAULT 'NO',
  status_laboral VARCHAR(40) NULL,
  notes TEXT NULL,
  PRIMARY KEY (dni_nie),
  UNIQUE KEY uq_students_id (id),
  INDEX idx_students_district_code (district_code),
  INDEX idx_students_municipality_code (municipality_code),
  CONSTRAINT fk_students_district_code
    FOREIGN KEY (district_code) REFERENCES districts(code)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_students_municipality_code
    FOREIGN KEY (municipality_code) REFERENCES municipalities(code)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS students_import_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  dni_nie_raw TEXT NULL,
  first_names_raw TEXT NULL,
  last_names_raw TEXT NULL,
  birth_date_raw TEXT NULL,
  sex_raw TEXT NULL,
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
IGNORE 2 LINES
(
  dni_nie_raw,
  first_names_raw,
  last_names_raw,
  birth_date_raw,
  sex_raw,
  phone_raw,
  email_raw,
  @sharepoint_link_raw,
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
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(dni_nie_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS dni_nie_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(first_names_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS first_names,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(last_names_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS last_names,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(birth_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS birth_date_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(sex_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS sex_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(phone_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS phone_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(email_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS email_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(notes_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS notes_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(district_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS district_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(municipality_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS municipality_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(social_security_number_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS social_security_number_raw
  FROM students_import_stage
),
normalized AS (
  SELECT
    row_id,
    first_names,
    last_names,
    UPPER(REPLACE(dni_nie_raw, ' ', '')) AS dni_nie,
    social_security_number_raw AS social_security_number,
    CASE
      WHEN birth_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(birth_date_raw, '%Y-%m-%d')
      WHEN birth_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
        STR_TO_DATE(birth_date_raw, '%m/%e/%Y'),
        STR_TO_DATE(birth_date_raw, '%e/%m/%Y')
      )
      ELSE NULL
    END AS birth_date,
    CASE
      WHEN LOWER(sex_raw) IN ('mujer', 'female', 'f') THEN 'mujer'
      WHEN LOWER(sex_raw) IN ('hombre', 'male', 'm') THEN 'hombre'
      WHEN LOWER(sex_raw) IN ('other', 'otro', 'otra', 'no-binario', 'no binario', 'non-binary') THEN 'other'
      ELSE 'unknown'
    END AS sex,
    phone_raw AS phone,
    LOWER(email_raw) AS email,
    notes_raw AS notes,
    normalize_spanish_place_name(district_raw) AS district,
    normalize_spanish_place_name(municipality_raw) AS municipality
  FROM cleaned
),
dedupe_doc AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY dni_nie ORDER BY row_id DESC) AS rn_doc
  FROM normalized
  WHERE first_names IS NOT NULL
    AND last_names IS NOT NULL
    AND dni_nie IS NOT NULL
)
SELECT
  first_names,
  last_names,
  dni_nie,
  social_security_number,
  birth_date,
  sex,
  district,
  municipality,
  phone,
  email,
  notes
FROM dedupe_doc
WHERE rn_doc = 1;

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
  b.dni_nie,
  b.first_names,
  b.last_names,
  b.social_security_number,
  b.birth_date,
  b.sex,
  d.code AS district_code,
  m.code AS municipality_code,
  b.phone,
  b.email,
  'NO' AS tic,
  NULL AS status_laboral,
  b.notes
FROM tmp_students_base b
LEFT JOIN municipalities m
  ON m.name = b.municipality
LEFT JOIN districts d
  ON d.municipality_code = m.code
 AND d.name = b.district;

INSERT INTO students (
  dni_nie,
  first_names,
  last_names,
  social_security_number,
  birth_date,
  sex,
  district_code,
  municipality_code,
  phone,
  email,
  tic,
  status_laboral,
  notes
)
SELECT
  dni_nie,
  first_names,
  last_names,
  social_security_number,
  birth_date,
  sex,
  district_code,
  municipality_code,
  phone,
  email,
  tic,
  status_laboral,
  notes
FROM tmp_students_import
ON DUPLICATE KEY UPDATE
  first_names = VALUES(first_names),
  last_names = VALUES(last_names),
  social_security_number = VALUES(social_security_number),
  birth_date = VALUES(birth_date),
  sex = VALUES(sex),
  district_code = VALUES(district_code),
  municipality_code = VALUES(municipality_code),
  phone = VALUES(phone),
  email = VALUES(email),
  tic = VALUES(tic),
  status_laboral = VALUES(status_laboral),
  notes = VALUES(notes);

SELECT
  (SELECT COUNT(*) FROM students_import_stage) AS staged_rows,
  (SELECT COUNT(*) FROM municipalities) AS municipalities_total,
  (SELECT COUNT(*) FROM districts) AS districts_total,
  (SELECT COUNT(*) FROM students) AS students_total;
