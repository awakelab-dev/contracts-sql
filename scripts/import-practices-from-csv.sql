-- Import practices from:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Control-Prácticas).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-practices-from-csv.sql
USE contracts_app;

DROP TABLE IF EXISTS practice_tutors;
DROP TABLE IF EXISTS tutors;
DROP TABLE IF EXISTS practices;
DROP TABLE IF EXISTS pnl_registered_companies;

CREATE TABLE pnl_registered_companies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pnl_registered_companies_name (name)
) ENGINE=InnoDB;

CREATE TABLE practices (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  expediente VARCHAR(64) NOT NULL,
  company_id BIGINT NULL,
  company_name VARCHAR(190) NULL,
  pnl_registered_company_id BIGINT NULL,
  workplace VARCHAR(255) NULL,
  does_practices VARCHAR(20) NOT NULL DEFAULT 'NO',
  conditions_for_practice TEXT NULL,
  practice_shift TEXT NULL,
  observations TEXT NULL,
  start_date DATE NULL,
  end_date DATE NULL,
  attendance_days INT NULL,
  schedule TEXT NULL,
  evaluation TEXT NULL,
  practice_status VARCHAR(40) NULL,
  leave_date DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_practices_expediente (expediente),
  INDEX idx_practices_company (company_id),
  INDEX idx_practices_pnl_registered_company_id (pnl_registered_company_id),
  INDEX idx_practices_start_date (start_date),
  INDEX idx_practices_end_date (end_date),
  CONSTRAINT fk_practices_expediente
    FOREIGN KEY (expediente) REFERENCES course_itinerary_students(expediente)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_practices_company
    FOREIGN KEY (company_id) REFERENCES companies(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_practices_pnl_registered_company
    FOREIGN KEY (pnl_registered_company_id) REFERENCES pnl_registered_companies(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE tutors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  dni VARCHAR(32) NOT NULL,
  full_name VARCHAR(190) NOT NULL,
  phone VARCHAR(50) NULL,
  tutor_of ENUM('EMHA','COMPANY') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tutors_dni_role (dni, tutor_of),
  INDEX idx_tutors_dni (dni)
) ENGINE=InnoDB;

CREATE TABLE practice_tutors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  practice_id BIGINT NOT NULL,
  tutor_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_practice_tutors_pair (practice_id, tutor_id),
  INDEX idx_practice_tutors_tutor_id (tutor_id),
  CONSTRAINT fk_practice_tutors_practice
    FOREIGN KEY (practice_id) REFERENCES practices(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_practice_tutors_tutor
    FOREIGN KEY (tutor_id) REFERENCES tutors(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TEMPORARY TABLE IF EXISTS tmp_practices_stage;
CREATE TEMPORARY TABLE tmp_practices_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  tecnico_raw TEXT NULL,
  expediente_raw TEXT NULL,
  permiso_trabajo_raw TEXT NULL,
  permiso_trabajo_obs_raw TEXT NULL,
  does_practices_raw TEXT NULL,
  conditions_raw TEXT NULL,
  cv_raw TEXT NULL,
  shift_raw TEXT NULL,
  observations_raw TEXT NULL,
  company_raw TEXT NULL,
  workplace_raw TEXT NULL,
  start_date_raw TEXT NULL,
  end_date_raw TEXT NULL,
  attendance_days_raw TEXT NULL,
  schedule_raw TEXT NULL,
  breakdown_days_raw TEXT NULL,
  tutor_emha_raw TEXT NULL,
  tutor_company_raw TEXT NULL,
  tutor_email_raw TEXT NULL,
  tutor_phone_raw TEXT NULL,
  social_security_company_raw TEXT NULL,
  attendance_sheet_raw TEXT NULL,
  has_ss_register_raw TEXT NULL,
  has_ss_unregister_raw TEXT NULL,
  evaluation_raw TEXT NULL,
  status_raw TEXT NULL,
  leave_date_raw TEXT NULL
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Control-Prácticas).csv'
INTO TABLE tmp_practices_stage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  tecnico_raw,
  expediente_raw,
  permiso_trabajo_raw,
  permiso_trabajo_obs_raw,
  does_practices_raw,
  conditions_raw,
  cv_raw,
  shift_raw,
  observations_raw,
  company_raw,
  workplace_raw,
  start_date_raw,
  end_date_raw,
  attendance_days_raw,
  schedule_raw,
  breakdown_days_raw,
  tutor_emha_raw,
  tutor_company_raw,
  tutor_email_raw,
  tutor_phone_raw,
  social_security_company_raw,
  attendance_sheet_raw,
  has_ss_register_raw,
  has_ss_unregister_raw,
  evaluation_raw,
  status_raw,
  leave_date_raw
);

DROP TEMPORARY TABLE IF EXISTS tmp_practices_normalized;
CREATE TEMPORARY TABLE tmp_practices_normalized AS
SELECT
  src.row_id,
  src.expediente,
  src.company_name,
  src.company_name_key,
  src.workplace,
  CASE
    WHEN src.does_practices_raw IS NULL THEN NULL
    WHEN src.does_practices_raw LIKE '%INSER%' THEN 'INSERCION'
    WHEN src.does_practices_raw LIKE 'SI%' OR src.does_practices_raw = 'SÍ' THEN 'SI'
    WHEN src.does_practices_raw LIKE '%ACTUALIZ%' THEN 'ACTUALIZAR'
    WHEN src.does_practices_raw LIKE 'NO%' THEN 'NO'
    ELSE NULL
  END AS does_practices,
  src.conditions_for_practice,
  src.practice_shift,
  src.observations,
  CASE
    WHEN src.start_date_raw IS NULL THEN NULL
    WHEN src.start_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(src.start_date_raw, '%Y-%m-%d')
    WHEN src.start_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
      STR_TO_DATE(src.start_date_raw, '%m/%e/%Y'),
      STR_TO_DATE(src.start_date_raw, '%e/%m/%Y'),
      STR_TO_DATE(src.start_date_raw, '%m/%d/%Y'),
      STR_TO_DATE(src.start_date_raw, '%d/%m/%Y')
    )
    WHEN src.start_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}$' THEN COALESCE(
      STR_TO_DATE(src.start_date_raw, '%m/%e/%y'),
      STR_TO_DATE(src.start_date_raw, '%e/%m/%y'),
      STR_TO_DATE(src.start_date_raw, '%m/%d/%y'),
      STR_TO_DATE(src.start_date_raw, '%d/%m/%y')
    )
    ELSE NULL
  END AS start_date,
  CASE
    WHEN src.end_date_raw IS NULL THEN NULL
    WHEN src.end_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(src.end_date_raw, '%Y-%m-%d')
    WHEN src.end_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
      STR_TO_DATE(src.end_date_raw, '%m/%e/%Y'),
      STR_TO_DATE(src.end_date_raw, '%e/%m/%Y'),
      STR_TO_DATE(src.end_date_raw, '%m/%d/%Y'),
      STR_TO_DATE(src.end_date_raw, '%d/%m/%Y')
    )
    WHEN src.end_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}$' THEN COALESCE(
      STR_TO_DATE(src.end_date_raw, '%m/%e/%y'),
      STR_TO_DATE(src.end_date_raw, '%e/%m/%y'),
      STR_TO_DATE(src.end_date_raw, '%m/%d/%y'),
      STR_TO_DATE(src.end_date_raw, '%d/%m/%y')
    )
    ELSE NULL
  END AS end_date,
  CAST(NULLIF(REGEXP_SUBSTR(src.attendance_days_raw, '[0-9]+'), '') AS UNSIGNED) AS attendance_days,
  src.schedule,
  src.evaluation,
  CASE
    WHEN src.status_raw IS NULL THEN NULL
    WHEN src.status_raw LIKE '%FINALIZ%' THEN 'FINALIZADAS'
    WHEN src.status_raw LIKE '%INTERRUMP%' OR src.status_raw LIKE '%INTERRUP%' THEN 'INTERRUMPIDAS'
    WHEN src.status_raw LIKE '%NO REALIZA%' THEN 'NO REALIZA PRACTICAS'
    WHEN src.status_raw LIKE '%NO APTO%' THEN 'NO APTO FORMACION'
    WHEN src.status_raw LIKE '%INSER%' THEN 'INSERCION FORMACION'
    ELSE src.status_raw
  END AS practice_status,
  CASE
    WHEN src.leave_date_raw IS NULL THEN NULL
    WHEN src.leave_date_raw REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(src.leave_date_raw, '%Y-%m-%d')
    WHEN src.leave_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
      STR_TO_DATE(src.leave_date_raw, '%m/%e/%Y'),
      STR_TO_DATE(src.leave_date_raw, '%e/%m/%Y'),
      STR_TO_DATE(src.leave_date_raw, '%m/%d/%Y'),
      STR_TO_DATE(src.leave_date_raw, '%d/%m/%Y')
    )
    WHEN src.leave_date_raw REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}$' THEN COALESCE(
      STR_TO_DATE(src.leave_date_raw, '%m/%e/%y'),
      STR_TO_DATE(src.leave_date_raw, '%e/%m/%y'),
      STR_TO_DATE(src.leave_date_raw, '%m/%d/%y'),
      STR_TO_DATE(src.leave_date_raw, '%d/%m/%y')
    )
    ELSE NULL
  END AS leave_date
