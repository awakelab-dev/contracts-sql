#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

// Deterministic seed generator for Contracts App.
// Run: node contracts-sql/scripts/generate-seed.mjs
// Output: contracts-sql/seed.sql

const OUT_FILE = path.resolve(process.cwd(), 'contracts-sql/seed.sql');

const CONFIG = {
  rng_seed: 1337,
  companies: 30,
  vacancies_per_company_min: 2,
  vacancies_per_company_max: 3,
  students: 100,
  cvs: 75,
  pnl_per_student_min: 1,
  pnl_per_student_max: 5,
  courses_per_student_min: 1,
  courses_per_student_max: 3,
  invitations_per_student_min: 3,
  invitations_per_student_max: 7,
  interviews_per_student_min: 1,
  interviews_per_student_max: 3,
  contracts_per_student_min: 2,
  contracts_per_student_max: 10,

  // Contract date bounds (YYYY-MM-DD) for generated hiring_contracts.
  contract_start_min: '2024-01-01',
  contract_start_max: '2026-01-15',

  // Vacancy created_at bounds (YYYY-MM-DD).
  vacancy_created_min: '2024-08-01',
  vacancy_created_max: '2026-02-01',
};

function createRng(seed) {
  let s = (seed >>> 0) || 1;
  return {
    next() {
      // LCG (Numerical Recipes)
      s = (Math.imul(1664525, s) + 1013904223) >>> 0;
      return s / 2 ** 32;
    },
    int(min, max) {
      if (max < min) throw new Error(`int(min,max): max < min (${min},${max})`);
      const r = this.next();
      return Math.floor(r * (max - min + 1)) + min;
    },
    chance(p) {
      return this.next() < p;
    },
    pick(arr) {
      if (!arr.length) throw new Error('pick(): empty array');
      return arr[this.int(0, arr.length - 1)];
    },
    shuffle(arr) {
      const a = [...arr];
      for (let i = a.length - 1; i > 0; i--) {
        const j = this.int(0, i);
        [a[i], a[j]] = [a[j], a[i]];
      }
      return a;
    },
  };
}

const rng = createRng(CONFIG.rng_seed);

function pad2(n) {
  return String(n).padStart(2, '0');
}

function toIsoDate(d) {
  return d.toISOString().slice(0, 10);
}

function parseIsoDateUTC(s) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) throw new Error(`Invalid date: ${s}`);
  const [y, m, d] = s.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function addDaysUTC(date, days) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  d.setUTCDate(d.getUTCDate() + days);
  return d;
}

function randDateBetween(startIso, endIso) {
  const start = parseIsoDateUTC(startIso);
  const end = parseIsoDateUTC(endIso);
  const msPerDay = 24 * 60 * 60 * 1000;
  const days = Math.max(0, Math.floor((end.getTime() - start.getTime()) / msPerDay));
  const offset = rng.int(0, days);
  return toIsoDate(addDaysUTC(start, offset));
}

function randDateTimeBetween(startIso, endIso) {
  const day = randDateBetween(startIso, endIso);
  const hh = pad2(rng.int(8, 18));
  const mm = pad2(rng.int(0, 59));
  const ss = pad2(rng.int(0, 59));
  return `${day} ${hh}:${mm}:${ss}`;
}

function escapeSqlString(s) {
  return String(s)
    .replace(/\\/g, '\\\\')
    .replace(/\u0000/g, '\\0')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\t/g, '\\t')
    .replace(/'/g, "\\'");
}

