-- Import course itineraries from:
-- /Users/leonardobarreto/projects/contracts/Imports/CONTRATOS - DATOS EMPRESAS E CURSOS -APP(cursos).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-course-itineraries-from-csv.sql
USE contracts_app;

CREATE TABLE IF NOT EXISTS course_itineraries (
  course_code VARCHAR(50) NOT NULL,
  itinerary_name VARCHAR(190) NOT NULL,
  formation_start_date DATE NULL,
  formation_end_date DATE NULL,
  formation_schedule VARCHAR(120) NULL,
  company VARCHAR(190) NULL,
  teacher VARCHAR(190) NULL,
  PRIMARY KEY (course_code)
) ENGINE=InnoDB;

SET @formation_start_date_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'course_itineraries'
    AND COLUMN_NAME = 'formation_start_date'
);
SET @ddl := IF(
  @formation_start_date_exists = 0,
  'ALTER TABLE course_itineraries ADD COLUMN formation_start_date DATE NULL AFTER itinerary_name',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @formation_end_date_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'course_itineraries'
    AND COLUMN_NAME = 'formation_end_date'
);
SET @ddl := IF(
  @formation_end_date_exists = 0,
  'ALTER TABLE course_itineraries ADD COLUMN formation_end_date DATE NULL AFTER formation_start_date',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @formation_schedule_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'course_itineraries'
    AND COLUMN_NAME = 'formation_schedule'
);
SET @ddl := IF(
  @formation_schedule_exists = 0,
  'ALTER TABLE course_itineraries ADD COLUMN formation_schedule VARCHAR(120) NULL AFTER formation_end_date',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @company_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'course_itineraries'
    AND COLUMN_NAME = 'company'
);
SET @ddl := IF(
  @company_exists = 0,
  'ALTER TABLE course_itineraries ADD COLUMN company VARCHAR(190) NULL AFTER formation_schedule',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @teacher_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'course_itineraries'
    AND COLUMN_NAME = 'teacher'
);
SET @ddl := IF(
  @teacher_exists = 0,
  'ALTER TABLE course_itineraries ADD COLUMN teacher VARCHAR(190) NULL AFTER company',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TEMPORARY TABLE IF EXISTS tmp_course_itineraries_stage;
CREATE TEMPORARY TABLE tmp_course_itineraries_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  course_code_raw TEXT NULL,
  itinerary_name_raw TEXT NULL,
  formation_start_date_raw TEXT NULL,
  formation_end_date_raw TEXT NULL,
  formation_schedule_raw TEXT NULL,
  company_raw TEXT NULL,
  teacher_raw TEXT NULL
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/CONTRATOS - DATOS EMPRESAS E CURSOS -APP(cursos).csv'
INTO TABLE tmp_course_itineraries_stage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  course_code_raw,
  itinerary_name_raw,
  formation_start_date_raw,
  formation_end_date_raw,
  formation_schedule_raw,
  company_raw,
  teacher_raw
);

DROP TEMPORARY TABLE IF EXISTS tmp_course_itineraries_normalized;
CREATE TEMPORARY TABLE tmp_course_itineraries_normalized AS
SELECT
  src.row_id,
  src.course_code,
  src.itinerary_name,
  CASE
    WHEN src.formation_start_date_raw IS NULL THEN NULL
    WHEN src.formation_start_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(src.formation_start_date_raw, '%Y-%m-%d')
    WHEN src.formation_start_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
      STR_TO_DATE(src.formation_start_date_raw, '%m/%e/%Y'),
      STR_TO_DATE(src.formation_start_date_raw, '%e/%m/%Y')
    )
    ELSE NULL
  END AS formation_start_date,
  CASE
    WHEN src.formation_end_date_raw IS NULL THEN NULL
    WHEN src.formation_end_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(src.formation_end_date_raw, '%Y-%m-%d')
    WHEN src.formation_end_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
      STR_TO_DATE(src.formation_end_date_raw, '%m/%e/%Y'),
      STR_TO_DATE(src.formation_end_date_raw, '%e/%m/%Y')
    )
    ELSE NULL
  END AS formation_end_date,
  src.formation_schedule,
  src.company,
  src.teacher
