-- Datos de ejemplo
INSERT INTO companies (name, sector, contact_name, contact_email) VALUES 
('R. PARAGUAS', 'Hostelería', 'RRHH', 'rrhh@paraguas.fake'),
('SNIPES ROPA', 'Comercio', 'Tienda Central', 'seleccion@snipes.fake');

INSERT INTO students (full_name, dni_nie, course_code, employment_status) VALUES 
('ANTHONY JOSUE BRUFAU', '12345678X', 'EMHA01', 'searching'),
('JEROME MICHAEL MASON', '87654321Y', 'EMHA01', 'searching');

INSERT INTO vacancies (company_id, title, sector, status) VALUES 
(1, 'Camarero/a terraza fin de semana', 'Hostelería', 'open'),
(2, 'Dependiente/a tienda urbana', 'Comercio', 'open');

INSERT INTO interviews (student_id, place, interview_date, notes) VALUES 
(1, 'Oficinas R. PARAGUAS - Calle Serrano', '2026-01-27', 'Entrevista para puesto de camarero terraza. Llevar CV impreso.'),
(2, 'Tienda SNIPES - Centro Comercial', '2026-01-28', 'Segunda entrevista con el gerente de tienda. Perfil muy interesado.');