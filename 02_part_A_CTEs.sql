-- ============================================================
-- PART A: Common Table Expressions (CTEs)
-- Business Scenario: Hospital Management System
-- ============================================================


-- ============================================================
-- A1. SIMPLE CTE
-- Business Value: Quickly identify high-cost appointments
--                 (above average treatment cost) to flag for
--                 financial auditing or insurance claims.
-- ============================================================
WITH HighCostAppointments AS (
    SELECT
        a.appointment_id,
        p.full_name          AS patient_name,
        d.full_name          AS doctor_name,
        a.diagnosis,
        a.treatment_cost,
        a.appointment_date
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    JOIN doctors  d ON a.doctor_id  = d.doctor_id
    WHERE a.treatment_cost > (
        SELECT AVG(treatment_cost) FROM appointments
    )
)
SELECT *
FROM   HighCostAppointments
ORDER  BY treatment_cost DESC;


-- ============================================================
-- A2. MULTIPLE CTEs
-- Business Value: Compare each department's total revenue
--                 against its allocated budget to spot
--                 over- or under-performing departments.
-- ============================================================
WITH DeptRevenue AS (
    -- Total revenue earned per department via doctor appointments
    SELECT
        dep.department_id,
        dep.dept_name,
        dep.budget,
        SUM(a.treatment_cost) AS total_revenue
    FROM   appointments  a
    JOIN   doctors      d   ON a.doctor_id      = d.doctor_id
    JOIN   departments  dep ON d.department_id  = dep.department_id
    WHERE  a.status = 'Completed'
    GROUP  BY dep.department_id, dep.dept_name, dep.budget
),
BudgetAnalysis AS (
    -- Calculate surplus/deficit and utilisation percentage
    SELECT
        department_id,
        dept_name,
        budget,
        total_revenue,
        (total_revenue - budget)          AS revenue_vs_budget,
        ROUND((total_revenue / budget) * 100, 2) AS revenue_pct_of_budget
    FROM DeptRevenue
)
SELECT *
FROM   BudgetAnalysis
ORDER  BY revenue_pct_of_budget DESC;


-- ============================================================
-- A3. RECURSIVE CTE
-- Business Value: Categorise patients into age groups using
--                 a recursive counter; useful for demographic
--                 reporting and resource planning.
-- ============================================================
WITH RECURSIVE AgeGroups AS (
    -- Anchor: start from age 0
    SELECT 0 AS age_start, 9 AS age_end, '0-9 (Infant/Child)' AS age_group

    UNION ALL

    -- Recursive step: increment by 10 until 80
    SELECT
        age_start + 10,
        age_end   + 10,
        CASE
            WHEN (age_start + 10) BETWEEN 10 AND 19 THEN '10-19 (Teenager)'
            WHEN (age_start + 10) BETWEEN 20 AND 29 THEN '20-29 (Young Adult)'
            WHEN (age_start + 10) BETWEEN 30 AND 39 THEN '30-39 (Adult)'
            WHEN (age_start + 10) BETWEEN 40 AND 49 THEN '40-49 (Middle-Aged)'
            WHEN (age_start + 10) BETWEEN 50 AND 59 THEN '50-59 (Senior)'
            WHEN (age_start + 10) BETWEEN 60 AND 69 THEN '60-69 (Elderly)'
            ELSE                                          '70+ (Very Elderly)'
        END
    FROM AgeGroups
    WHERE age_start < 70
),
PatientAges AS (
    SELECT
        patient_id,
        full_name,
        TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age
    FROM patients
)
SELECT
    ag.age_group,
    COUNT(pa.patient_id) AS patient_count
FROM   AgeGroups  ag
LEFT JOIN PatientAges pa
       ON pa.age BETWEEN ag.age_start AND ag.age_end
GROUP  BY ag.age_group, ag.age_start
ORDER  BY ag.age_start;


-- ============================================================
-- A4. CTE WITH AGGREGATION
-- Business Value: Rank doctors by their total revenue
--                 contribution to help management identify
--                 top-performing physicians.
-- ============================================================
WITH DoctorStats AS (
    SELECT
        d.doctor_id,
        d.full_name          AS doctor_name,
        d.specialization,
        dep.dept_name,
        COUNT(a.appointment_id)  AS total_appointments,
        SUM(a.treatment_cost)    AS total_revenue,
        AVG(a.treatment_cost)    AS avg_cost_per_visit,
        MIN(a.treatment_cost)    AS min_cost,
        MAX(a.treatment_cost)    AS max_cost
    FROM   appointments a
    JOIN   doctors      d   ON a.doctor_id     = d.doctor_id
    JOIN   departments  dep ON d.department_id = dep.department_id
    WHERE  a.status = 'Completed'
    GROUP  BY d.doctor_id, d.full_name, d.specialization, dep.dept_name
),
RankedDoctors AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM DoctorStats
)
SELECT *
FROM   RankedDoctors
ORDER  BY revenue_rank;


-- ============================================================
-- A5. CTE COMBINED WITH JOIN OPERATIONS
-- Business Value: Full patient visit history — joining patient,
--                 doctor, and department info — to produce a
--                 360° patient record for clinical review.
-- ============================================================
WITH PatientVisitHistory AS (
    SELECT
        a.appointment_id,
        a.appointment_date,
        a.diagnosis,
        a.treatment_cost,
        a.status,
        p.patient_id,
        p.full_name   AS patient_name,
        p.gender,
        p.city,
        TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS patient_age
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
),
DoctorDeptInfo AS (
    SELECT
        d.doctor_id,
        d.full_name      AS doctor_name,
        d.specialization,
        dep.dept_name,
        dep.location     AS dept_location
    FROM doctors     d
    JOIN departments dep ON d.department_id = dep.department_id
)
SELECT
    pvh.appointment_id,
    pvh.patient_name,
    pvh.patient_age,
    pvh.gender,
    pvh.city,
    ddi.doctor_name,
    ddi.specialization,
    ddi.dept_name,
    ddi.dept_location,
    pvh.appointment_date,
    pvh.diagnosis,
    pvh.treatment_cost,
    pvh.status
FROM   PatientVisitHistory pvh
JOIN   DoctorDeptInfo      ddi ON 1 = 1   -- joined via appointments bridge
JOIN   appointments        a   ON a.appointment_id = pvh.appointment_id
                               AND a.doctor_id     = ddi.doctor_id
ORDER  BY pvh.patient_name, pvh.appointment_date;