FROM (
  SELECT
    row_id,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(expediente_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS expediente,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(does_practices_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS does_practices_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(conditions_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS conditions_for_practice,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(shift_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS practice_shift,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(observations_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS observations,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(company_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS company_name,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REPLACE(REPLACE(REPLACE(company_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
              '[^[:alnum:] ]+',
              ' '
            ),
            '[[:space:]]+',
            ' '
          )
        ),
        ''
      )
    ) AS company_name_key,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(workplace_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS workplace,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(start_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS start_date_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(end_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS end_date_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attendance_days_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS attendance_days_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(schedule_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS schedule,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(evaluation_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS evaluation,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(status_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS status_raw,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(leave_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS leave_date_raw
  FROM tmp_practices_stage
) src
WHERE src.expediente IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_companies_lookup;
CREATE TEMPORARY TABLE tmp_companies_lookup AS
SELECT
  MIN(c.id) AS company_id,
  UPPER(
    NULLIF(
      TRIM(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REPLACE(REPLACE(REPLACE(c.name, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
            '[^[:alnum:] ]+',
            ' '
          ),
          '[[:space:]]+',
          ' '
        )
      ),
      ''
    )
  ) AS company_name_key
FROM companies c
GROUP BY company_name_key;

DROP TEMPORARY TABLE IF EXISTS tmp_practices_ranked;
CREATE TEMPORARY TABLE tmp_practices_ranked AS
SELECT
  n.*,
  c.company_id,
  ROW_NUMBER() OVER (
    PARTITION BY n.expediente
    ORDER BY
      (
        (CASE WHEN n.practice_status IS NOT NULL THEN 4 ELSE 0 END) +
        (CASE WHEN n.does_practices IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.company_name IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.start_date IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.end_date IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.evaluation IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.leave_date IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.attendance_days IS NOT NULL THEN 1 ELSE 0 END)
      ) DESC,
      n.row_id DESC
  ) AS rn
FROM tmp_practices_normalized n
LEFT JOIN tmp_companies_lookup c ON c.company_name_key = n.company_name_key;

DROP TEMPORARY TABLE IF EXISTS tmp_practices_clean;
CREATE TEMPORARY TABLE tmp_practices_clean AS
SELECT
  r.expediente,
  r.company_id,
  r.company_name,
  r.workplace,
  CASE
    WHEN r.does_practices IS NOT NULL THEN r.does_practices
    WHEN r.practice_status = 'INSERCION FORMACION' THEN 'INSERCION'
    WHEN r.practice_status IN ('NO REALIZA PRACTICAS', 'NO APTO FORMACION') THEN 'NO'
    WHEN r.start_date IS NOT NULL OR r.end_date IS NOT NULL THEN 'SI'
    ELSE 'NO'
  END AS does_practices,
  r.conditions_for_practice,
  r.practice_shift,
  r.observations,
  r.start_date,
  r.end_date,
  r.attendance_days,
  r.schedule,
  r.evaluation,
  CASE
    WHEN r.practice_status IS NOT NULL THEN r.practice_status
    WHEN r.does_practices = 'INSERCION' THEN 'INSERCION FORMACION'
    WHEN r.does_practices = 'NO' THEN 'NO REALIZA PRACTICAS'
    WHEN r.end_date IS NOT NULL THEN 'FINALIZADAS'
    ELSE NULL
  END AS practice_status,
  r.leave_date
FROM tmp_practices_ranked r
WHERE r.rn = 1;

INSERT INTO practices (
  expediente,
  company_id,
  company_name,
  workplace,
  does_practices,
  conditions_for_practice,
  practice_shift,
  observations,
  start_date,
  end_date,
  attendance_days,
  schedule,
  evaluation,
  practice_status,
  leave_date
)
SELECT
  c.expediente,
  c.company_id,
  c.company_name,
  c.workplace,
  c.does_practices,
  c.conditions_for_practice,
  c.practice_shift,
  c.observations,
  c.start_date,
  c.end_date,
  c.attendance_days,
  c.schedule,
  c.evaluation,
  c.practice_status,
  c.leave_date
FROM tmp_practices_clean c
INNER JOIN course_itinerary_students cis ON cis.expediente = c.expediente
ORDER BY c.expediente;

SELECT COUNT(*) AS csv_rows
FROM tmp_practices_stage;

SELECT COUNT(*) AS normalized_rows
FROM tmp_practices_normalized;

SELECT COUNT(*) AS duplicate_expedientes
FROM (
  SELECT expediente
  FROM tmp_practices_normalized
  GROUP BY expediente
  HAVING COUNT(*) > 1
) duplicates;

SELECT COUNT(*) AS rows_without_enrollment
FROM tmp_practices_clean c
LEFT JOIN course_itinerary_students cis ON cis.expediente = c.expediente
WHERE cis.expediente IS NULL;

SELECT COUNT(*) AS inserted_rows
FROM practices;

SELECT COUNT(*) AS unresolved_companies
FROM practices
WHERE company_name IS NOT NULL
  AND company_id IS NULL;

SELECT
  does_practices,
  COUNT(*) AS rows_count
FROM practices
GROUP BY does_practices
ORDER BY rows_count DESC, does_practices ASC;

SELECT
  COALESCE(practice_status, '(SIN ESTADO)') AS practice_status,
  COUNT(*) AS rows_count
FROM practices
GROUP BY practice_status
ORDER BY rows_count DESC, practice_status ASC;