FROM (
  SELECT
    row_id,
    UPPER(
      REPLACE(
        NULLIF(
          TRIM(
            REGEXP_REPLACE(
              REPLACE(REPLACE(REPLACE(course_code_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
              '[[:space:]]+',
              ' '
            )
          ),
          ''
        ),
        ' ',
        ''
      )
    ) AS course_code,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REPLACE(REPLACE(REPLACE(itinerary_name_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
            '[[:space:]]+',
            ' '
          )
        ),
        ''
      )
    ) AS itinerary_name,
    NULLIF(
      TRIM(
        REGEXP_REPLACE(
          REPLACE(REPLACE(REPLACE(formation_start_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
          '[[:space:]]+',
          ' '
        )
      ),
      ''
    ) AS formation_start_date_raw,
    NULLIF(
      TRIM(
        REGEXP_REPLACE(
          REPLACE(REPLACE(REPLACE(formation_end_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
          '[[:space:]]+',
          ' '
        )
      ),
      ''
    ) AS formation_end_date_raw,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REPLACE(REPLACE(REPLACE(formation_schedule_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
            '[[:space:]]+',
            ' '
          )
        ),
        ''
      )
    ) AS formation_schedule,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REPLACE(REPLACE(REPLACE(company_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
            '[[:space:]]+',
            ' '
          )
        ),
        ''
      )
    ) AS company,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REPLACE(REPLACE(REPLACE(teacher_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
            '[[:space:]]+',
            ' '
          )
        ),
        ''
      )
    ) AS teacher
  FROM tmp_course_itineraries_stage
) src
WHERE src.course_code IS NOT NULL
  AND src.itinerary_name IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_course_itineraries_clean;
CREATE TEMPORARY TABLE tmp_course_itineraries_clean AS
SELECT
  ranked.course_code,
  ranked.itinerary_name,
  ranked.formation_start_date,
  ranked.formation_end_date,
  ranked.formation_schedule,
  ranked.company,
  ranked.teacher
FROM (
  SELECT
    n.course_code,
    n.itinerary_name,
    n.formation_start_date,
    n.formation_end_date,
    n.formation_schedule,
    n.company,
    n.teacher,
    ROW_NUMBER() OVER (PARTITION BY n.course_code ORDER BY n.row_id DESC) AS rn
  FROM tmp_course_itineraries_normalized n
) ranked
WHERE ranked.rn = 1;

INSERT INTO course_itineraries (
  course_code,
  itinerary_name,
  formation_start_date,
  formation_end_date,
  formation_schedule,
  company,
  teacher
)
SELECT
  c.course_code,
  c.itinerary_name,
  c.formation_start_date,
  c.formation_end_date,
  c.formation_schedule,
  c.company,
  c.teacher
FROM tmp_course_itineraries_clean c
ON DUPLICATE KEY UPDATE
  itinerary_name = VALUES(itinerary_name),
  formation_start_date = VALUES(formation_start_date),
  formation_end_date = VALUES(formation_end_date),
  formation_schedule = VALUES(formation_schedule),
  company = VALUES(company),
  teacher = VALUES(teacher);

SELECT COUNT(*) AS csv_rows
FROM tmp_course_itineraries_stage;

SELECT COUNT(*) AS normalized_rows
FROM tmp_course_itineraries_normalized;

SELECT COUNT(*) AS duplicate_course_codes
FROM (
  SELECT course_code
  FROM tmp_course_itineraries_normalized
  GROUP BY course_code
  HAVING COUNT(*) > 1
) duplicates;

SELECT COUNT(*) AS imported_rows
FROM tmp_course_itineraries_clean;

SELECT COUNT(*) AS total_course_itineraries
FROM course_itineraries;

SELECT COUNT(*) AS courses_with_formation_start_date
FROM course_itineraries
WHERE formation_start_date IS NOT NULL;

SELECT COUNT(*) AS courses_with_formation_end_date
FROM course_itineraries
WHERE formation_end_date IS NOT NULL;

SELECT COUNT(*) AS courses_with_schedule
FROM course_itineraries
WHERE formation_schedule IS NOT NULL;

SELECT COUNT(*) AS courses_with_company
FROM course_itineraries
WHERE company IS NOT NULL;

SELECT COUNT(*) AS courses_with_teacher
FROM course_itineraries
WHERE teacher IS NOT NULL;
