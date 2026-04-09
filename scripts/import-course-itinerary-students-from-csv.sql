-- Import course_itinerary_students relation from:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Cursos-Alumnos).csv
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Actividad-Formativa).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-course-itinerary-students-from-csv.sql
USE contracts_app;

DROP TABLE IF EXISTS course_itinerary_students;
CREATE TABLE course_itinerary_students (
  course_code VARCHAR(50) NOT NULL,
  expediente VARCHAR(64) NOT NULL,
  dni_nie VARCHAR(50) NOT NULL,
  leave_date DATE NULL,
  leave_reason VARCHAR(30) NULL,
  leave_notification VARCHAR(30) NULL,
  course_status VARCHAR(20) NOT NULL DEFAULT 'APTO',
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

INSERT INTO course_itinerary_students (course_code, expediente, dni_nie, course_status)
SELECT
  t.course_code,
  t.expediente,
  s.dni_nie,
  'APTO'
FROM tmp_course_itinerary_students_clean t
INNER JOIN course_itineraries ci ON ci.course_code = t.course_code
INNER JOIN students s ON s.dni_nie = t.dni_nie
ORDER BY t.course_code, t.expediente;

DROP TEMPORARY TABLE IF EXISTS tmp_course_activity_stage;
CREATE TEMPORARY TABLE tmp_course_activity_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  expediente_raw TEXT NULL,
  leave_date_raw TEXT NULL,
  leave_reason_raw TEXT NULL,
  leave_notification_raw TEXT NULL,
  final_status_raw TEXT NULL
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Actividad-Formativa).csv'
INTO TABLE tmp_course_activity_stage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  expediente_raw,
  leave_date_raw,
  leave_reason_raw,
  leave_notification_raw,
  final_status_raw
);

DROP TEMPORARY TABLE IF EXISTS tmp_course_activity_normalized;
CREATE TEMPORARY TABLE tmp_course_activity_normalized AS
SELECT
  src.row_id,
  src.expediente,
  CASE
    WHEN src.leave_date_raw IS NULL THEN NULL
    WHEN src.leave_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(src.leave_date_raw, '%Y-%m-%d')
    ELSE COALESCE(
      STR_TO_DATE(src.leave_date_raw, '%m/%d/%Y'),
      STR_TO_DATE(src.leave_date_raw, '%d/%m/%Y'),
      STR_TO_DATE(src.leave_date_raw, '%m/%d/%y'),
      STR_TO_DATE(src.leave_date_raw, '%d/%m/%y')
    )
  END AS leave_date,
  CASE
    WHEN src.leave_reason_raw IS NULL THEN NULL
    WHEN src.leave_reason_raw LIKE '%ABANDON%' THEN 'ABANDONO'
    WHEN src.leave_reason_raw LIKE '%INSER%' THEN 'INSERCION'
    WHEN src.leave_reason_raw LIKE '%EXPUL%' THEN 'EXPULSION'
    WHEN src.leave_reason_raw LIKE '%ENFERMEDAD%' THEN 'ENFERMEDAD'
    WHEN src.leave_reason_raw LIKE '%OTR%' THEN 'OTROS'
    ELSE NULL
  END AS leave_reason,
  CASE
    WHEN src.leave_notification_raw IS NULL THEN NULL
    WHEN src.leave_notification_raw LIKE '%NOTIFIC%' THEN 'NOTIFICADA'
    WHEN src.leave_notification_raw LIKE '%FIRMAD%' THEN 'FIRMADA'
    WHEN src.leave_notification_raw LIKE '%EXPUL%' THEN 'EXPULSION'
    ELSE NULL
  END AS leave_notification,
  CASE
    WHEN src.final_status_raw IS NULL THEN NULL
    WHEN REPLACE(src.final_status_raw, ' ', '') LIKE '%NOAPTO%' THEN 'NO APTO'
    WHEN src.final_status_raw LIKE '%INSER%' THEN 'INSERCION'
    WHEN src.final_status_raw LIKE '%APTO%' THEN 'APTO'
    ELSE NULL
  END AS final_status
FROM (
  SELECT
    row_id,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(expediente_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS expediente,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(leave_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS leave_date_raw,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(leave_reason_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS leave_reason_raw,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(leave_notification_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS leave_notification_raw,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(final_status_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS final_status_raw
  FROM tmp_course_activity_stage
) src
WHERE src.expediente IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_course_activity_clean;
CREATE TEMPORARY TABLE tmp_course_activity_clean AS
SELECT
  ranked.expediente,
  ranked.leave_date,
  ranked.leave_reason,
  ranked.leave_notification,
  CASE
    WHEN ranked.final_status IS NOT NULL THEN ranked.final_status
    WHEN ranked.leave_reason = 'INSERCION' THEN 'INSERCION'
    WHEN ranked.leave_reason IS NOT NULL
      OR ranked.leave_date IS NOT NULL
      OR ranked.leave_notification IS NOT NULL THEN 'NO APTO'
    ELSE 'APTO'
  END AS course_status
FROM (
  SELECT
    n.*,
    ROW_NUMBER() OVER (
      PARTITION BY n.expediente
      ORDER BY
        (
          (CASE WHEN n.leave_date IS NOT NULL THEN 1 ELSE 0 END) +
          (CASE WHEN n.leave_reason IS NOT NULL THEN 1 ELSE 0 END) +
          (CASE WHEN n.leave_notification IS NOT NULL THEN 1 ELSE 0 END) +
          (CASE WHEN n.final_status IS NOT NULL THEN 2 ELSE 0 END) +
          (CASE WHEN n.final_status = 'APTO' THEN -1 ELSE 0 END)
        ) DESC,
        n.row_id DESC
    ) AS rn
  FROM tmp_course_activity_normalized n
) ranked
WHERE ranked.rn = 1;

UPDATE course_itinerary_students cis
INNER JOIN tmp_course_activity_clean a ON a.expediente = cis.expediente
SET
  cis.leave_date = a.leave_date,
  cis.leave_reason = CASE WHEN a.course_status = 'APTO' THEN NULL ELSE a.leave_reason END,
  cis.leave_notification = CASE WHEN a.course_status = 'APTO' THEN NULL ELSE a.leave_notification END,
  cis.course_status = COALESCE(a.course_status, 'APTO');

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

SELECT COUNT(*) AS activity_csv_rows
FROM tmp_course_activity_stage;

SELECT COUNT(*) AS activity_normalized_rows
FROM tmp_course_activity_normalized;

SELECT COUNT(*) AS duplicate_activity_expedientes
FROM (
  SELECT expediente
  FROM tmp_course_activity_normalized
  GROUP BY expediente
  HAVING COUNT(*) > 1
) duplicates;

SELECT COUNT(*) AS activity_rows_without_enrollment
FROM tmp_course_activity_clean a
LEFT JOIN course_itinerary_students cis ON cis.expediente = a.expediente
WHERE cis.expediente IS NULL;

SELECT
  course_status,
  COUNT(*) AS status_rows
FROM course_itinerary_students
GROUP BY course_status
ORDER BY status_rows DESC, course_status ASC;
