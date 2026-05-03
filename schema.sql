-- Schema base para Contracts App (Aurora MySQL compatible)
CREATE DATABASE IF NOT EXISTS contracts_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE contracts_app;

-- Usuarios internos
CREATE TABLE IF NOT EXISTS users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM("admin","department") NOT NULL DEFAULT "department",
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Cursos
CREATE TABLE IF NOT EXISTS courses (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(190) NOT NULL,
  UNIQUE KEY uq_courses_code (code)
) ENGINE=InnoDB;

-- Cursos/itinerarios importados desde CSV
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
-- Catálogo de municipios
CREATE TABLE IF NOT EXISTS municipalities (
  code INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  PRIMARY KEY (code),
  UNIQUE KEY uq_municipalities_name (name)
) ENGINE=InnoDB;

-- Catálogo de distritos por municipio
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

-- Alumnos
CREATE TABLE IF NOT EXISTS students (
  dni_nie VARCHAR(50) NOT NULL,
  id BIGINT NOT NULL AUTO_INCREMENT,
  first_names VARCHAR(190) NOT NULL,
  last_names VARCHAR(190) NOT NULL,
  social_security_number VARCHAR(50) NULL,
  birth_date DATE NULL,
  sex ENUM("mujer","hombre","other","unknown") NOT NULL DEFAULT "unknown",
  district_code INT UNSIGNED NULL,
  municipality_code INT UNSIGNED NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(190) NULL,
  tic VARCHAR(3) NOT NULL DEFAULT 'NO',
  status_laboral VARCHAR(40) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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

-- Relación cursos-itinerario por alumno (CSV Cursos-Alumnos)
CREATE TABLE IF NOT EXISTS course_itinerary_students (
  course_code VARCHAR(50) NOT NULL,
  expediente VARCHAR(64) NOT NULL,
  dni_nie VARCHAR(50) NOT NULL,
  effective_start_date DATE NULL,
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

-- Cursos realizados por alumno
CREATE TABLE IF NOT EXISTS student_courses (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT NOT NULL,
  title VARCHAR(190) NOT NULL,
  description TEXT NULL,
  institution VARCHAR(190) NULL,
  start_date DATE NULL,
  end_date DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_student_courses_student (student_id),
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;
-- Sectores de empresa (normalizado)
CREATE TABLE IF NOT EXISTS sectors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sector_name VARCHAR(120) NOT NULL,
  UNIQUE KEY uq_sectors_name (sector_name)
) ENGINE=InnoDB;

-- Catálogo de cursos (normalizado) para Matching con IA
-- Nota: se alimenta desde student_courses (títulos únicos)
CREATE TABLE IF NOT EXISTS course_topics (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(190) NOT NULL,
  description TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_course_topics_title (title)
) ENGINE=InnoDB;
-- Catálogo de códigos de contrato
CREATE TABLE IF NOT EXISTS contract_codes (
  code INT UNSIGNED NOT NULL,
  contract_type VARCHAR(80) NOT NULL,
  workday VARCHAR(80) NOT NULL,
  hiring_mode VARCHAR(190) NOT NULL,
  PRIMARY KEY (code)
) ENGINE=InnoDB;

INSERT INTO contract_codes (code, contract_type, workday, hiring_mode) VALUES
  (100, 'INDEFINIDO', 'TIEMPO COMPLETO', 'ORDINARIO'),
  (109, 'INDEFINIDO', 'TIEMPO COMPLETO', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (130, 'INDEFINIDO', 'TIEMPO COMPLETO', 'DISCAPACITADOS'),
  (139, 'INDEFINIDO', 'TIEMPO COMPLETO', 'DISCAPACITADOS'),
  (150, 'INDEFINIDO', 'TIEMPO COMPLETO', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (189, 'INDEFINIDO', 'TIEMPO COMPLETO', ''),
  (200, 'INDEFINIDO', 'TIEMPO PARCIAL', 'ORDINARIO'),
  (209, 'INDEFINIDO', 'TIEMPO PARCIAL', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (230, 'INDEFINIDO', 'TIEMPO PARCIAL', 'DISCAPACITADOS'),
  (239, 'INDEFINIDO', 'TIEMPO PARCIAL', 'DISCAPACITADOS'),
  (250, 'INDEFINIDO', 'TIEMPO PARCIAL', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (289, 'INDEFINIDO', 'TIEMPO PARCIAL', ''),
  (300, 'INDEFINIDO', 'FIJO DISCONTINUO', ''),
  (309, 'INDEFINIDO', 'FIJO DISCONTINUO', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (330, 'INDEFINIDO', 'FIJO DISCONTINUO', 'DISCAPACITADOS'),
  (339, 'INDEFINIDO', 'FIJO DISCONTINUO', 'DISCAPACITADOS'),
  (350, 'INDEFINIDO', 'FIJO DISCONTINUO', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (389, 'INDEFINIDO', 'FIJO DISCONTINUO', ''),
  (401, 'DURACIÓN DETERMINADA', 'TIEMPO COMPLETO', 'OBRAO SERVICIO DETERMINADO'),
  (402, 'DURACIÓN DETERMINADA', 'TIEMPO COMPLETO', 'EVENTUALPOR CIRCUNSTANCIAS DE LAPRODUCCIÓN'),
  (403, 'DURACIÓN DETERMINADA', 'TIEMPO COMPLETO', 'INSERCIÓN'),
  (408, 'TEMPORAL', 'TIEMPO COMPLETO', ''),
  (410, 'DURACIÓN DETERMINADA', 'TIEMPO COMPLETO', 'INTERINIDAD'),
  (418, 'DURACIÓN DETERMINADA', 'TIEMPO COMPLETO', 'INTERINIDAD'),
  (420, 'TEMPORAL', 'TIEMPO COMPLETO', 'PRÁCTICAS'),
  (421, 'TEMPORAL', 'TIEMPO COMPLETO', 'FORMACIÓN'),
  (430, 'TEMPORAL', 'TIEMPO COMPLETO', 'DISCAPACITADOS'),
  (441, 'TEMPORAL', 'TIEMPO COMPLETO', 'RELEVO'),
  (450, 'TEMPORAL', 'TIEMPO COMPLETO', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (452, 'TEMPORAL', 'TIEMPO COMPLETO', 'DESEMPLEADOS EMPRESAS DE INSERCIÓN'),
  (501, 'DURACIÓN DETERMINADA', 'TIEMPO PARCIAL', 'OBRAO SERVICIO DETERMINADO'),
  (502, 'DURACIÓN DETERMINADA', 'TIEMPO PARCIAL', 'EVENTUALPOR CIRCUNSTANCIAS DE LAPRODUCCIÓN'),
  (503, 'DURACIÓN DETERMINADA', 'TIEMPO PARCIAL', 'INSERCIÓN'),
  (508, 'TEMPORAL', 'TIEMPO PARCIAL', ''),
  (510, 'DURACIÓN DETERMINADA', 'TIEMPO PARCIAL', 'INTERINIDAD'),
  (518, 'DURACIÓN DETERMINADA', 'TIEMPO PARCIAL', 'INTERINIDAD'),
  (520, 'TEMPORAL', 'TIEMPO PARCIAL', 'PRÁCTICAS'),
  (530, 'TEMPORAL', 'TIEMPO PARCIAL', 'DISCAPACITADOS'),
  (540, 'TEMPORAL', 'TIEMPO PARCIAL', 'JUBILADO PARCIAL'),
  (541, 'TEMPORAL', 'TIEMPO PARCIAL', 'RELEVO'),
  (550, 'TEMPORAL', 'TIEMPO PARCIAL', 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE'),
  (552, 'TEMPORAL', 'TIEMPO PARCIAL', 'DESEMPLEADOS CONTRATADOS POR EMPRESAS DE INSERCIÓN')
ON DUPLICATE KEY UPDATE
  contract_type = VALUES(contract_type),
  workday = VALUES(workday),
  hiring_mode = VALUES(hiring_mode);



-- Prácticas
CREATE TABLE IF NOT EXISTS internships (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT NOT NULL,
  company_name VARCHAR(190) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Entrevistas
CREATE TABLE IF NOT EXISTS interviews (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT NOT NULL,
  place VARCHAR(190) NULL,
  interview_date DATE NOT NULL,
  status ENUM("sent","attended","no_show") NOT NULL DEFAULT "sent",
  notes TEXT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Empresas
CREATE TABLE IF NOT EXISTS companies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
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
  has_complex_practice_centers TINYINT(1) NOT NULL DEFAULT 0,
  notes TEXT NULL,
  UNIQUE KEY uq_company_fiscal_name (fiscal_name),
  INDEX idx_companies_sector_id (sector_id),
  CONSTRAINT fk_companies_sector
    FOREIGN KEY (sector_id) REFERENCES sectors(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- Direcciones/Centros de prácticas por empresa
CREATE TABLE IF NOT EXISTS company_practice_centers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT NOT NULL,
  address VARCHAR(255) NULL,
  sector VARCHAR(120) NULL,
  center VARCHAR(190) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_company_practice_centers_company_id (company_id),
  CONSTRAINT fk_company_practice_centers_company
    FOREIGN KEY (company_id) REFERENCES companies(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Prácticas no laborales (Control-Prácticas)
CREATE TABLE IF NOT EXISTS pnl_registered_companies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pnl_registered_companies_name (name)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS practices (
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

CREATE TABLE IF NOT EXISTS tutors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  dni VARCHAR(32) NOT NULL,
  full_name VARCHAR(190) NOT NULL,
  phone VARCHAR(50) NULL,
  tutor_of ENUM('EMHA', 'COMPANY') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_tutors_dni_role (dni, tutor_of),
  INDEX idx_tutors_dni (dni)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS practice_tutors (
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

-- Vacantes
CREATE TABLE IF NOT EXISTS vacancies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT NOT NULL,
  practice_center_id BIGINT NULL,
  workplace VARCHAR(255) NULL,
  title VARCHAR(190) NOT NULL,
  sector VARCHAR(120) NULL,
  description TEXT NULL,
  requirements TEXT NULL,
  horarios TEXT NULL,
  tipo_contrato VARCHAR(120) NULL,
  sueldo_aproximado_bruto_anual DECIMAL(12,2) NULL,
  status ENUM("open","closed") DEFAULT "open",
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_vacancies_practice_center_id (practice_center_id),
  FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
  FOREIGN KEY (practice_center_id) REFERENCES company_practice_centers(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Puntaje de Matching por Vacante vs Curso (IA)
CREATE TABLE IF NOT EXISTS vacancy_course_match (
  vacancy_id BIGINT NOT NULL,
  course_topic_id BIGINT NOT NULL,
  score TINYINT NOT NULL,
  model VARCHAR(64) NOT NULL,
  prompt_version INT NOT NULL DEFAULT 1,
  notes VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (vacancy_id, course_topic_id),
  INDEX idx_vacancy_course_match_vacancy (vacancy_id),
  INDEX idx_vacancy_course_match_course (course_topic_id),
  FOREIGN KEY (vacancy_id) REFERENCES vacancies(id) ON DELETE CASCADE,
  FOREIGN KEY (course_topic_id) REFERENCES course_topics(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Empleos/Contratos
CREATE TABLE IF NOT EXISTS employment_contracts (
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

-- Invitaciones a vacantes
CREATE TABLE IF NOT EXISTS invitations (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  vacancy_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  status ENUM("sent","accepted","rejected","expired") DEFAULT "sent",
  sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  responded_at DATETIME NULL,
  FOREIGN KEY (vacancy_id) REFERENCES vacancies(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  UNIQUE KEY uq_invitation (vacancy_id, student_id)
) ENGINE=InnoDB;

-- Documentos (CVs)
CREATE TABLE IF NOT EXISTS documents (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT NOT NULL,
  type ENUM("cv","other") DEFAULT "cv",
  url VARCHAR(255) NOT NULL,
  uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Import jobs y errores
CREATE TABLE IF NOT EXISTS import_jobs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  source VARCHAR(120) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM("running","completed","failed") DEFAULT "running"
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS import_errors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  job_id BIGINT NOT NULL,
  `row_number` INT NOT NULL,
  message TEXT NOT NULL,
  raw_data TEXT NULL,
  FOREIGN KEY (job_id) REFERENCES import_jobs(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Liquidaciones (cierre de días cotizados)
CREATE TABLE IF NOT EXISTS liquidations (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  target ENUM("six_months","one_year") NOT NULL,
  mode ENUM("individual","pooled") NOT NULL DEFAULT "individual",
  target_fte_days INT NOT NULL,
  total_students INT NOT NULL DEFAULT 0,
  total_fte_days_used DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_jornadas INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_liquidations_range (start_date, end_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS student_liquidation_balances (
  student_id BIGINT PRIMARY KEY,
  fte_days_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS liquidation_lines (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  liquidation_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  opening_fte_days DECIMAL(12,2) NOT NULL DEFAULT 0,
  added_fte_days DECIMAL(12,2) NOT NULL DEFAULT 0,
  used_fte_days DECIMAL(12,2) NOT NULL DEFAULT 0,
  closing_fte_days DECIMAL(12,2) NOT NULL DEFAULT 0,
  jornadas_generated INT NOT NULL DEFAULT 0,
  FOREIGN KEY (liquidation_id) REFERENCES liquidations(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  INDEX idx_liquidation_lines_liquidation (liquidation_id),
  INDEX idx_liquidation_lines_student (student_id)
) ENGINE=InnoDB;
