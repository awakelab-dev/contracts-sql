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
  courses_per_student_min: 1,
  courses_per_student_max: 3,
  invitations_per_student_min: 3,
  invitations_per_student_max: 7,
  interviews_per_student_min: 1,
  interviews_per_student_max: 3,
  contracts_per_student_min: 2,
  contracts_per_student_max: 10,

  // Contract date bounds (YYYY-MM-DD) for generated employment_contracts.
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

const MUNICIPALITY_DEFINITIONS = [
  { name: 'Madrid', districts: DISTRICTS },
  { name: 'Alcalá de Henares', districts: ['Centro', 'Reyes Católicos', 'Espartales'] },
  { name: 'Móstoles', districts: ['Centro', 'Norte Universidad'] },
  { name: 'Getafe', districts: ['Centro', 'Sector III'] },
  { name: 'Alcorcón', districts: ['Centro', 'Parque Lisboa'] },
  { name: 'Leganés', districts: ['Centro', 'Zarzaquemada'] },
  { name: 'Fuenlabrada', districts: ['Centro', 'Loranca'] },
  { name: 'Alcobendas', districts: ['Centro', 'Valdelasfuentes'] },
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

const CONTRACT_CODES = [
  { code: 100, contract_type: 'INDEFINIDO', workday: 'TIEMPO COMPLETO', hiring_mode: 'ORDINARIO' },
  { code: 109, contract_type: 'INDEFINIDO', workday: 'TIEMPO COMPLETO', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 130, contract_type: 'INDEFINIDO', workday: 'TIEMPO COMPLETO', hiring_mode: 'DISCAPACITADOS' },
  { code: 139, contract_type: 'INDEFINIDO', workday: 'TIEMPO COMPLETO', hiring_mode: 'DISCAPACITADOS' },
  { code: 150, contract_type: 'INDEFINIDO', workday: 'TIEMPO COMPLETO', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 189, contract_type: 'INDEFINIDO', workday: 'TIEMPO COMPLETO', hiring_mode: '' },
  { code: 200, contract_type: 'INDEFINIDO', workday: 'TIEMPO PARCIAL', hiring_mode: 'ORDINARIO' },
  { code: 209, contract_type: 'INDEFINIDO', workday: 'TIEMPO PARCIAL', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 230, contract_type: 'INDEFINIDO', workday: 'TIEMPO PARCIAL', hiring_mode: 'DISCAPACITADOS' },
  { code: 239, contract_type: 'INDEFINIDO', workday: 'TIEMPO PARCIAL', hiring_mode: 'DISCAPACITADOS' },
  { code: 250, contract_type: 'INDEFINIDO', workday: 'TIEMPO PARCIAL', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 289, contract_type: 'INDEFINIDO', workday: 'TIEMPO PARCIAL', hiring_mode: '' },
  { code: 300, contract_type: 'INDEFINIDO', workday: 'FIJO DISCONTINUO', hiring_mode: '' },
  { code: 309, contract_type: 'INDEFINIDO', workday: 'FIJO DISCONTINUO', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 330, contract_type: 'INDEFINIDO', workday: 'FIJO DISCONTINUO', hiring_mode: 'DISCAPACITADOS' },
  { code: 339, contract_type: 'INDEFINIDO', workday: 'FIJO DISCONTINUO', hiring_mode: 'DISCAPACITADOS' },
  { code: 350, contract_type: 'INDEFINIDO', workday: 'FIJO DISCONTINUO', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 389, contract_type: 'INDEFINIDO', workday: 'FIJO DISCONTINUO', hiring_mode: '' },
  { code: 401, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO COMPLETO', hiring_mode: 'OBRAO SERVICIO DETERMINADO' },
  { code: 402, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO COMPLETO', hiring_mode: 'EVENTUALPOR CIRCUNSTANCIAS DE LAPRODUCCIÓN' },
  { code: 403, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO COMPLETO', hiring_mode: 'INSERCIÓN' },
  { code: 408, contract_type: 'TEMPORAL', workday: 'TIEMPO COMPLETO', hiring_mode: '' },
  { code: 410, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO COMPLETO', hiring_mode: 'INTERINIDAD' },
  { code: 418, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO COMPLETO', hiring_mode: 'INTERINIDAD' },
  { code: 420, contract_type: 'TEMPORAL', workday: 'TIEMPO COMPLETO', hiring_mode: 'PRÁCTICAS' },
  { code: 421, contract_type: 'TEMPORAL', workday: 'TIEMPO COMPLETO', hiring_mode: 'FORMACIÓN' },
  { code: 430, contract_type: 'TEMPORAL', workday: 'TIEMPO COMPLETO', hiring_mode: 'DISCAPACITADOS' },
  { code: 441, contract_type: 'TEMPORAL', workday: 'TIEMPO COMPLETO', hiring_mode: 'RELEVO' },
  { code: 450, contract_type: 'TEMPORAL', workday: 'TIEMPO COMPLETO', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 452, contract_type: 'TEMPORAL', workday: 'TIEMPO COMPLETO', hiring_mode: 'DESEMPLEADOS EMPRESAS DE INSERCIÓN' },
  { code: 501, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO PARCIAL', hiring_mode: 'OBRAO SERVICIO DETERMINADO' },
  { code: 502, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO PARCIAL', hiring_mode: 'EVENTUALPOR CIRCUNSTANCIAS DE LAPRODUCCIÓN' },
  { code: 503, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO PARCIAL', hiring_mode: 'INSERCIÓN' },
  { code: 508, contract_type: 'TEMPORAL', workday: 'TIEMPO PARCIAL', hiring_mode: '' },
  { code: 510, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO PARCIAL', hiring_mode: 'INTERINIDAD' },
  { code: 518, contract_type: 'DURACIÓN DETERMINADA', workday: 'TIEMPO PARCIAL', hiring_mode: 'INTERINIDAD' },
  { code: 520, contract_type: 'TEMPORAL', workday: 'TIEMPO PARCIAL', hiring_mode: 'PRÁCTICAS' },
  { code: 530, contract_type: 'TEMPORAL', workday: 'TIEMPO PARCIAL', hiring_mode: 'DISCAPACITADOS' },
  { code: 540, contract_type: 'TEMPORAL', workday: 'TIEMPO PARCIAL', hiring_mode: 'JUBILADO PARCIAL' },
  { code: 541, contract_type: 'TEMPORAL', workday: 'TIEMPO PARCIAL', hiring_mode: 'RELEVO' },
  { code: 550, contract_type: 'TEMPORAL', workday: 'TIEMPO PARCIAL', hiring_mode: 'FOMENTO CONTRATACIÓN INDEFINIDA/EMPLEO ESTABLE' },
  { code: 552, contract_type: 'TEMPORAL', workday: 'TIEMPO PARCIAL', hiring_mode: 'DESEMPLEADOS CONTRATADOS POR EMPRESAS DE INSERCIÓN' },
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

const COURSE_ITINERARIES = [
  ['25EMHA01', 'AYUDANTE DE CAMARERO'],
  ['25EMHA02', 'AYUDANTE DE COCINA'],
  ['25EMHA03', 'AYUDANTE DE COCINA'],
  ['25EMHA04', 'AYUDANTE DE COCINA'],
  ['25EMHA05', 'AYUDANTE DE CAMARERO'],
  ['25EMHA06', 'AYUDANTE DE COCINA'],
  ['25EMHA07', 'AYUDANTE DE COCINA'],
  ['25EMHA08', 'ATENCION AL CLIENTE EN BARRA Y TIENDA'],
  ['25EMHA09', 'CdP OPERACIONES BÁSICAS COCINA'],
  ['25EMHA10', 'COCINA AVANZADA'],
  ['25EMHA11', 'SERVICIO DE SALA ESPECIALIZADO'],
  ['25EMHA13', 'AYUDANTE DE CAMARERO'],
  ['25EMHA14', 'OPERARIO DE DESPIECE'],
  ['25EMHA15', 'AYUDANTE DE COCINA'],
  ['25EMHA16', 'AYUDANTE DE CATERING'],
  ['25EMHA17', 'OPERARIO DE CARNICERIA'],
  ['25EMHA18', 'OPERARIO DE PESCADERIA'],
  ['25EMHA20', 'AYUDANTE BARRA Y SALA PASTELERÍA'],
  ['25EMHA21', 'AYUDANTE DE COCINA'],
  ['25EMHA22', 'AYUDANTE DE COCINA'],
  ['25EMHA23', 'AYUDANTE BARRA PASTELERIA'],
  ['25EMHA24', 'AYUDANTE BARRA PASTELERIA'],
  ['25EMHA25', 'AYUDANTE CAMARERO'],
  ['25EMHA26', 'AYUDANTE PANADERÍA Y PASTELERÍA'],
  ['25EMHA27', 'AYUDANTE PANADERÍA Y PASTELERÍA'],
  ['25EMHA28', 'OPERARIO DE CARNICERIA'],
  ['25EMHA29', 'AYUDANTE COCINA'],
  ['26EMHA01', 'AYUDANTE COCINA'],
  ['26EMHA02', 'AYUDANTE COCINA'],
  ['26EMHA03', 'AYUDANTE PANADERÍA Y PASTELERÍA'],
  ['26EMHA04', 'AYUDANTE SALA Y BARRA'],
  ['26EMHA05', 'AYUDANTE DE CARNICERIA'],
  ['26EMHA06', 'AYUDANTE COCINA Y SERVICIO DE MOSTRADOR'],
  ['26EMHA07', 'ATENCIÓN AL CLIENTE EN SERVICIO DE BARRA Y TIENDA'],
  ['26EMHA08', 'ELABORACION DE PLATOS, FAST FOOD Y CATERING'],
  ['26EMHA09', 'AYUDANTE PANADERIA Y PASTELERIA'],
  ['26EMHA10', 'AYUDANTE SALA Y BARRA'],
  ['26EMHA11', 'AYUDANTE COCINA'],
  ['26EMHA12', 'OPERARIO DE CARNICERIA'],
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
const sectors = SECTORS.map((sector_name, index) => ({
  id: index + 1,
  sector_name,
}));
const sectorIdByName = new Map(sectors.map((s) => [s.sector_name, s.id]));
const companies = [];
for (let i = 1; i <= CONFIG.companies; i++) {
  const sector = rng.pick(SECTORS);
  const sector_id = sectorIdByName.get(sector) ?? null;
  const name = `${rng.pick(COMPANY_ADJ)} ${rng.pick(COMPANY_NOUN)} ${String(i).padStart(3, '0')} S.L.`;
  const cif = genCompanyNif(i);
  const slug = genEmailSlug(name);
  companies.push({
    id: i,
    cif,
    name,
    fiscal_name: name,
    sector,
    sector_id,
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

const municipalityCatalog = MUNICIPALITY_DEFINITIONS.map((municipality, index) => ({
  code: index + 1,
  name: municipality.name,
}));

const municipalityCodeByName = new Map(municipalityCatalog.map((m) => [m.name, m.code]));

const districtCatalog = [];
let districtCode = 1;
for (const municipality of MUNICIPALITY_DEFINITIONS) {
  const municipality_code = municipalityCodeByName.get(municipality.name);
  if (!municipality_code) continue;
  for (const districtName of municipality.districts) {
    districtCatalog.push({
      code: districtCode++,
      municipality_code,
      name: districtName,
    });
  }
}

const districtsByMunicipalityCode = new Map();
for (const district of districtCatalog) {
  const list = districtsByMunicipalityCode.get(district.municipality_code) || [];
  list.push(district);
  districtsByMunicipalityCode.set(district.municipality_code, list);
}

const students = [];
for (let i = 1; i <= CONFIG.students; i++) {
  const { first_names, last_names, email } = genStudentName(i);
  const dni = genDni(30000000 + i);
  const ssn = `${pad2(rng.int(1, 52))} ${String(rng.int(10000000, 99999999))} ${pad2(rng.int(1, 99))}`;

  const birth_year = rng.int(1990, 2004);
  const birth_date = randDateBetween(`${birth_year}-01-01`, `${birth_year}-12-28`);
  const sex = rng.chance(0.52) ? 'mujer' : 'hombre';
  const municipality =
    rng.chance(0.7) ? municipalityCatalog[0] : rng.pick(municipalityCatalog.slice(1));
  const municipalityDistricts =
    districtsByMunicipalityCode.get(municipality.code) || districtCatalog;
  const district = rng.pick(municipalityDistricts);
  const phone = `6${String(rng.int(0, 99999999)).padStart(8, '0')}`;

  students.push({
    id: i,
    first_names,
    last_names,
    dni_nie: dni,
    social_security_number: ssn,
    birth_date,
    sex,
    district_code: district.code,
    municipality_code: municipality.code,
    phone,
    email,
    notes: rng.chance(0.15) ? 'Seguimiento recomendado.' : null,
  });
}

const courseItineraryStudents = [];
let expedienteSeq = 1;
for (const student of students) {
  const enrollments = rng.chance(0.35) ? 2 : 1;
  const chosenCourseCodes = new Set();
  while (chosenCourseCodes.size < enrollments) {
    chosenCourseCodes.add(rng.pick(COURSE_ITINERARIES)[0]);
  }
  for (const course_code of chosenCourseCodes) {
    const expediente = `${course_code}_${String(expedienteSeq).padStart(4, '0')}`;
    expedienteSeq += 1;
    courseItineraryStudents.push({
      course_code,
      expediente,
      dni_nie: student.dni_nie,
    });
  }
}
const studentIdByDniNie = new Map(students.map((student) => [student.dni_nie, student.id]));
const expedientesByStudentId = new Map();
for (const row of courseItineraryStudents) {
  const sid = studentIdByDniNie.get(row.dni_nie);
  if (!sid) continue;
  const current = expedientesByStudentId.get(sid) || [];
  current.push(row.expediente);
  expedientesByStudentId.set(sid, current);
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

// Practices
const practicesRows = [];
for (const enrollment of courseItineraryStudents) {
  const modeRoll = rng.next();
  const does_practices = modeRoll < 0.14 ? 'NO' : modeRoll < 0.22 ? 'INSERCION' : 'SI';
  const company = rng.pick(companies);

  let company_id = null;
  let company_name = null;
  let workplace = null;
  let start_date = null;
  let end_date = null;
  let attendance_days = null;
  let schedule = null;
  let evaluation = null;
  let practice_status = null;
  let leave_date = null;

  const conditions_for_practice = rng.pick(['DESEMPLEADO', 'MEJORA DE EMPLEO']);
  const practice_shift = rng.pick(['MAÑANA', 'TARDE', 'INDIFERENTE']);
  const observations = rng.chance(0.25) ? 'Seguimiento de prácticas.' : null;

  if (does_practices === 'SI') {
    company_id = company.id;
    company_name = company.name;
    workplace = `Madrid - ${rng.pick(DISTRICTS)}`;
    start_date = randDateBetween('2024-01-01', '2026-01-10');
    end_date = rng.chance(0.9) ? randDateBetween(start_date, '2026-02-01') : null;
    attendance_days = rng.pick([8, 9, 10, 12, 16]);
    schedule = rng.chance(0.7) ? 'L-V 09:00-14:00' : 'L-V 15:00-20:00';
    if (rng.chance(0.18)) {
      practice_status = 'INTERRUMPIDAS';
      leave_date = end_date || start_date;
      evaluation = 'ABANDONO DE LAS PRÁCTICAS';
    } else {
      practice_status = 'FINALIZADAS';
      evaluation = 'PRACTICAS SUPERADAS';
    }
  } else if (does_practices === 'INSERCION') {
    practice_status = 'INSERCION FORMACION';
  } else {
    practice_status = rng.chance(0.55) ? 'NO REALIZA PRACTICAS' : 'NO APTO FORMACION';
  }

  practicesRows.push({
    expediente: enrollment.expediente,
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
    leave_date,
  });
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

// Employment contracts
const contractRows = [];
for (const s of students) {
  const count = rng.int(CONFIG.contracts_per_student_min, CONFIG.contracts_per_student_max);
  const studentExpedientes = expedientesByStudentId.get(s.id) || [];
  if (!studentExpedientes.length) continue;

  for (let i = 0; i < count; i++) {
    const c = rng.pick(companies);
    const contractCode = rng.pick(CONTRACT_CODES);
    const expediente = rng.pick(studentExpedientes);
    const sector_id = c.sector_id;
    const position = rng.pick(VACANCY_TITLES_BY_SECTOR[c.sector] || ['Operario/a']);
    const company_id = c.id;

    let start_date = randDateBetween(CONFIG.contract_start_min, CONFIG.contract_start_max);
    let end_date = null;
    let is_itinerary_company_contract = rng.chance(0.55) ? 'SI' : 'NO';
    let contract_code = contractCode.code;
    let attached_contract = rng.chance(0.78) ? 'SI' : 'NO';
    let attached_work_life = rng.chance(0.7) ? 'SI' : 'NO';
    let observations = rng.chance(0.25) ? 'Contrato para seguimiento de inserción.' : null;

    // Duration days (inclusive)
    const durationDays = rng.int(30, 240);
    const endCandidate = addDaysUTC(parseIsoDateUTC(start_date), durationDays - 1);
    const endCap = parseIsoDateUTC('2026-02-01');
    end_date = endCandidate.getTime() > endCap.getTime() ? null : toIsoDate(endCandidate);

    // Guarantee: ensure the dataset can generate jornadas without exceeding 10 contracts per student.
    // We override the first contract for the first 10 students.
    if (s.id <= 10 && i === 0) {

      start_date = '2025-01-15';
      end_date = '2025-09-15';
      is_itinerary_company_contract = 'SI';
      attached_contract = 'SI';
      attached_work_life = 'SI';
      contract_code = 100;
      observations = 'Contrato largo (dataset) para pruebas de liquidación.';
    }

    contractRows.push({
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
      end_date,
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
  'practices',
  'student_courses',
  'course_itinerary_students',
  'course_itineraries',
  'vacancies',
  'companies',
  'sectors',
  'contract_codes',
  'student_liquidation_balances',
  'liquidation_lines',
  'liquidations',
  'students',
  'municipalities',
  'districts',
]) {
  lines.push(`TRUNCATE TABLE ${t};`);
}
lines.push('SET FOREIGN_KEY_CHECKS=1;');
lines.push('');

insertMany(
  lines,
  'sectors',
  ['id', 'sector_name'],
  sectors.map((s) => [s.id, s.sector_name]),
  100
);
insertMany(
  lines,
  'contract_codes',
  ['code', 'contract_type', 'workday', 'hiring_mode'],
  CONTRACT_CODES.map((c) => [c.code, c.contract_type, c.workday, c.hiring_mode]),
  200
);

insertMany(
  lines,
  'companies',
  ['id', 'cif', 'name', 'fiscal_name', 'sector_id', 'company_email', 'company_phone', 'contact_name', 'contact_email', 'contact_phone', 'notes'],
  companies.map((c) => [c.id, c.cif, c.name, c.fiscal_name, c.sector_id, c.company_email, c.company_phone, c.contact_name, c.contact_email, c.contact_phone, c.notes]),
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
  'course_itineraries',
  ['course_code', 'itinerary_name'],
  COURSE_ITINERARIES.map(([course_code, itinerary_name]) => [
    course_code,
    itinerary_name,
  ]),
  200
);
insertMany(
  lines,
  'municipalities',
  ['code', 'name'],
  municipalityCatalog.map((municipality) => [municipality.code, municipality.name]),
  100
);

insertMany(
  lines,
  'districts',
  ['code', 'municipality_code', 'name'],
  districtCatalog.map((district) => [district.code, district.municipality_code, district.name]),
  100
);

insertMany(
  lines,
  'students',
  [
    'first_names',
    'last_names',
    'dni_nie',
    'social_security_number',
    'birth_date',
    'sex',
    'district_code',
    'municipality_code',
    'phone',
    'email',
    'notes',
  ],
  students.map((s) => [
    s.first_names,
    s.last_names,
    s.dni_nie,
    s.social_security_number,
    s.birth_date,
    s.sex,
    s.district_code,
    s.municipality_code,
    s.phone,
    s.email,
    s.notes,
  ]),
  200
);

insertMany(
  lines,
  'course_itinerary_students',
  ['course_code', 'expediente', 'dni_nie'],
  courseItineraryStudents.map((row) => [row.course_code, row.expediente, row.dni_nie]),
  250
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
  'practices',
  [
    'expediente',
    'company_id',
    'company_name',
    'workplace',
    'does_practices',
    'conditions_for_practice',
    'practice_shift',
    'observations',
    'start_date',
    'end_date',
    'attendance_days',
    'schedule',
    'evaluation',
    'practice_status',
    'leave_date',
  ],
  practicesRows.map((p) => [
    p.expediente,
    p.company_id,
    p.company_name,
    p.workplace,
    p.does_practices,
    p.conditions_for_practice,
    p.practice_shift,
    p.observations,
    p.start_date,
    p.end_date,
    p.attendance_days,
    p.schedule,
    p.evaluation,
    p.practice_status,
    p.leave_date,
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
  'employment_contracts',
  [
    'expediente',
    'sector_id',
    'position',
    'company_id',
    'is_itinerary_company_contract',
    'contract_code',
    'attached_contract',
    'attached_work_life',
    'observations',
    'start_date',
    'end_date',
  ],
  contractRows.map((c) => [
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
    c.end_date,
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
  sectors: sectors.length,
  companies: companies.length,
  vacancies: vacancies.length,
  students: students.length,
  documents: documents.length,
  student_courses: studentCourses.length,
  practices: practicesRows.length,
  interviews: interviewRows.length,
  employment_contracts: contractRows.length,
  invitations: invitationRows.length,
};

// eslint-disable-next-line no-console
console.log(`Generated ${path.relative(process.cwd(), OUT_FILE)}`);
// eslint-disable-next-line no-console
console.log(counts);