function sqlValue(v) {
  if (v === null || v === undefined) return 'NULL';
  if (typeof v === 'number') return Number.isFinite(v) ? String(v) : 'NULL';
  if (typeof v === 'boolean') return v ? '1' : '0';
  return `'${escapeSqlString(v)}'`;
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

function insertMany(lines, table, columns, rows, chunkSize = 250) {
  if (!rows.length) return;

  for (const part of chunk(rows, chunkSize)) {
    const valuesSql = part
      .map((r) => {
        if (r.length !== columns.length) {
          throw new Error(`Row length mismatch for ${table}: expected ${columns.length}, got ${r.length}`);
        }
        return `(${r.map(sqlValue).join(', ')})`;
      })
      .join(',\n');

    lines.push(`INSERT INTO ${table} (${columns.join(', ')}) VALUES`);
    lines.push(valuesSql + ';');
    lines.push('');
  }
}

// ---------- Data vocabularies ----------

const SECTORS = [
  'Hostelería',
  'Comercio',
  'Logística',
  'Administración',
  'Sanidad',
  'Construcción',
  'Tecnología',
  'Atención al cliente',
  'Limpieza',
  'Seguridad',
];

const DISTRICTS = [
  'Centro',
  'Tetuán',
  'Chamartín',
  'Salamanca',
  'Retiro',
  'Arganzuela',
  'Carabanchel',
  'Latina',
  'Usera',
  'Villaverde',
  'Fuencarral-El Pardo',
  'Ciudad Lineal',
  'Hortaleza',
  'Moratalaz',
  'San Blas-Canillejas',
  'Barajas',
  'Puente de Vallecas',
  'Villa de Vallecas',
  'Vicálvaro',
];

const FIRST_NAMES = [
  'Antonio',
  'María',
  'Lucía',
  'Sofía',
  'Carlos',
  'Javier',
  'Marta',
  'Paula',
  'Alejandro',
  'Daniel',
  'Laura',
  'Sara',
  'David',
  'Álvaro',
  'Carmen',
  'Elena',
  'Irene',
  'Nuria',
  'Adrián',
  'Raúl',
  'Diego',
  'Eva',
  'Noelia',
  'Víctor',
  'Hugo',
  'Ainhoa',
  'Beatriz',
  'Celia',
  'Cristina',
  'Jorge',
  'Óscar',
  'Miguel',
  'Isabel',
  'Patricia',
  'Rocío',
];

const LAST_NAMES = [
  'García',
  'Fernández',
  'González',
  'Rodríguez',
  'López',
  'Martínez',
  'Sánchez',
  'Pérez',
  'Gómez',
  'Díaz',
  'Hernández',
  'Muñoz',
  'Álvarez',
  'Romero',
  'Alonso',
  'Gutiérrez',
  'Navarro',
  'Torres',
  'Domínguez',
  'Vázquez',
  'Ramos',
  'Gil',
  'Serrano',
  'Molina',
  'Morales',
  'Ortega',
  'Delgado',
  'Castro',
  'Rubio',
  'Marín',
];

const COMPANY_ADJ = ['ALFA', 'NUEVA', 'GLOBAL', 'URBANA', 'IBÉRICA', 'NORTE', 'SUR', 'CENTRAL', 'EXPERTA', 'MODERNA'];
const COMPANY_NOUN = ['SERVICIOS', 'LOGÍSTICA', 'COMERCIO', 'SOLUCIONES', 'GESTIÓN', 'HOSTELERÍA', 'TECNOLOGÍA', 'DISTRIBUCIÓN'];

const CONTRACT_TYPES = ['Indefinido', 'Duración Determinada', 'Temporal'];
const WORKDAY_OPTIONS = ['Tiempo Completo', 'Tiempo Parcial', 'Fijo Discontínuo'];
const CONTRIBUTION_GROUPS = [
  'INGENIEROS Y LICENCIADOS  DE ALTA DIRECCIÓN',
  'INGENIEROS TÉCNICOS, PERITOS Y AYUDANTES TITULADOS',
  'JEFES ADMINISTRATIVOS Y DE TALLER',
  'AYUDANTES NO TITULADOS',
  'OFICIALES ADMINISTRATIVOS',
  'SUBALTERNOS',
  'AUXILIARES ADMINISTRATIVOS',
  'OFICIALES DE PRIMERA Y SEGUNDA',
  'OFICIALES DE TERCERA Y ESPECIALISTAS',
  'PEONES',
  'TRABAJADORES MENORES DE DIECIOCHO AÑOS, CUALQUIERA QUE SEA SU CATEGORÍA PROFESIONAL',
];

const COURSE_TITLES = [
  'Excel Básico',
  'Atención al Cliente',
  'Manipulador de Alimentos',
  'Prevención de Riesgos Laborales',
  'Logística y Almacén',
  'Inglés para el Empleo',
  'Ofimática',
  'Cocina Básica',
  'Camarero/a de Sala',
  'Carretilla Elevadora',
  'Auxiliar Administrativo',
  'Dependiente/a de Comercio',
];

const COURSE_INSTITUTIONS = ['Centro de Formación Madrid', 'Aula Digital', 'Academia Empleo', 'PRL Formación', 'Language Hub'];

const VACANCY_TITLES_BY_SECTOR = {
  'Hostelería': ['Camarero/a', 'Ayudante de cocina', 'Recepcionista hotel'],
  'Comercio': ['Dependiente/a', 'Mozo/a almacén', 'Visual merchandiser junior'],
  'Logística': ['Operario/a de almacén', 'Repartidor/a', 'Auxiliar de logística'],
  'Administración': ['Auxiliar administrativo/a', 'Recepcionista', 'Back office'],
  'Sanidad': ['Auxiliar de clínica', 'Recepcionista centro médico', 'Celador/a'],
  'Construcción': ['Peón de obra', 'Ayudante de mantenimiento', 'Operario/a'],
  'Tecnología': ['Soporte técnico', 'Helpdesk', 'Operador/a de datos'],
  'Atención al cliente': ['Teleoperador/a', 'Atención al cliente', 'Gestor/a de incidencias'],
  'Limpieza': ['Personal de limpieza', 'Operario/a limpieza', 'Cristalero/a'],
  'Seguridad': ['Auxiliar de seguridad', 'Control de accesos', 'Vigilante (sin arma)'],
};

function dniLetter(num) {
  const letters = 'TRWAGMYFPDXBNJZSQVHLCKE';
  return letters[num % 23];
}

function genDni(num) {
  const n = String(num).padStart(8, '0');
  return `${n}${dniLetter(num)}`;
}

function genCompanyNif(i) {
  // Simple unique fake NIF: B + 8 digits
  return `B${String(10000000 + i).padStart(8, '0')}`;
}

function genPhone() {
  return `+34 6${String(rng.int(0, 99)).padStart(2, '0')} ${String(rng.int(0, 999)).padStart(3, '0')} ${String(rng.int(0, 999)).padStart(3, '0')}`;
}

function genEmailSlug(s) {
  return s
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '.')
    .replace(/^\.|\.$/g, '');
}

