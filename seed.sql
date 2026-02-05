-- Datos de ejemplo
INSERT INTO companies (nif, name, company_email, company_phone, sector, contact_name, contact_email) VALUES 
('B12345678', 'R. PARAGUAS', 'info@paraguas.fake', '+34 600 000 001', 'Hostelería', 'RRHH', 'rrhh@paraguas.fake'),
('B87654321', 'SNIPES ROPA', 'info@snipes.fake', '+34 600 000 002', 'Comercio', 'Tienda Central', 'seleccion@snipes.fake');

INSERT INTO students (
  first_names,
  last_names,
  dni_nie,
  social_security_number,
  birth_date,
  district,
  phone,
  email,
  employment_status
) VALUES 
('ANTHONY JOSUE', 'BRUFAU', '12345678X', '12 34567890 01', '1996-03-12', 'Centro', '600123456', 'anthony.brufau@example.com', 'unemployed'),
('JEROME MICHAEL', 'MASON', '87654321Y', '11 22334455 02', '1993-11-02', 'Tetuán', '600234567', 'jerome.mason@example.com', 'unemployed');

-- Cursos realizados (por alumno)
INSERT INTO student_courses (student_id, title, description, institution, start_date, end_date) VALUES
(1, 'Ayudante de Camarero/a', 'Formación en atención al cliente, servicio de sala y barra, protocolo básico y TPV.', 'Centro de Formación Madrid', '2025-09-01', '2025-10-15'),
(1, 'Manipulador de Alimentos', 'Higiene alimentaria, alérgenos y buenas prácticas de manipulación.', 'Academia Salud & Food', '2025-10-20', '2025-10-25'),
(1, 'Prevención de Riesgos Laborales (Hostelería)', 'Prevención básica, EPIs y actuación ante incidentes.', 'PRL Formación', '2025-11-05', '2025-11-20'),
(1, 'Barista Básico', 'Extracción espresso, texturizado de leche y bebidas principales.', 'Coffee Lab', '2025-12-02', '2025-12-10'),
(1, 'Inglés para Hostelería', 'Vocabulario y frases útiles en sala y barra.', 'Language Hub', '2026-01-05', '2026-02-05'),
(1, 'Atención al Cliente y Gestión de Quejas', 'Comunicación asertiva, resolución de incidencias y fidelización.', 'Centro de Formación Madrid', '2026-02-10', '2026-02-28'),
(2, 'Dependiente/a de Comercio', 'Atención al cliente, reposición, caja y visual merchandising.', 'Escuela Comercio Urbano', '2025-08-10', '2025-09-30'),
(2, 'Inglés para Atención al Cliente', 'Comunicación en situaciones comunes en tienda y hostelería.', 'Language Hub', '2025-10-01', '2025-12-01'),
(2, 'Excel Básico', 'Tablas, fórmulas básicas y gestión de listados.', 'Aula Digital', '2025-12-05', '2025-12-20');

-- PnL (Prácticas no Laborales)
INSERT INTO pnl (
  student_id, company_nif, company_name, signer_name, signer_nif, workplace, position,
  start_date, end_date, schedule, weekly_hours, observations
) VALUES
(1, 'B44556677', 'CAFÉ PLAZA S.L.', 'Ana Ruiz', '11223344A', 'C/ Alcalá 45, Madrid', 'Ayudante de barra',
 '2025-02-01', '2025-03-15', 'Lunes: 09:00-13:00\nMiércoles: 09:00-13:00\nViernes: 09:00-13:00', 12,
 'Buen trato al cliente. Mejorar rapidez en caja.'),
(1, 'B55667788', 'HOTEL CENTRAL MADRID', 'Carlos Pérez', '22334455B', 'Hotel Central - Recepción', 'Recepcionista (prácticas)',
 '2025-06-01', '2025-07-15', 'Lunes: 10:00-14:00\nMartes: 10:00-14:00\nJueves: 10:00-14:00', 12,
 'Aprendizaje rápido. Reforzar inglés.'),
(1, 'B66778899', 'EVENTOS GRAN VÍA', 'Lucía Martín', '33445566C', 'IFEMA - Pabellón 2', 'Auxiliar de catering',
 '2025-09-01', '2025-09-30', 'Sábado: 10:00-18:00\nDomingo: 10:00-18:00', 16,
 'Buen desempeño en eventos. Trabajo en equipo excelente.'),
(1, 'B22334455', 'SERVIMAD S.A.', 'Marta Sánchez', '12345678Z', 'C/ Gran Vía 123, Madrid', 'Ayudante de sala',
 '2025-10-20', '2025-12-20', 'Lunes: 09:00-14:00\nMartes: 09:00-14:00\nMiércoles: 09:00-14:00\nJueves: 09:00-14:00\nViernes: 09:00-14:00', 25,
 'Buen desempeño. Recomendación: reforzar velocidad en momentos de alta demanda.'),
