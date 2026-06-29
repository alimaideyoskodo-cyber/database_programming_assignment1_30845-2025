-- ============================================================
-- Assignment I: CTEs & SQL Window Functions
-- Course: C11665 - DPR400210: Database Programming
-- Instructor: Eric Maniraguha | UNILAK
-- Business Scenario: Hospital Management System
-- ============================================================

-- ============================================================
-- DROP TABLES (for clean re-runs)
-- ============================================================
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS departments;

-- ============================================================
-- CREATE TABLES
-- ============================================================

-- Department table
CREATE TABLE departments (
    department_id   INT           PRIMARY KEY,
    dept_name       VARCHAR(100)  NOT NULL,
    location        VARCHAR(100),
    budget          DECIMAL(12,2)
);

-- Doctors table
CREATE TABLE doctors (
    doctor_id       INT           PRIMARY KEY,
    full_name       VARCHAR(100)  NOT NULL,
    specialization  VARCHAR(100),
    department_id   INT           NOT NULL,
    hire_date       DATE,
    salary          DECIMAL(10,2),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Patients table
CREATE TABLE patients (
    patient_id      INT           PRIMARY KEY,
    full_name       VARCHAR(100)  NOT NULL,
    date_of_birth   DATE,
    gender          CHAR(1),          -- 'M' or 'F'
    phone           VARCHAR(20),
    city            VARCHAR(80)
);

-- Appointments table
CREATE TABLE appointments (
    appointment_id  INT           PRIMARY KEY,
    patient_id      INT           NOT NULL,
    doctor_id       INT           NOT NULL,
    appointment_date DATE         NOT NULL,
    diagnosis       VARCHAR(200),
    treatment_cost  DECIMAL(10,2),
    status          VARCHAR(20)   DEFAULT 'Completed', -- Completed | Pending | Cancelled
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id)
);

-- ============================================================
-- SEED DATA — Departments
-- ============================================================
INSERT INTO departments VALUES
(1, 'Cardiology',     'Block A', 500000.00),
(2, 'Neurology',      'Block B', 450000.00),
(3, 'Orthopedics',    'Block C', 380000.00),
(4, 'Pediatrics',     'Block D', 420000.00),
(5, 'General Surgery','Block E', 600000.00);

-- ============================================================
-- SEED DATA — Doctors
-- ============================================================
INSERT INTO doctors VALUES
(1,  'Dr. Alice Uwimana',    'Cardiologist',    1, '2018-03-15', 95000.00),
(2,  'Dr. Bob Nkurunziza',   'Neurologist',     2, '2019-07-22', 88000.00),
(3,  'Dr. Carol Mukamana',   'Orthopedist',     3, '2020-01-10', 82000.00),
(4,  'Dr. David Habimana',   'Pediatrician',    4, '2017-11-05', 78000.00),
(5,  'Dr. Eva Nsengimana',   'General Surgeon', 5, '2016-06-30', 102000.00),
(6,  'Dr. Frank Bizimana',   'Cardiologist',    1, '2021-02-14', 91000.00),
(7,  'Dr. Grace Kayitesi',   'Neurologist',     2, '2022-09-01', 84000.00),
(8,  'Dr. Henry Niyonzima',  'Pediatrician',    4, '2015-04-18', 80000.00);

-- ============================================================
-- SEED DATA — Patients
-- ============================================================
INSERT INTO patients VALUES
(1,  'Jean Bosco Ntwari',   '1985-04-12', 'M', '0781234567', 'Kigali'),
(2,  'Marie Claire Uwase',  '1990-08-23', 'F', '0782345678', 'Huye'),
(3,  'Patrick Nshimiyimana','1978-12-01', 'M', '0783456789', 'Musanze'),
(4,  'Solange Mukeshimana', '2000-03-17', 'F', '0784567890', 'Kigali'),
(5,  'Emmanuel Habyarimana','1965-07-09', 'M', '0785678901', 'Rubavu'),
(6,  'Claudine Ingabire',   '1995-11-30', 'F', '0786789012', 'Kigali'),
(7,  'Alexis Niyonshuti',   '1982-05-25', 'M', '0787890123', 'Nyagatare'),
(8,  'Vestine Uwineza',     '2005-01-14', 'F', '0788901234', 'Kigali'),
(9,  'Didier Ndagijimana',  '1970-09-08', 'M', '0789012345', 'Muhanga'),
(10, 'Anitha Mukamazimpaka','1988-06-20', 'F', '0780123456', 'Kigali');

-- ============================================================
-- SEED DATA — Appointments
-- ============================================================
INSERT INTO appointments VALUES
(1,  1,  1, '2026-01-05', 'Hypertension',         150000.00, 'Completed'),
(2,  2,  2, '2026-01-10', 'Migraine',              120000.00, 'Completed'),
(3,  3,  3, '2026-01-15', 'Knee Fracture',         250000.00, 'Completed'),
(4,  4,  4, '2026-01-20', 'Common Cold',            45000.00, 'Completed'),
(5,  5,  5, '2026-01-25', 'Appendicitis',          300000.00, 'Completed'),
(6,  6,  1, '2026-02-03', 'Arrhythmia',            175000.00, 'Completed'),
(7,  7,  6, '2026-02-08', 'Heart Failure',         210000.00, 'Completed'),
(8,  8,  7, '2026-02-12', 'Epilepsy',              195000.00, 'Completed'),
(9,  9,  2, '2026-02-18', 'Stroke',                280000.00, 'Completed'),
(10, 10, 8, '2026-02-22', 'Fever',                  55000.00, 'Completed'),
(11, 1,  5, '2026-03-01', 'Hernia',                220000.00, 'Completed'),
(12, 2,  3, '2026-03-05', 'Spinal Disc',           240000.00, 'Completed'),
(13, 3,  1, '2026-03-10', 'Coronary Artery Disease',195000.00,'Completed'),
(14, 4,  4, '2026-03-15', 'Asthma',                 85000.00, 'Completed'),
(15, 5,  6, '2026-03-20', 'Atrial Fibrillation',   160000.00, 'Completed'),
(16, 6,  7, '2026-04-02', 'Parkinson Disease',     215000.00, 'Completed'),
(17, 7,  2, '2026-04-07', 'Alzheimers',            200000.00, 'Completed'),
(18, 8,  8, '2026-04-11', 'Malnutrition',           70000.00, 'Completed'),
(19, 9,  5, '2026-04-16', 'Gallstones',            310000.00, 'Completed'),
(20, 10, 3, '2026-04-20', 'Hip Replacement',       350000.00, 'Pending'),
(21, 1,  6, '2026-05-02', 'Heart Check-up',        100000.00, 'Completed'),
(22, 2,  1, '2026-05-06', 'Hypertension Follow-up',130000.00, 'Completed'),
(23, 3,  4, '2026-05-10', 'Child Vaccination',      30000.00, 'Cancelled'),
(24, 4,  5, '2026-05-14', 'Laparoscopy',           275000.00, 'Completed'),
(25, 5,  2, '2026-05-18', 'Nerve Pain',            145000.00, 'Completed');

-- Verify row counts
SELECT 'departments' AS tbl, COUNT(*) AS rows FROM departments
UNION ALL
SELECT 'doctors',     COUNT(*) FROM doctors
UNION ALL
SELECT 'patients',    COUNT(*) FROM patients
UNION ALL
SELECT 'appointments',COUNT(*) FROM appointments;
