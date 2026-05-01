-- Import employment_contracts from Inserción Laboral CSVs:
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Inserción Laboral (1)).csv
-- /Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Inserción Laboral (2)).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-employment-contracts-from-csv.sql

USE contracts_app;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS employment_contracts;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE employment_contracts (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  expediente VARCHAR(64) NOT NULL,
  sector_id BIGINT NULL,
  position VARCHAR(190) NULL,
  company_id BIGINT NULL,
  is_itinerary_company_contract ENUM('SI', 'NO') NOT NULL DEFAULT 'NO',
  contract_code INT UNSIGNED NULL,
  attached_contract ENUM('SI', 'NO') NOT NULL DEFAULT 'NO',
  attached_work_life ENUM('SI', 'NO') NOT NULL DEFAULT 'NO',
  observations TEXT NULL,
  start_date DATE NULL,
  end_date DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_employment_contracts_expediente (expediente),
  INDEX idx_employment_contracts_sector_id (sector_id),
  INDEX idx_employment_contracts_company_id (company_id),
  INDEX idx_employment_contracts_contract_code (contract_code),
  INDEX idx_employment_contracts_start_date (start_date),
  INDEX idx_employment_contracts_end_date (end_date),
  CONSTRAINT fk_employment_contracts_expediente
    FOREIGN KEY (expediente) REFERENCES course_itinerary_students(expediente)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_employment_contracts_sector_id
    FOREIGN KEY (sector_id) REFERENCES sectors(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_employment_contracts_company_id
    FOREIGN KEY (company_id) REFERENCES companies(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_employment_contracts_contract_code
    FOREIGN KEY (contract_code) REFERENCES contract_codes(code)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

DROP TEMPORARY TABLE IF EXISTS tmp_employment_contracts_stage;
CREATE TEMPORARY TABLE tmp_employment_contracts_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  source_file VARCHAR(120) NOT NULL,
  expediente_raw TEXT NULL,
  sector_raw TEXT NULL,
  position_raw TEXT NULL,
  company_raw TEXT NULL,
  itinerary_contract_raw TEXT NULL,
  contract_code_raw TEXT NULL,
  attached_contract_raw TEXT NULL,
  attached_work_life_raw TEXT NULL,
  observations_raw TEXT NULL,
  start_date_raw TEXT NULL,
  end_date_raw TEXT NULL
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Inserción Laboral (1)).csv'
INTO TABLE tmp_employment_contracts_stage
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  expediente_raw,
  sector_raw,
  position_raw,
  company_raw,
  itinerary_contract_raw,
  contract_code_raw,
  attached_contract_raw,
  attached_work_life_raw,
  observations_raw,
  start_date_raw,
  end_date_raw
)
SET source_file = 'file_1';

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/EXPEDIENTES ALUMNOS - APP(Inserción Laboral (2)).csv'
INTO TABLE tmp_employment_contracts_stage
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  expediente_raw,
  sector_raw,
  position_raw,
  company_raw,
  itinerary_contract_raw,
  contract_code_raw,
  attached_contract_raw,
  attached_work_life_raw,
  observations_raw,
  start_date_raw,
  end_date_raw
)
SET source_file = 'file_2';

DROP TEMPORARY TABLE IF EXISTS tmp_employment_contracts_normalized;
CREATE TEMPORARY TABLE tmp_employment_contracts_normalized AS
SELECT
  src.row_id,
  src.source_file,
  src.expediente,
  src.sector_name,
  src.position,
  src.company_name,
  src.company_name_key,
  src.is_itinerary_company_contract,
  CAST(NULLIF(REGEXP_SUBSTR(src.contract_code_raw, '[0-9]+'), '') AS UNSIGNED) AS contract_code,
  src.attached_contract,
  src.attached_work_life,
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
    WHEN src.end_date_raw LIKE 'INDEFINID%' THEN NULL
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
  END AS end_date
