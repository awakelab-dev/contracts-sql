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

-- Alumnos
CREATE TABLE IF NOT EXISTS students (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  first_names VARCHAR(190) NOT NULL,
  last_names VARCHAR(190) NOT NULL,
  dni_nie VARCHAR(50) NOT NULL,
  social_security_number VARCHAR(50) NULL,
  birth_date DATE NULL,
  district VARCHAR(120) NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(190) NULL,
  practices_start DATE NULL,
  practices_end DATE NULL,
  employment_status ENUM("unemployed","employed","improved","unknown") DEFAULT "unknown",
  notes TEXT NULL,
  UNIQUE KEY uq_students_dni (dni_nie)
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

-- PnL (Prácticas no Laborales)
CREATE TABLE IF NOT EXISTS pnl (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id BIGINT NOT NULL,
  company_nif VARCHAR(50) NOT NULL,
  company_name VARCHAR(190) NOT NULL,
  signer_name VARCHAR(190) NULL,
  signer_nif VARCHAR(50) NULL,
  workplace VARCHAR(190) NULL,
  position VARCHAR(190) NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  schedule TEXT NULL,
  weekly_hours INT NULL,
  observations TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_pnl_student (student_id),
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
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
