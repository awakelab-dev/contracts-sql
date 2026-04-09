-- Import course itineraries from:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Cursos).csv
-- and enrich date from:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Atividad-Formativa-Fechas).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-course-itineraries-from-csv.sql
USE contracts_app;

CREATE TABLE IF NOT EXISTS course_itineraries (
  course_code VARCHAR(50) NOT NULL,
  itinerary_name VARCHAR(190) NOT NULL,
  formation_end_date DATE NULL,
  PRIMARY KEY (course_code)
) ENGINE=InnoDB;

SET @formation_end_date_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'course_itineraries'
    AND COLUMN_NAME = 'formation_end_date'
);
SET @ddl := IF(
  @formation_end_date_exists = 0,
  'ALTER TABLE course_itineraries ADD COLUMN formation_end_date DATE NULL AFTER itinerary_name',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO course_itineraries (course_code, itinerary_name)
VALUES
  ('25EMHA01','AYUDANTE DE CAMARERO'),
  ('25EMHA02','AYUDANTE DE COCINA'),
  ('25EMHA03','AYUDANTE DE COCINA'),
  ('25EMHA04','AYUDANTE DE COCINA'),
  ('25EMHA05','AYUDANTE DE CAMARERO'),
  ('25EMHA06','AYUDANTE DE COCINA'),
  ('25EMHA07','AYUDANTE DE COCINA'),
  ('25EMHA08','ATENCION AL CLIENTE EN BARRA Y TIENDA'),
  ('25EMHA09','CdP OPERACIONES BÁSICAS COCINA'),
  ('25EMHA10','COCINA AVANZADA'),
  ('25EMHA11','SERVICIO DE SALA ESPECIALIZADO'),
  ('25EMHA13','AYUDANTE DE CAMARERO'),
  ('25EMHA14','OPERARIO DE DESPIECE'),
  ('25EMHA15','AYUDANTE DE COCINA'),
  ('25EMHA16','AYUDANTE DE CATERING'),
  ('25EMHA17','OPERARIO DE CARNICERIA'),
  ('25EMHA18','OPERARIO DE PESCADERIA'),
  ('25EMHA20','AYUDANTE BARRA Y SALA PASTELERÍA'),
  ('25EMHA21','AYUDANTE DE COCINA'),
  ('25EMHA22','AYUDANTE DE COCINA'),
  ('25EMHA23','AYUDANTE BARRA PASTELERIA'),
  ('25EMHA24','AYUDANTE BARRA PASTELERIA'),
  ('25EMHA25','AYUDANTE CAMARERO'),
  ('25EMHA26','AYUDANTE PANADERÍA Y PASTELERÍA'),
  ('25EMHA27','AYUDANTE PANADERÍA Y PASTELERÍA'),
  ('25EMHA28','OPERARIO DE CARNICERIA'),
  ('25EMHA29','AYUDANTE COCINA'),
  ('26EMHA01','AYUDANTE COCINA'),
  ('26EMHA02','AYUDANTE COCINA'),
  ('26EMHA03','AYUDANTE PANADERÍA Y PASTELERÍA'),
  ('26EMHA04','AYUDANTE SALA Y BARRA'),
  ('26EMHA05','AYUDANTE DE CARNICERIA'),
  ('26EMHA06','AYUDANTE COCINA Y SERVICIO DE MOSTRADOR'),
  ('26EMHA07','ATENCIÓN AL CLIENTE EN SERVICIO DE BARRA Y TIENDA'),
  ('26EMHA08','ELABORACION DE PLATOS, FAST FOOD Y CATERING'),
  ('26EMHA09','AYUDANTE PANADERIA Y PASTELERIA'),
  ('26EMHA10','AYUDANTE SALA Y BARRA'),
  ('26EMHA11','AYUDANTE COCINA'),
  ('26EMHA12','OPERARIO DE CARNICERIA')
ON DUPLICATE KEY UPDATE
  itinerary_name = VALUES(itinerary_name);

DROP TEMPORARY TABLE IF EXISTS tmp_activity_dates_stage;
CREATE TEMPORARY TABLE tmp_activity_dates_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  expediente_raw TEXT NULL,
  formation_date_raw TEXT NULL
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Atividad-Formativa-Fechas).csv'
INTO TABLE tmp_activity_dates_stage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  expediente_raw,
  formation_date_raw
);

DROP TEMPORARY TABLE IF EXISTS tmp_activity_dates_normalized;
CREATE TEMPORARY TABLE tmp_activity_dates_normalized AS
SELECT
  row_id,
  UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(expediente_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS expediente,
  UPPER(SUBSTRING_INDEX(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(expediente_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), ''), '_', 1)) AS course_code,
  CASE
    WHEN NULLIF(TRIM(formation_date_raw), '') IS NULL THEN NULL
    WHEN TRIM(formation_date_raw) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(TRIM(formation_date_raw), '%Y-%m-%d')
    WHEN TRIM(formation_date_raw) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
      STR_TO_DATE(TRIM(formation_date_raw), '%m/%e/%Y'),
      STR_TO_DATE(TRIM(formation_date_raw), '%e/%m/%Y')
    )
    ELSE NULL
  END AS formation_end_date
FROM tmp_activity_dates_stage
WHERE NULLIF(TRIM(expediente_raw), '') IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_course_first_dates;
CREATE TEMPORARY TABLE tmp_course_first_dates AS
SELECT
  ranked.course_code,
  ranked.formation_end_date
FROM (
  SELECT
    n.course_code,
    n.formation_end_date,
    ROW_NUMBER() OVER (PARTITION BY n.course_code ORDER BY n.row_id ASC) AS rn
  FROM tmp_activity_dates_normalized n
  WHERE n.course_code IS NOT NULL
    AND n.formation_end_date IS NOT NULL
) ranked
WHERE ranked.rn = 1;

UPDATE course_itineraries ci
INNER JOIN tmp_course_first_dates d ON d.course_code = ci.course_code
SET ci.formation_end_date = d.formation_end_date;

SELECT COUNT(*) AS total_course_itineraries
FROM course_itineraries;

SELECT COUNT(*) AS courses_with_formation_end_date
FROM course_itineraries
WHERE formation_end_date IS NOT NULL;

SELECT COUNT(*) AS missing_courses_in_catalog
FROM tmp_course_first_dates d
LEFT JOIN course_itineraries ci ON ci.course_code = d.course_code
WHERE ci.course_code IS NULL;