function genStudentName(i) {
  const first = rng.pick(FIRST_NAMES);
  const second = rng.chance(0.35) ? rng.pick(FIRST_NAMES) : '';
  const last1 = rng.pick(LAST_NAMES);
  const last2 = rng.chance(0.55) ? rng.pick(LAST_NAMES) : '';

  const first_names = [first, second].filter(Boolean).join(' ');
  const last_names = [last1, last2].filter(Boolean).join(' ');

  const email = `${genEmailSlug(first)}.${genEmailSlug(last1)}${String(i).padStart(3, '0')}@example.com`;

  return { first_names, last_names, email };
}

function employmentStatus() {
  const r = rng.next();
  if (r < 0.52) return 'unemployed';
  if (r < 0.78) return 'employed';
  if (r < 0.93) return 'improved';
  return 'unknown';
}

// ---------- Generate dataset ----------

const companies = [];
for (let i = 1; i <= CONFIG.companies; i++) {
  const sector = rng.pick(SECTORS);
  const name = `${rng.pick(COMPANY_ADJ)} ${rng.pick(COMPANY_NOUN)} ${String(i).padStart(3, '0')} S.L.`;
  const nif = genCompanyNif(i);
  const slug = genEmailSlug(name);
  companies.push({
    id: i,
    nif,
    name,
    sector,
    company_email: `info@${slug}.fake`,
    company_phone: genPhone(),
    contact_name: 'RRHH',
    contact_email: `rrhh@${slug}.fake`,
    contact_phone: genPhone(),
    notes: rng.chance(0.2) ? 'Empresa colaboradora.' : null,
  });
}

const vacancies = [];
let vacancyId = 1;
for (const c of companies) {
  const count = rng.int(CONFIG.vacancies_per_company_min, CONFIG.vacancies_per_company_max);
  const titles = VACANCY_TITLES_BY_SECTOR[c.sector] || ['Operario/a', 'Auxiliar', 'Técnico/a'];
  for (let j = 0; j < count; j++) {
    const title = rng.pick(titles);
    const created_at = randDateTimeBetween(CONFIG.vacancy_created_min, CONFIG.vacancy_created_max);
    const status = rng.chance(0.72) ? 'open' : 'closed';
    vacancies.push({
      id: vacancyId++,
      company_id: c.id,
      title,
      sector: c.sector,
      description: `${title} en ${c.name}. Incorporación inmediata.`,
      requirements: rng.chance(0.7) ? 'Responsabilidad, puntualidad y ganas de aprender.' : null,
      status,
      created_at,
    });
  }
}

