# Hospital Management System — CTEs & SQL Window Functions

**Course:** C11665 - DPR400210: Database Programming  
**Instructor:** Eric Maniraguha | UNILAK  
**Assignment:** Individual Assignment I  

---

## Business Problem

A private hospital in Kigali needs a database system to track **departments, doctors, patients, and appointments**. Management wants to:

- Monitor departmental revenue vs budget
- Identify top-performing doctors
- Analyse patient visit history and spending patterns
- Support data-driven decisions using advanced SQL analytics

---

## Database Schema

| Table | Description |
|---|---|
| `departments` | Hospital departments (Cardiology, Neurology, etc.) |
| `doctors` | Doctor profiles linked to departments |
| `patients` | Patient demographics |
| `appointments` | Patient–doctor visit records with cost and diagnosis |

### ER Diagram (Text Representation)

```
departments (department_id PK)
    │
    └──< doctors (doctor_id PK, department_id FK)
              │
              └──< appointments (appointment_id PK, doctor_id FK, patient_id FK)
                        │
              patients (patient_id PK) >──┘
```

---

## Files

| File | Contents |
|---|---|
| `01_schema_and_data.sql` | CREATE TABLE statements + INSERT seed data |
| `02_part_A_CTEs.sql` | All 5 CTE implementations |
| `03_part_B_window_functions.sql` | All window function implementations |
| `04_analysis.sql` | Descriptive, Diagnostic & Prescriptive analysis |

---

## Part A — CTE Implementations

| # | Type | Purpose |
|---|---|---|
| A1 | Simple CTE | Flag appointments above average cost |
| A2 | Multiple CTEs | Department revenue vs budget comparison |
| A3 | Recursive CTE | Patient age group segmentation |
| A4 | CTE + Aggregation | Doctor revenue ranking |
| A5 | CTE + JOINs | 360° patient visit history |

---

## Part B — Window Function Implementations

### Ranking Functions
| Function | Query Purpose |
|---|---|
| `ROW_NUMBER()` | Unique rank of appointments per doctor by cost |
| `RANK()` | Patient spending rank (with gaps on ties) |
| `DENSE_RANK()` | Doctor revenue rank within department (no gaps) |
| `PERCENT_RANK()` | Percentile position of each appointment cost |

### Aggregate Window Functions
| Function | Query Purpose |
|---|---|
| `SUM() OVER()` | Running total cost per department |
| `AVG() OVER()` | Department average cost per appointment row |
| `MIN() OVER()` | Global minimum cost (all appointments) |
| `MAX() OVER()` | Global maximum cost (all appointments) |

### Navigation Functions
| Function | Query Purpose |
|---|---|
| `LAG()` | Previous visit cost for each patient |
| `LEAD()` | Next scheduled visit cost and date |

### Distribution Functions
| Function | Query Purpose |
|---|---|
| `NTILE(4)` | Segment appointments into cost quartiles |
| `CUME_DIST()` | Cumulative cost distribution percentage |

---

## Analysis & Findings

### Descriptive Analysis (What happened?)
- General Surgery generated the highest revenue despite handling fewer appointments — driven by high-cost procedures like appendicitis and gallstone surgery.
- Most patients are adults (30–49), making this the primary demographic to serve.
- Hypertension and neurological conditions are among the most frequent diagnoses.

### Diagnostic Analysis (Why did it happen?)
- Top revenue doctors (e.g. Dr. Eva Nsengimana) specialise in high-cost surgical procedures.
- Repeated diagnoses for the same patient indicate chronic disease management gaps.
- Cancelled and pending appointments represent revenue leakage that should be minimised.

### Prescriptive Analysis (What actions should be taken?)
- **Under-utilised doctors** should have their schedules reviewed and appointment slots opened to the public.
- **High-spending patients** (top quartile) should be enrolled in the hospital's insurance/welfare programme.
- **Departments with deficits** should review operating costs and increase patient throughput.

---

## How to Run

1. Open any SQL client (MySQL Workbench, DBeaver, VS Code with SQLTools)
2. Create a new database: `CREATE DATABASE hospital_db; USE hospital_db;`
3. Run files in order:
   ```
   01_schema_and_data.sql
   02_part_A_CTEs.sql
   03_part_B_window_functions.sql
   04_analysis.sql
   ```

---

## References

- MySQL 8.0 Documentation — Window Functions: https://dev.mysql.com/doc/refman/8.0/en/window-functions.html
- MySQL 8.0 Documentation — CTEs: https://dev.mysql.com/doc/refman/8.0/en/with.html
- Course materials — DPR400210, UNILAK 2026

---

## Academic Integrity Statement

I confirm that this submission is my own original work. I have not copied any part of this project from classmates or online repositories. All SQL queries were written and tested independently in accordance with UNILAK's academic integrity policy.
