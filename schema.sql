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
  full_name VARCHAR(190) NOT NULL,
  dni_nie VARCHAR(50) NOT NULL,
  course_code VARCHAR(50) NOT NULL,
  practices_start DATE NULL,
  practices_end DATE NULL,
  employment_status ENUM("unemployed","employed","improved","unknown") DEFAULT "unknown",
  notes TEXT NULL,
  UNIQUE KEY uq_students_dni (dni_nie),
  INDEX idx_students_course (course_code)
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
  notes TEXT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Empresas
CREATE TABLE IF NOT EXISTS companies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  sector VARCHAR(120) NULL,
  contact_name VARCHAR(120) NULL,
  contact_email VARCHAR(190) NULL,
  contact_phone VARCHAR(50) NULL,
  notes TEXT NULL,
  UNIQUE KEY uq_company_name (name)
) ENGINE=InnoDB;

-- Vacantes
CREATE TABLE IF NOT EXISTS vacancies (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  company_id BIGINT NOT NULL,
  title VARCHAR(190) NOT NULL,
  sector VARCHAR(120) NULL,
  requirements TEXT NULL,
  status ENUM("open","closed") DEFAULT "open",
  deadline DATE NULL,
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
  row_number INT NOT NULL,
  message TEXT NOT NULL,
  raw_data TEXT NULL,
  FOREIGN KEY (job_id) REFERENCES import_jobs(id) ON DELETE CASCADE
) ENGINE=InnoDB;
EOF

# helper script to apply schema via env vars (without printing secrets)
cat > apply-schema.sh <<\"EOF\"
#!/usr/bin/env bash
set -euo pipefail
: "${DB_HOST:?set DB_HOST}" : "${DB_USER:?set DB_USER}" : "${DB_NAME:=contracts_app}"
# DB_PASSWORD should be provided by the user securely: export DB_PASSWORD=... (will not be echoed)
if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "DB_PASSWORD is not set. Export it securely before running this script." 1>&2
  exit 1
fi
MYSQL_PWD="$DB_PASSWORD" mysql -h "$DB_HOST" -u "$DB_USER" < schema.sql
echo "Schema applied to $DB_HOST/$DB_NAME"
EOF
chmod +x apply-schema.sh
