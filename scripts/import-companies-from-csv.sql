-- Import companies from:
-- /Users/leonardobarreto/projects/contracts/Imports/CONTRATOS - DATOS EMPRESAS E CURSOS -APP(Datos-empresas-nuevo).csv
-- Usage example:
-- mysql --local-infile=1 -u root -D contracts_app < contracts-sql/scripts/import-companies-from-csv.sql

USE contracts_app;

CREATE TABLE IF NOT EXISTS sectors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sector_name VARCHAR(120) NOT NULL,
  UNIQUE KEY uq_sectors_name (sector_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS companies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  nif VARCHAR(50) NULL,
  cif VARCHAR(50) NULL,
  name VARCHAR(190) NOT NULL,
  fiscal_name VARCHAR(255) NULL,
  sector_id BIGINT NULL,
  company_email VARCHAR(190) NULL,
  company_phone VARCHAR(50) NULL,
  contact_name VARCHAR(190) NULL,
  contact_email VARCHAR(190) NULL,
  contact_phone VARCHAR(50) NULL,
  contact_date DATE NULL,
  agreement_signed VARCHAR(10) NULL,
  agreement_date DATE NULL,
  agreement_code VARCHAR(64) NULL,
  codigo_convenio VARCHAR(64) NULL,
  required_position VARCHAR(255) NULL,
  notes TEXT NULL,
  UNIQUE KEY uq_company_name (name),
  UNIQUE KEY uq_company_nif (nif),
  INDEX idx_companies_sector_id (sector_id),
  CONSTRAINT fk_companies_sector
    FOREIGN KEY (sector_id) REFERENCES sectors(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'cif'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN cif VARCHAR(50) NULL AFTER nif', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'fiscal_name'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN fiscal_name VARCHAR(255) NULL AFTER name', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'sector_id'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN sector_id BIGINT NULL AFTER fiscal_name', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'company_email'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN company_email VARCHAR(190) NULL AFTER sector_id', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'company_phone'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN company_phone VARCHAR(50) NULL AFTER company_email', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'contact_name'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN contact_name VARCHAR(190) NULL AFTER company_phone', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'contact_email'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN contact_email VARCHAR(190) NULL AFTER contact_name', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'contact_phone'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN contact_phone VARCHAR(50) NULL AFTER contact_email', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'contact_date'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN contact_date DATE NULL AFTER contact_phone', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'agreement_signed'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN agreement_signed VARCHAR(10) NULL AFTER contact_date', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'agreement_date'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN agreement_date DATE NULL AFTER agreement_signed', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'agreement_code'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN agreement_code VARCHAR(64) NULL AFTER agreement_date', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'codigo_convenio'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN codigo_convenio VARCHAR(64) NULL AFTER agreement_code', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'required_position'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN required_position VARCHAR(255) NULL AFTER codigo_convenio', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'notes'
);
SET @ddl := IF(@col_exists = 0, 'ALTER TABLE companies ADD COLUMN notes TEXT NULL AFTER required_position', 'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_companies_sector_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND INDEX_NAME = 'idx_companies_sector_id'
);
SET @ddl := IF(
  @idx_companies_sector_exists = 0,
  'ALTER TABLE companies ADD INDEX idx_companies_sector_id (sector_id)',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_companies_sector_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND CONSTRAINT_NAME = 'fk_companies_sector'
);
SET @ddl := IF(
  @fk_companies_sector_exists = 0,
  'ALTER TABLE companies ADD CONSTRAINT fk_companies_sector FOREIGN KEY (sector_id) REFERENCES sectors(id) ON UPDATE CASCADE ON DELETE SET NULL',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @legacy_sector_col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'companies'
    AND COLUMN_NAME = 'sector'
);
SET @ddl := IF(
  @legacy_sector_col_exists > 0,
  'ALTER TABLE companies DROP COLUMN sector',
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TEMPORARY TABLE IF EXISTS tmp_company_name_lookup;
CREATE TEMPORARY TABLE tmp_company_name_lookup AS
SELECT
  c.id AS old_company_id,
  c.name AS old_company_name,
  c.fiscal_name AS old_fiscal_name,
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
FROM companies c;

DROP TEMPORARY TABLE IF EXISTS tmp_vacancy_company_resolve;
CREATE TEMPORARY TABLE tmp_vacancy_company_resolve AS
SELECT
  v.id AS vacancy_id,
  v.company_id AS old_company_id,
  COALESCE(l.old_company_name, l.old_fiscal_name) AS company_name_source,
  l.company_name_key
FROM vacancies v
LEFT JOIN tmp_company_name_lookup l ON l.old_company_id = v.company_id;

DROP TEMPORARY TABLE IF EXISTS tmp_practice_company_resolve;
CREATE TEMPORARY TABLE tmp_practice_company_resolve AS
SELECT
  p.id AS practice_id,
  p.company_id AS old_company_id,
  COALESCE(NULLIF(TRIM(p.company_name), ''), l.old_company_name, l.old_fiscal_name) AS company_name_source,
  UPPER(
    NULLIF(
      TRIM(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(COALESCE(NULLIF(TRIM(p.company_name), ''), l.old_company_name, l.old_fiscal_name), CHAR(13), ' '),
                CHAR(10),
                ' '
              ),
              CHAR(9),
              ' '
            ),
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
FROM practices p
LEFT JOIN tmp_company_name_lookup l ON l.old_company_id = p.company_id;

DROP TEMPORARY TABLE IF EXISTS tmp_companies_stage;
CREATE TEMPORARY TABLE tmp_companies_stage (
  row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code_raw TEXT NULL,
  commercial_name_raw TEXT NULL,
  fiscal_name_raw TEXT NULL,
  nif_raw TEXT NULL,
  sector_raw TEXT NULL,
  contact_name_raw TEXT NULL,
  email_raw TEXT NULL,
  phone_raw TEXT NULL,
  contact_date_raw TEXT NULL,
  agreement_signed_raw TEXT NULL,
  agreement_date_raw TEXT NULL,
  agreement_code_raw TEXT NULL,
  required_position_raw TEXT NULL,
  observations_raw TEXT NULL,
  extra_raw TEXT NULL
) ENGINE=InnoDB;

LOAD DATA LOCAL INFILE '/Users/leonardobarreto/projects/contracts/Imports/CONTRATOS - DATOS EMPRESAS E CURSOS -APP(Datos-empresas-nuevo).csv'
INTO TABLE tmp_companies_stage
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  code_raw,
  commercial_name_raw,
  fiscal_name_raw,
  nif_raw,
  sector_raw,
  contact_name_raw,
  email_raw,
  phone_raw,
  contact_date_raw,
  agreement_signed_raw,
  agreement_date_raw,
  agreement_code_raw,
  required_position_raw,
  observations_raw,
  extra_raw
);

DROP TEMPORARY TABLE IF EXISTS tmp_companies_normalized;
CREATE TEMPORARY TABLE tmp_companies_normalized AS
SELECT
  src.row_id,
  CAST(src.code_clean AS UNSIGNED) AS company_id,
  src.company_name,
  src.fiscal_name,
  src.nif,
  src.sector_name,
  src.contact_name,
  src.company_email,
  src.company_phone,
  src.contact_email,
  src.contact_phone,
  src.contact_date,
  src.agreement_signed,
  src.agreement_date,
  src.agreement_code,
  src.required_position,
  src.notes,
  UPPER(
    NULLIF(
      TRIM(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REPLACE(REPLACE(REPLACE(src.company_name, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
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
FROM (
  SELECT
    s.row_id,
    NULLIF(REGEXP_REPLACE(TRIM(s.code_raw), '[^0-9]', ''), '') AS code_clean,
    COALESCE(
      NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.commercial_name_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), ''),
      NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.fiscal_name_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')
    ) AS company_name,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.fiscal_name_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS fiscal_name,
    UPPER(
      NULLIF(
        REGEXP_REPLACE(
          TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.nif_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')),
          '[^[:alnum:]]',
          ''
        ),
        ''
      )
    ) AS nif,
    UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.sector_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) AS sector_name,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.contact_name_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS contact_name,
    LOWER(NULLIF(REGEXP_SUBSTR(s.email_raw, '[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}'), '')) AS company_email,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.phone_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS company_phone,
    LOWER(NULLIF(REGEXP_SUBSTR(s.email_raw, '[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}'), '')) AS contact_email,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.phone_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS contact_phone,
    CASE
      WHEN NULLIF(TRIM(s.contact_date_raw), '') IS NULL THEN NULL
      WHEN TRIM(s.contact_date_raw) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(TRIM(s.contact_date_raw), '%Y-%m-%d')
      WHEN TRIM(s.contact_date_raw) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
        STR_TO_DATE(TRIM(s.contact_date_raw), '%m/%e/%Y'),
        STR_TO_DATE(TRIM(s.contact_date_raw), '%e/%m/%Y'),
        STR_TO_DATE(TRIM(s.contact_date_raw), '%m/%d/%Y'),
        STR_TO_DATE(TRIM(s.contact_date_raw), '%d/%m/%Y')
      )
      WHEN TRIM(s.contact_date_raw) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}$' THEN COALESCE(
        STR_TO_DATE(TRIM(s.contact_date_raw), '%m/%e/%y'),
        STR_TO_DATE(TRIM(s.contact_date_raw), '%e/%m/%y'),
        STR_TO_DATE(TRIM(s.contact_date_raw), '%m/%d/%y'),
        STR_TO_DATE(TRIM(s.contact_date_raw), '%d/%m/%y')
      )
      ELSE NULL
    END AS contact_date,
    CASE
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.agreement_signed_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'SI%' THEN 'SI'
      WHEN UPPER(NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.agreement_signed_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '')) LIKE 'NO%' THEN 'NO'
      ELSE NULL
    END AS agreement_signed,
    CASE
      WHEN NULLIF(TRIM(s.agreement_date_raw), '') IS NULL THEN NULL
      WHEN TRIM(s.agreement_date_raw) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(TRIM(s.agreement_date_raw), '%Y-%m-%d')
      WHEN TRIM(s.agreement_date_raw) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN COALESCE(
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%m/%e/%Y'),
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%e/%m/%Y'),
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%m/%d/%Y'),
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%d/%m/%Y')
      )
      WHEN TRIM(s.agreement_date_raw) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}$' THEN COALESCE(
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%m/%e/%y'),
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%e/%m/%y'),
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%m/%d/%y'),
        STR_TO_DATE(TRIM(s.agreement_date_raw), '%d/%m/%y')
      )
      ELSE NULL
    END AS agreement_date,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.agreement_code_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS agreement_code,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.required_position_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS required_position,
    NULLIF(TRIM(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(s.observations_raw, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '), '[[:space:]]+', ' ')), '') AS notes
  FROM tmp_companies_stage s
) src
WHERE src.code_clean IS NOT NULL
  AND src.company_name IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_companies_ranked;
CREATE TEMPORARY TABLE tmp_companies_ranked AS
SELECT
  n.*,
  ROW_NUMBER() OVER (
    PARTITION BY n.company_id
    ORDER BY
      (
        (CASE WHEN n.company_name IS NOT NULL THEN 3 ELSE 0 END) +
        (CASE WHEN n.fiscal_name IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.nif IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.sector_name IS NOT NULL THEN 2 ELSE 0 END) +
        (CASE WHEN n.contact_name IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.company_email IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.company_phone IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.agreement_code IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.required_position IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.notes IS NOT NULL THEN 1 ELSE 0 END)
      ) DESC,
      n.row_id DESC
  ) AS rn
FROM tmp_companies_normalized n;

DROP TEMPORARY TABLE IF EXISTS tmp_companies_clean;
CREATE TEMPORARY TABLE tmp_companies_clean AS
SELECT
  r.company_id,
  r.company_name,
  r.fiscal_name,
  r.nif,
  r.sector_name,
  r.contact_name,
  r.company_email,
  r.company_phone,
  r.contact_email,
  r.contact_phone,
  r.contact_date,
  r.agreement_signed,
  r.agreement_date,
  r.agreement_code,
  r.required_position,
  r.notes,
  r.company_name_key
FROM tmp_companies_ranked r
WHERE r.rn = 1;

SET FOREIGN_KEY_CHECKS=0;
DELETE FROM companies;
DELETE FROM sectors;
SET FOREIGN_KEY_CHECKS=1;

INSERT INTO sectors (sector_name)
SELECT DISTINCT c.sector_name
FROM tmp_companies_clean c
WHERE c.sector_name IS NOT NULL
ORDER BY c.sector_name;

INSERT INTO companies (
  id,
  nif,
  cif,
  name,
  fiscal_name,
  sector_id,
  company_email,
  company_phone,
  contact_name,
  contact_email,
  contact_phone,
  contact_date,
  agreement_signed,
  agreement_date,
  agreement_code,
  codigo_convenio,
  required_position,
  notes
)
SELECT
  c.company_id,
  c.nif,
  c.nif,
  c.company_name,
  c.fiscal_name,
  s.id,
  c.company_email,
  c.company_phone,
  c.contact_name,
  c.contact_email,
  c.contact_phone,
  c.contact_date,
  c.agreement_signed,
  c.agreement_date,
  c.agreement_code,
  c.agreement_code,
  c.required_position,
  c.notes
FROM tmp_companies_clean c
LEFT JOIN sectors s ON s.sector_name = c.sector_name
ORDER BY c.company_id;

DROP TEMPORARY TABLE IF EXISTS tmp_new_companies_lookup;
CREATE TEMPORARY TABLE tmp_new_companies_lookup AS
SELECT
  MIN(l.company_id) AS company_id,
  l.company_name_key
FROM (
  SELECT
    c.id AS company_id,
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
  WHERE c.name IS NOT NULL
  UNION ALL
  SELECT
    c.id AS company_id,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REPLACE(REPLACE(REPLACE(c.fiscal_name, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
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
  WHERE c.fiscal_name IS NOT NULL
) l
WHERE l.company_name_key IS NOT NULL
GROUP BY l.company_name_key;

UPDATE vacancies v
LEFT JOIN tmp_vacancy_company_resolve src ON src.vacancy_id = v.id
LEFT JOIN tmp_new_companies_lookup lk ON lk.company_name_key = src.company_name_key
SET v.company_id = lk.company_id
WHERE lk.company_id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_missing_vacancy_company_names;
CREATE TEMPORARY TABLE tmp_missing_vacancy_company_names AS
SELECT DISTINCT src.company_name_source AS company_name
FROM tmp_vacancy_company_resolve src
LEFT JOIN tmp_new_companies_lookup lk ON lk.company_name_key = src.company_name_key
WHERE src.company_name_source IS NOT NULL
  AND lk.company_id IS NULL;

INSERT INTO companies (name, fiscal_name, notes)
SELECT
  m.company_name,
  m.company_name,
  'LEGACY AUTO-CREATED TO PRESERVE EXISTING RELATIONS'
FROM tmp_missing_vacancy_company_names m
LEFT JOIN companies c
  ON TRIM(c.name) COLLATE utf8mb4_unicode_ci = TRIM(m.company_name) COLLATE utf8mb4_unicode_ci
WHERE c.id IS NULL;

INSERT IGNORE INTO companies (name, fiscal_name, notes)
VALUES (
  'EMPRESA NO IDENTIFICADA (LEGACY)',
  'EMPRESA NO IDENTIFICADA (LEGACY)',
  'AUTO-CREATED FALLBACK TO PRESERVE EXISTING RELATIONS'
);

SET @fallback_company_id := (
  SELECT id
  FROM companies
  WHERE name = 'EMPRESA NO IDENTIFICADA (LEGACY)'
  LIMIT 1
);

DROP TEMPORARY TABLE IF EXISTS tmp_new_companies_lookup;
CREATE TEMPORARY TABLE tmp_new_companies_lookup AS
SELECT
  MIN(l.company_id) AS company_id,
  l.company_name_key
FROM (
  SELECT
    c.id AS company_id,
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
  WHERE c.name IS NOT NULL
  UNION ALL
  SELECT
    c.id AS company_id,
    UPPER(
      NULLIF(
        TRIM(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REPLACE(REPLACE(REPLACE(c.fiscal_name, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
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
  WHERE c.fiscal_name IS NOT NULL
) l
WHERE l.company_name_key IS NOT NULL
GROUP BY l.company_name_key;

UPDATE vacancies v
LEFT JOIN tmp_vacancy_company_resolve src ON src.vacancy_id = v.id
LEFT JOIN tmp_new_companies_lookup lk ON lk.company_name_key = src.company_name_key
SET v.company_id = COALESCE(lk.company_id, @fallback_company_id);

UPDATE vacancies v
LEFT JOIN companies c ON c.id = v.company_id
SET v.company_id = @fallback_company_id
WHERE c.id IS NULL;

UPDATE practices p
LEFT JOIN tmp_practice_company_resolve src ON src.practice_id = p.id
LEFT JOIN tmp_new_companies_lookup lk ON lk.company_name_key = src.company_name_key
LEFT JOIN companies c ON c.id = lk.company_id
SET
  p.company_id = lk.company_id,
  p.company_name = COALESCE(c.name, src.company_name_source, p.company_name);

UPDATE practices p
LEFT JOIN companies c ON c.id = p.company_id
SET p.company_id = NULL
WHERE c.id IS NULL;

SELECT COUNT(*) AS csv_rows
FROM tmp_companies_stage;

SELECT COUNT(*) AS normalized_rows
FROM tmp_companies_normalized;

SELECT COUNT(*) AS duplicate_codes
FROM (
  SELECT company_id
  FROM tmp_companies_normalized
  GROUP BY company_id
  HAVING COUNT(*) > 1
) duplicates;

SELECT COUNT(*) AS imported_companies
FROM companies;

SELECT COUNT(*) AS imported_companies_from_csv
FROM companies
WHERE id IN (SELECT company_id FROM tmp_companies_clean);

SELECT COUNT(*) AS imported_sectors
FROM sectors;

SELECT COUNT(*) AS legacy_companies_autocreated
FROM companies
WHERE notes = 'LEGACY AUTO-CREATED TO PRESERVE EXISTING RELATIONS';

SELECT COUNT(*) AS practices_with_company
FROM practices
WHERE company_id IS NOT NULL;

SELECT COUNT(*) AS vacancies_without_company
FROM vacancies v
LEFT JOIN companies c ON c.id = v.company_id
WHERE c.id IS NULL;