const students = [];
for (let i = 1; i <= CONFIG.students; i++) {
  const { first_names, last_names, email } = genStudentName(i);
  const expediente = `EXP-${String(i).padStart(6, '0')}`;
  const dni = genDni(30000000 + i);
  const ssn = `${pad2(rng.int(1, 52))} ${String(rng.int(10000000, 99999999))} ${pad2(rng.int(1, 99))}`;

  const birth_year = rng.int(1990, 2004);
  const birth_date = randDateBetween(`${birth_year}-01-01`, `${birth_year}-12-28`);
  const age = Math.max(0, 2026 - birth_year);
  const sex = rng.chance(0.52) ? 'mujer' : 'hombre';

  const district = rng.pick(DISTRICTS);
  const municipality = 'Madrid';
  const phone = `6${String(rng.int(0, 99999999)).padStart(8, '0')}`;

  students.push({
    id: i,
    expediente,
    first_names,
    last_names,
    dni_nie: dni,
    social_security_number: ssn,
    birth_date,
    age,
    sex,
    district,
    municipality,
    phone,
    email,
    employment_status: employmentStatus(),
    notes: rng.chance(0.15) ? 'Seguimiento recomendado.' : null,
  });
}

// Documents (CV)
const allStudentIds = students.map((s) => s.id);
const cvStudentIds = rng.shuffle(allStudentIds).slice(0, Math.min(CONFIG.cvs, allStudentIds.length));
const documents = cvStudentIds.map((sid) => ({
  student_id: sid,
  type: 'cv',
  url: `https://files.example.com/cv/student-${sid}.pdf`,
  uploaded_at: randDateTimeBetween('2025-11-01', '2026-02-01'),
}));

// Courses
const studentCourses = [];
for (const s of students) {
  const count = rng.int(CONFIG.courses_per_student_min, CONFIG.courses_per_student_max);
  for (let i = 0; i < count; i++) {
    const title = rng.pick(COURSE_TITLES);
    const start_date = randDateBetween('2024-01-01', '2026-01-15');
    const end_date = randDateBetween(start_date, '2026-02-01');
    studentCourses.push({
      student_id: s.id,
      title,
      description: rng.chance(0.65) ? `Formación en ${title.toLowerCase()}.` : null,
      institution: rng.pick(COURSE_INSTITUTIONS),
      start_date,
      end_date,
    });
  }
}

// PnL
const pnlRows = [];
for (const s of students) {
  const count = rng.int(CONFIG.pnl_per_student_min, CONFIG.pnl_per_student_max);
  for (let i = 0; i < count; i++) {
    const c = rng.pick(companies);
    const start_date = randDateBetween('2024-01-01', '2026-01-10');
    const end_date = rng.chance(0.85) ? randDateBetween(start_date, '2026-02-01') : null;
    pnlRows.push({
      student_id: s.id,
      company_nif: c.nif,
      company_name: c.name,
      signer_name: 'Responsable',
      signer_nif: genDni(40000000 + rng.int(1, 9999)),
      workplace: `Madrid - ${rng.pick(DISTRICTS)}`,
      position: rng.pick(['Auxiliar', 'Apoyo', 'Operario/a', 'Recepción', 'Sala', 'Caja']),
      start_date,
      end_date,
      schedule: rng.chance(0.7) ? 'L-V 09:00-13:00' : 'L-X-V 10:00-14:00',
      weekly_hours: rng.pick([10, 12, 15, 20, 25, 30]),
      observations: rng.chance(0.5) ? 'Buen desempeño y actitud.' : null,
    });
  }
}

// Interviews
const interviewRows = [];
for (const s of students) {
  const count = rng.int(CONFIG.interviews_per_student_min, CONFIG.interviews_per_student_max);
  for (let i = 0; i < count; i++) {
    const c = rng.pick(companies);
    const interview_date = randDateBetween('2025-01-01', '2026-02-01');
    const r = rng.next();
    const status = r < 0.55 ? 'sent' : r < 0.88 ? 'attended' : 'no_show';
    interviewRows.push({
      student_id: s.id,
      place: `${c.name} - RRHH`,
      interview_date,
      status,
      notes: status === 'no_show' ? 'No asistió. Reprogramar si procede.' : null,
    });
  }
}