FROM (
  SELECT
    row_id,
    source_file,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(expediente_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS expediente,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(sector_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS sector_name,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(position_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS position,
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
    CASE
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(itinerary_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) IN ('SI', 'SÍ', 'S', '1', 'TRUE', 'YES')
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(itinerary_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'SI%'
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(itinerary_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'SÍ%'
        THEN 'SI'
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(itinerary_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) IN ('NO', 'N', '0', 'FALSE')
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(itinerary_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'NO%'
        THEN 'NO'
      ELSE 'NO'
    END AS is_itinerary_company_contract,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(contract_code_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS contract_code_raw,
    CASE
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) IN ('SI', 'SÍ', 'S', '1', 'TRUE', 'YES')
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'SI%'
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'SÍ%'
        THEN 'SI'
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) IN ('NO', 'N', '0', 'FALSE')
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_contract_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'NO%'
        THEN 'NO'
      WHEN NULLIF(TRIM(attached_contract_raw), '') IS NULL THEN 'NO'
      ELSE 'SI'
    END AS attached_contract,
    CASE
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_work_life_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) IN ('SI', 'SÍ', 'S', '1', 'TRUE', 'YES')
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_work_life_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'SI%'
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_work_life_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'SÍ%'
        THEN 'SI'
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_work_life_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) IN ('NO', 'N', '0', 'FALSE')
        OR UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(attached_work_life_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'NO%'
        THEN 'NO'
      ELSE 'NO'
    END AS attached_work_life,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(observations_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS observations,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(start_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS start_date_raw,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(end_date_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS end_date_raw
  FROM tmp_employment_contracts_stage
) src
WHERE src.expediente IS NOT NULL;

INSERT INTO sectors (sector_name)
SELECT DISTINCT n.sector_name
FROM tmp_employment_contracts_normalized n
WHERE n.sector_name IS NOT NULL
ON DUPLICATE KEY UPDATE sector_name = VALUES(sector_name);

DROP TEMPORARY TABLE IF EXISTS tmp_companies_lookup;
CREATE TEMPORARY TABLE tmp_companies_lookup AS
SELECT
  MIN(x.company_id) AS company_id,
  x.company_name_key
FROM (
  SELECT
    c.id AS company_id,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REPLACE(REPLACE(REPLACE(COALESCE(c.name, c.fiscal_name), CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
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
) x
WHERE x.company_name_key IS NOT NULL
GROUP BY x.company_name_key;

INSERT INTO companies (name, fiscal_name, notes)
SELECT DISTINCT
  n.company_name,
  NULL,
  'AUTO-CREATED FROM INSERCION LABORAL CSV'
FROM tmp_employment_contracts_normalized n
LEFT JOIN tmp_companies_lookup lk ON lk.company_name_key = n.company_name_key
WHERE n.company_name IS NOT NULL
  AND n.company_name_key IS NOT NULL
  AND lk.company_id IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_companies_lookup;
CREATE TEMPORARY TABLE tmp_companies_lookup AS
SELECT
  MIN(x.company_id) AS company_id,
  x.company_name_key
FROM (
  SELECT
    c.id AS company_id,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REPLACE(REPLACE(REPLACE(COALESCE(c.name, c.fiscal_name), CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
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
) x
WHERE x.company_name_key IS NOT NULL
GROUP BY x.company_name_key;

DROP TEMPORARY TABLE IF EXISTS tmp_employment_contracts_ranked;
CREATE TEMPORARY TABLE tmp_employment_contracts_ranked AS
SELECT
  n.*,
  ROW_NUMBER() OVER (
    PARTITION BY n.expediente
    ORDER BY
      (
        (CASE WHEN n.start_date IS NOT NULL THEN 4 ELSE 0 END) +
        (CASE WHEN n.end_date IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.sector_name IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.position IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.company_name IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.contract_code IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.observations IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.attached_contract = 'SI' THEN 1 ELSE 0 END) +
        (CASE WHEN n.attached_work_life = 'SI' THEN 1 ELSE 0 END) +
        (CASE WHEN n.source_file = 'file_2' THEN 1 ELSE 0 END)
      ) DESC,
      n.row_id DESC
  ) AS rn
FROM tmp_employment_contracts_normalized n;

DROP TEMPORARY TABLE IF EXISTS tmp_employment_contracts_clean;
CREATE TEMPORARY TABLE tmp_employment_contracts_clean AS
SELECT
  r.expediente,
  sec.id AS sector_id,
  r.position,
  lk.company_id,
  r.is_itinerary_company_contract,
  cc.code AS contract_code,
  r.attached_contract,
  r.attached_work_life,
  r.observations,
  r.start_date,
  r.end_date,
  r.company_name_key,
  r.contract_code AS contract_code_input
FROM tmp_employment_contracts_ranked r
LEFT JOIN sectors sec ON sec.sector_name = r.sector_name
LEFT JOIN tmp_companies_lookup lk ON lk.company_name_key = r.company_name_key
LEFT JOIN contract_codes cc ON cc.code = r.contract_code
WHERE r.rn = 1;

INSERT INTO employment_contracts (
  expediente,
  sector_id,
  position,
  company_id,
  is_itinerary_company_contract,
  contract_code,
  attached_contract,
  attached_work_life,
  observations,
  start_date,
  end_date
)
SELECT
  c.expediente,
  c.sector_id,
  c.position,
  c.company_id,
  c.is_itinerary_company_contract,
  c.contract_code,
  c.attached_contract,
  c.attached_work_life,
  c.observations,
  c.start_date,
  c.end_date
FROM tmp_employment_contracts_clean c
INNER JOIN course_itinerary_students cis ON cis.expediente = c.expediente
ORDER BY c.expediente;

SELECT COUNT(*) AS csv_rows
FROM tmp_employment_contracts_stage;

SELECT COUNT(*) AS normalized_rows
FROM tmp_employment_contracts_normalized;

SELECT COUNT(*) AS duplicate_expedientes
FROM (
  SELECT expediente
  FROM tmp_employment_contracts_normalized
  GROUP BY expediente
  HAVING COUNT(*) > 1
) duplicates;

SELECT COUNT(*) AS rows_without_enrollment
FROM tmp_employment_contracts_clean c
LEFT JOIN course_itinerary_students cis ON cis.expediente = c.expediente
WHERE cis.expediente IS NULL;

SELECT COUNT(*) AS unresolved_companies
FROM tmp_employment_contracts_clean
WHERE company_name_key IS NOT NULL
  AND company_id IS NULL;

SELECT COUNT(*) AS unresolved_contract_codes
FROM tmp_employment_contracts_clean
WHERE contract_code_input IS NOT NULL
  AND contract_code IS NULL;

SELECT COUNT(*) AS inserted_rows
FROM employment_contracts;