(2, 'A99887766', 'GRUPO PARAGUAS, S.A.', 'Luis Gómez', '87654321X', 'Centro Comercial Norte', 'Dependiente/a',
 '2025-09-15', '2025-11-15', 'Lunes: 16:00-20:00\nMartes: 16:00-20:00\nMiércoles: 16:00-20:00\nJueves: 16:00-20:00\nViernes: 16:00-20:00', 20,
 'Interés alto. Objetivo: mejorar argumentario de ventas y cierres.');

-- Contrataciones (histórico de contratos)
INSERT INTO hiring_contracts (
  student_id, company_nif, company_name, sector, start_date, end_date,
  workday_pct, contribution_group, contract_type, weekly_hours, contributed_days, notes
) VALUES
(1, 'B88990011', 'CATERING EXPRESS', 'Hostelería', '2025-11-01', '2025-12-15', '75%', 'Grupo 6', 'Temporal', 30, 45,
 'Contrato corto previo. Buen desempeño en eventos.'),
(1, 'B22334455', 'SERVIMAD S.A.', 'Hostelería', '2025-12-22', '2026-03-31', '50%', 'Grupo 6', 'Temporal', 20, 90,
 'Contrato tras PnL. Turnos de tarde en fines de semana.'),
(1, 'B33445566', 'Grupo La Terraza', 'Hostelería', '2026-02-01', '2026-04-15', '75%', 'Grupo 6', 'Temporal', 30, 75,
 'Contrato simultáneo (refuerzo eventos).'),
(1, 'B77889900', 'RESTO DELICIA', 'Hostelería', '2026-04-20', '2026-06-30', '100%', 'Grupo 6', 'Temporal', 40, 70,
 'Renovación por buen rendimiento.'),
(1, 'B10111213', 'HOTEL CENTRAL MADRID', 'Hostelería', '2026-07-01', NULL, '100%', 'Grupo 6', 'Indefinido', 40, 30,
 'Incorporación estable tras varias entrevistas.'),
(2, 'B87654321', 'SNIPES ROPA', 'Comercio', '2025-12-10', NULL, '100%', 'Grupo 5', 'Indefinido', 40, 60,
 'Incorporación estable. Buen nivel de atención al cliente.');

INSERT INTO vacancies (company_id, title, sector, description, status, created_at) VALUES 
(1, 'Camarero/a terraza fin de semana', 'Hostelería', 'Atención en terraza, servicio de mesa y barra. Turnos sábados y domingos.', 'open', '2026-01-05 09:00:00'),
(1, 'Ayudante de cocina', 'Hostelería', 'Apoyo en preparación, mise en place y limpieza de cocina. Con ganas de aprender.', 'open', '2026-01-08 10:30:00'),
(1, 'Recepcionista hotel', 'Hostelería', 'Atención al huésped, check-in/check-out y tareas administrativas básicas.', 'open', '2026-01-12 12:00:00'),
(2, 'Dependiente/a tienda urbana', 'Comercio', 'Atención al cliente, reposición, caja y apoyo en visual merchandising.', 'open', '2026-01-15 16:10:00'),
(2, 'Mozo/a almacén textil', 'Comercio', 'Recepción de mercancía, picking, preparación de pedidos y orden de almacén.', 'open', '2026-01-18 08:45:00'),
(2, 'Visual merchandiser junior', 'Comercio', 'Apoyo en implantación de campañas, escaparatismo básico y rotación de producto.', 'open', '2026-01-21 11:20:00');

INSERT INTO interviews (student_id, place, interview_date, status, notes) VALUES 
(1, 'Oficinas R. PARAGUAS - Calle Serrano', '2026-01-10', 'attended', 'Primera entrevista. Buen encaje con el puesto.'),
(1, 'Oficinas R. PARAGUAS - Calle Serrano', '2026-01-27', 'attended', 'Entrevista para puesto de camarero terraza. Llevar CV impreso.'),
(1, 'Hotel Central - RRHH', '2026-02-03', 'sent', 'Entrevista programada. Preparar preguntas sobre turnos.'),
(1, 'Grupo La Terraza - Restaurante', '2026-02-05', 'no_show', 'No asistió por motivo personal. Reprogramar si procede.'),
(2, 'Tienda SNIPES - Centro Comercial', '2026-01-28', 'attended', 'Segunda entrevista con el gerente de tienda. Perfil muy interesado.');

-- Invitaciones a vacantes
INSERT INTO invitations (vacancy_id, student_id, status, sent_at, responded_at) VALUES
(1, 1, 'accepted', '2026-01-20 10:00:00', '2026-01-21 09:15:00'),
(2, 1, 'accepted', '2026-01-22 11:00:00', '2026-01-23 08:20:00'),
(3, 1, 'sent', '2026-01-25 14:30:00', NULL),
(4, 1, 'rejected', '2026-01-26 09:10:00', '2026-01-27 10:00:00'),
(4, 2, 'sent', '2026-01-22 12:30:00', NULL);
