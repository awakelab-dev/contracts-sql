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

-- Relación cursos-itinerario por alumno (CSV Cursos-Alumnos)
CREATE TABLE IF NOT EXISTS course_itinerary_students (
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


-- Contrataciones (histórico de contratos)
CREATE TABLE IF NOT EXISTS hiring_contracts (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT NOT NULL,
  company_nif VARCHAR(50) NOT NULL,
  company_name VARCHAR(190) NOT NULL,
  sector VARCHAR(120) NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  workday_pct VARCHAR(20) NULL,
  contribution_group VARCHAR(190) NULL,
  contract_type VARCHAR(120) NULL,
  weekly_hours INT NULL,
  contributed_days INT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_hiring_contracts_student (student_id),
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

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
  nif VARCHAR(50) NULL,
  name VARCHAR(190) NOT NULL,
  company_email VARCHAR(190) NULL,
  company_phone VARCHAR(50) NULL,
  sector VARCHAR(120) NULL,
  contact_name VARCHAR(120) NULL,
  contact_email VARCHAR(190) NULL,
  contact_phone VARCHAR(50) NULL,
  notes TEXT NULL,
  UNIQUE KEY uq_company_name (name),
  UNIQUE KEY uq_company_nif (nif)
) ENGINE=InnoDB;

-- Prácticas no laborales (Control-Prácticas)
CREATE TABLE IF NOT EXISTS practices (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  expediente VARCHAR(64) NOT NULL,
  company_id BIGINT NULL,
  company_name VARCHAR(190) NULL,
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
  INDEX idx_practices_start_date (start_date),
  INDEX idx_practices_end_date (end_date),
  CONSTRAINT fk_practices_expediente
    FOREIGN KEY (expediente) REFERENCES course_itinerary_students(expediente)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_practices_company
    FOREIGN KEY (company_id) REFERENCES companies(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- Vacantes
CREATE TABLE IF NOT EXISTS vacancies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT NOT NULL,
  title VARCHAR(190) NOT NULL,
  sector VARCHAR(120) NULL,
  description TEXT NULL,
  requirements TEXT NULL,
  status ENUM("open","closed") DEFAULT "open",
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
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
  student_id BIGINT NOT NULL,
  sector VARCHAR(120) NULL,
  position VARCHAR(120) NULL,
  employer VARCHAR(190) NULL,
  contract_type VARCHAR(120) NULL,
  attached_contract VARCHAR(255) NULL,
  workday VARCHAR(120) NULL,
  worked_days INT NULL,
  start_date DATE NULL,
  end_date DATE NULL,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
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