// Hiring contracts
const contractRows = [];
for (const s of students) {
  const count = rng.int(CONFIG.contracts_per_student_min, CONFIG.contracts_per_student_max);

  for (let i = 0; i < count; i++) {
    const c = rng.pick(companies);
    let company_nif = c.nif;
    let company_name = c.name;
    let sector = c.sector;

    let start_date = randDateBetween(CONFIG.contract_start_min, CONFIG.contract_start_max);

    // Duration days (inclusive)
    const durationDays = rng.int(30, 240);
    const endCandidate = addDaysUTC(parseIsoDateUTC(start_date), durationDays - 1);
    const endCap = parseIsoDateUTC('2026-02-01');
    let end_date = endCandidate.getTime() > endCap.getTime() ? null : toIsoDate(endCandidate);

    const useWeeklyHours = rng.chance(0.75);
    let weekly_hours = useWeeklyHours ? rng.pick([20, 30, 40]) : null;
    let workday_pct = useWeeklyHours ? rng.pick(WORKDAY_OPTIONS) : rng.pick(['50%', '75%', '100%']);

    // Contributed days approximated as duration days, with small noise.
    let contributed_days = Math.max(15, Math.round(durationDays * (0.9 + rng.next() * 0.2)));

    let contribution_group = rng.pick(CONTRIBUTION_GROUPS);
    let contract_type = rng.pick(CONTRACT_TYPES);
    let notes = rng.chance(0.25) ? 'Contrato para seguimiento de inserción.' : null;

    // Guarantee: ensure the dataset can generate jornadas without exceeding 10 contracts per student.
    // We override the first contract for the first 10 students.
    if (s.id <= 10 && i === 0) {
      const fixed = companies[(s.id - 1) % companies.length];
      company_nif = fixed.nif;
      company_name = fixed.name;
      sector = fixed.sector;

      start_date = '2025-01-15';
      end_date = '2025-09-15';
      workday_pct = 'Tiempo Completo';
      weekly_hours = 40;
      contributed_days = 200;
      contribution_group = 'OFICIALES ADMINISTRATIVOS';
      contract_type = 'Duración Determinada';
      notes = 'Contrato full-time largo (dataset) para pruebas de liquidación.';
    }

    contractRows.push({
      student_id: s.id,
      company_nif,
      company_name,
      sector,
      start_date,
      end_date,
      workday_pct,
      contribution_group,
      contract_type,
      weekly_hours,
      contributed_days,
      notes,
    });
  }
}

// Invitations
const invitationRows = [];
const vacancyIds = vacancies.map((v) => v.id);
for (const s of students) {
  const count = rng.int(CONFIG.invitations_per_student_min, CONFIG.invitations_per_student_max);
  const chosen = new Set();

  while (chosen.size < Math.min(count, vacancyIds.length)) {
    chosen.add(rng.pick(vacancyIds));
  }

  for (const vid of chosen) {
    const r = rng.next();
    const status = r < 0.58 ? 'sent' : r < 0.78 ? 'accepted' : r < 0.92 ? 'rejected' : 'expired';
    const sent_at = randDateTimeBetween('2025-06-01', '2026-02-01');
    const responded_at = status === 'sent' ? null : randDateTimeBetween(sent_at.slice(0, 10), '2026-02-01');

    invitationRows.push({
      vacancy_id: vid,
      student_id: s.id,
      status,
      sent_at,
      responded_at,
    });
  }
}

// ---------- Emit SQL ----------

const lines = [];
lines.push('-- Seed grande (determinístico).');
lines.push('-- Generado por contracts-sql/scripts/generate-seed.mjs');
lines.push(`-- rng_seed=${CONFIG.rng_seed}`);
lines.push('');
lines.push('USE contracts_app;');
lines.push('');

lines.push('SET FOREIGN_KEY_CHECKS=0;');
for (const t of [
  'invitations',
  'interviews',
  'documents',
  'employment_contracts',
  'internships',
  'hiring_contracts',
  'pnl',
  'student_courses',
  'vacancies',
  'companies',
  'student_liquidation_balances',
  'liquidation_lines',
  'liquidations',
  'students',
]) {
  lines.push(`TRUNCATE TABLE ${t};`);
}
lines.push('SET FOREIGN_KEY_CHECKS=1;');
lines.push('');

