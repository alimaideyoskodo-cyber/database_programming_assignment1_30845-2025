-- ============================================================
-- PART B: SQL Window Functions
-- Business Scenario: Hospital Management System
-- ============================================================


-- ============================================================
-- B1. RANKING FUNCTIONS
-- ============================================================

-- ---- B1a. ROW_NUMBER() -----
-- Business Value: Assign a unique sequential number to each
--                 appointment per doctor (no ties).
--                 Useful for paginating patient lists per doctor.
SELECT
    a.appointment_id,
    d.full_name                                           AS doctor_name,
    p.full_name                                           AS patient_name,
    a.treatment_cost,
    ROW_NUMBER() OVER (
        PARTITION BY a.doctor_id
        ORDER BY     a.treatment_cost DESC
    )                                                     AS row_num
FROM appointments a
JOIN doctors  d ON a.doctor_id  = d.doctor_id
JOIN patients p ON a.patient_id = p.patient_id
ORDER BY d.full_name, row_num;


-- ---- B1b. RANK() -----
-- Business Value: Rank patients by their total spending.
--                 Tied patients get the same rank (gaps appear).
WITH PatientSpending AS (
    SELECT
        p.patient_id,
        p.full_name          AS patient_name,
        SUM(a.treatment_cost) AS total_spent
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.status = 'Completed'
    GROUP BY p.patient_id, p.full_name
)
SELECT
    patient_name,
    total_spent,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM PatientSpending;


-- ---- B1c. DENSE_RANK() -----
-- Business Value: Rank doctors by revenue within their department.
--                 DENSE_RANK avoids gaps — better for leaderboards.
SELECT
    d.full_name      AS doctor_name,
    dep.dept_name,
    SUM(a.treatment_cost) AS total_revenue,
    DENSE_RANK() OVER (
        PARTITION BY dep.department_id
        ORDER BY     SUM(a.treatment_cost) DESC
    )                AS dept_revenue_rank
FROM   appointments  a
JOIN   doctors      d   ON a.doctor_id      = d.doctor_id
JOIN   departments  dep ON d.department_id  = dep.department_id
WHERE  a.status = 'Completed'
GROUP  BY d.doctor_id, d.full_name, dep.department_id, dep.dept_name
ORDER  BY dep.dept_name, dept_revenue_rank;


-- ---- B1d. PERCENT_RANK() -----
-- Business Value: Show the relative standing of each appointment
--                 cost as a percentile — helps identify the
--                 top 10% most expensive procedures.
SELECT
    a.appointment_id,
    p.full_name      AS patient_name,
    a.diagnosis,
    a.treatment_cost,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY a.treatment_cost) * 100, 2
    )                AS percentile_rank
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
ORDER BY a.treatment_cost DESC;


-- ============================================================
-- B2. AGGREGATE WINDOW FUNCTIONS
-- Business Value: Running totals and benchmarks alongside
--                 individual appointment rows — no GROUP BY
--                 required, so detail is preserved.
-- ============================================================
SELECT
    a.appointment_id,
    a.appointment_date,
    d.full_name          AS doctor_name,
    dep.dept_name,
    a.treatment_cost,

    -- Running total per department (ordered by date)
    SUM(a.treatment_cost) OVER (
        PARTITION BY dep.department_id
        ORDER BY     a.appointment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                    AS running_dept_total,

    -- Average cost per department (whole partition)
    ROUND(AVG(a.treatment_cost) OVER (
        PARTITION BY dep.department_id
    ), 2)                AS dept_avg_cost,

    -- Minimum cost in the whole dataset
    MIN(a.treatment_cost) OVER () AS global_min_cost,

    -- Maximum cost in the whole dataset
    MAX(a.treatment_cost) OVER () AS global_max_cost

FROM   appointments  a
JOIN   doctors      d   ON a.doctor_id      = d.doctor_id
JOIN   departments  dep ON d.department_id  = dep.department_id
WHERE  a.status = 'Completed'
ORDER  BY dep.dept_name, a.appointment_date;


-- ============================================================
-- B3. NAVIGATION FUNCTIONS
-- ============================================================

-- ---- B3a. LAG() — Previous appointment cost -----
-- Business Value: Detect month-over-month cost increases per
--                 patient; supports trend analysis.
SELECT
    p.full_name          AS patient_name,
    a.appointment_date,
    a.diagnosis,
    a.treatment_cost,
    LAG(a.treatment_cost, 1) OVER (
        PARTITION BY a.patient_id
        ORDER BY     a.appointment_date
    )                    AS previous_visit_cost,
    (a.treatment_cost -
        LAG(a.treatment_cost, 1) OVER (
            PARTITION BY a.patient_id
            ORDER BY     a.appointment_date
        )
    )                    AS cost_change
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
ORDER BY p.full_name, a.appointment_date;


-- ---- B3b. LEAD() — Next appointment cost -----
-- Business Value: Forecast upcoming patient spending so finance
--                 teams can prepare resource allocation.
SELECT
    p.full_name          AS patient_name,
    a.appointment_date,
    a.diagnosis,
    a.treatment_cost,
    LEAD(a.treatment_cost, 1) OVER (
        PARTITION BY a.patient_id
        ORDER BY     a.appointment_date
    )                    AS next_visit_cost,
    LEAD(a.appointment_date, 1) OVER (
        PARTITION BY a.patient_id
        ORDER BY     a.appointment_date
    )                    AS next_visit_date
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
ORDER BY p.full_name, a.appointment_date;


-- ============================================================
-- B4. DISTRIBUTION FUNCTIONS
-- ============================================================

-- ---- B4a. NTILE(4) — Quartiles -----
-- Business Value: Segment all appointments into 4 equal cost
--                 buckets (Q1 cheapest → Q4 most expensive)
--                 for pricing policy review.
SELECT
    a.appointment_id,
    p.full_name          AS patient_name,
    a.diagnosis,
    a.treatment_cost,
    NTILE(4) OVER (ORDER BY a.treatment_cost) AS cost_quartile,
    CASE NTILE(4) OVER (ORDER BY a.treatment_cost)
        WHEN 1 THEN 'Low Cost'
        WHEN 2 THEN 'Below Average'
        WHEN 3 THEN 'Above Average'
        WHEN 4 THEN 'High Cost'
    END                  AS cost_category
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
ORDER BY a.treatment_cost;


-- ---- B4b. CUME_DIST() — Cumulative Distribution -----
-- Business Value: Show the proportion of appointments at or
--                 below each cost level — useful for pricing
--                 benchmarks and insurance thresholds.
SELECT
    a.appointment_id,
    p.full_name          AS patient_name,
    a.diagnosis,
    a.treatment_cost,
    ROUND(
        CUME_DIST() OVER (ORDER BY a.treatment_cost) * 100, 2
    )                    AS cumulative_distribution_pct
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
ORDER BY a.treatment_cost;