insertMany(
  lines,
  'companies',
  ['nif', 'name', 'company_email', 'company_phone', 'sector', 'contact_name', 'contact_email', 'contact_phone', 'notes'],
  companies.map((c) => [c.nif, c.name, c.company_email, c.company_phone, c.sector, c.contact_name, c.contact_email, c.contact_phone, c.notes]),
  100
);

insertMany(
  lines,
  'vacancies',
  ['company_id', 'title', 'sector', 'description', 'requirements', 'status', 'created_at'],
  vacancies.map((v) => [v.company_id, v.title, v.sector, v.description, v.requirements, v.status, v.created_at]),
  200
);

insertMany(
  lines,
  'students',
  [
    'expediente',
    'first_names',
    'last_names',
    'dni_nie',
    'social_security_number',
    'birth_date',
    'age',
    'sex',
    'district',
    'municipality',
    'phone',
    'email',
    'employment_status',
    'notes',
  ],
  students.map((s) => [
    s.expediente,
    s.first_names,
    s.last_names,
    s.dni_nie,
    s.social_security_number,
    s.birth_date,
    s.age,
    s.sex,
    s.district,
    s.municipality,
    s.phone,
    s.email,
    s.employment_status,
    s.notes,
  ]),
  200
);

insertMany(
  lines,
  'documents',
  ['student_id', 'type', 'url', 'uploaded_at'],
  documents.map((d) => [d.student_id, d.type, d.url, d.uploaded_at]),
  250
);

insertMany(
  lines,
  'student_courses',
  ['student_id', 'title', 'description', 'institution', 'start_date', 'end_date'],
  studentCourses.map((c) => [c.student_id, c.title, c.description, c.institution, c.start_date, c.end_date]),
  250
);

insertMany(
  lines,
  'pnl',
  [
    'student_id',
    'company_nif',
    'company_name',
    'signer_name',
    'signer_nif',
    'workplace',
    'position',
    'start_date',
    'end_date',
    'schedule',
    'weekly_hours',
    'observations',
  ],
  pnlRows.map((p) => [
    p.student_id,
    p.company_nif,
    p.company_name,
    p.signer_name,
    p.signer_nif,
    p.workplace,
    p.position,
    p.start_date,
    p.end_date,
    p.schedule,
    p.weekly_hours,
    p.observations,
  ]),
  200
);

insertMany(
  lines,
  'interviews',
  ['student_id', 'place', 'interview_date', 'status', 'notes'],
  interviewRows.map((i) => [i.student_id, i.place, i.interview_date, i.status, i.notes]),
  250
);

insertMany(
  lines,
  'hiring_contracts',
  [
    'student_id',
    'company_nif',
    'company_name',
    'sector',
    'start_date',
    'end_date',
    'workday_pct',
    'contribution_group',
    'contract_type',
    'weekly_hours',
    'contributed_days',
    'notes',
  ],
  contractRows.map((c) => [
    c.student_id,
    c.company_nif,
    c.company_name,
    c.sector,
    c.start_date,
    c.end_date,
    c.workday_pct,
    c.contribution_group,
    c.contract_type,
    c.weekly_hours,
    c.contributed_days,
    c.notes,
  ]),
  200
);

insertMany(
  lines,
  'invitations',
  ['vacancy_id', 'student_id', 'status', 'sent_at', 'responded_at'],
  invitationRows.map((i) => [i.vacancy_id, i.student_id, i.status, i.sent_at, i.responded_at]),
  250
);

fs.mkdirSync(path.dirname(OUT_FILE), { recursive: true });
fs.writeFileSync(OUT_FILE, lines.join('\n') + '\n', 'utf8');

const counts = {
  companies: companies.length,
  vacancies: vacancies.length,
  students: students.length,
  documents: documents.length,
  student_courses: studentCourses.length,
  pnl: pnlRows.length,
  interviews: interviewRows.length,
  hiring_contracts: contractRows.length,
  invitations: invitationRows.length,
};

// eslint-disable-next-line no-console
console.log(`Generated ${path.relative(process.cwd(), OUT_FILE)}`);
// eslint-disable-next-line no-console
console.log(counts);
