-- ============================================================
-- PART C: Analysis Section
-- Business Scenario: Hospital Management System
-- ============================================================


-- ============================================================
-- DESCRIPTIVE ANALYSIS — "What happened?"
-- ============================================================

-- 1. Monthly revenue trend across all departments
SELECT
    DATE_FORMAT(appointment_date, '%Y-%m') AS month,
    COUNT(*)                               AS total_appointments,
    SUM(treatment_cost)                    AS total_revenue,
    AVG(treatment_cost)                    AS avg_treatment_cost
FROM  appointments
WHERE status = 'Completed'
GROUP BY month
ORDER BY month;


-- 2. Gender distribution of patients and their spending
SELECT
    p.gender,
    COUNT(DISTINCT p.patient_id)  AS patient_count,
    COUNT(a.appointment_id)       AS total_visits,
    SUM(a.treatment_cost)         AS total_spent,
    ROUND(AVG(a.treatment_cost),2) AS avg_cost_per_visit
FROM  patients     p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
GROUP BY p.gender;


-- 3. Top 5 most common diagnoses by frequency and revenue
SELECT
    diagnosis,
    COUNT(*)             AS frequency,
    SUM(treatment_cost)  AS total_revenue,
    ROUND(AVG(treatment_cost), 2) AS avg_cost
FROM  appointments
WHERE status = 'Completed'
GROUP BY diagnosis
ORDER BY frequency DESC
LIMIT 5;


-- 4. Department performance summary
SELECT
    dep.dept_name,
    COUNT(DISTINCT d.doctor_id)   AS doctor_count,
    COUNT(a.appointment_id)       AS appointments_handled,
    SUM(a.treatment_cost)         AS total_revenue,
    dep.budget,
    ROUND((SUM(a.treatment_cost) / dep.budget) * 100, 2) AS budget_utilisation_pct
FROM departments dep
LEFT JOIN doctors     d ON dep.department_id = d.department_id
LEFT JOIN appointments a ON d.doctor_id      = a.doctor_id AND a.status = 'Completed'
GROUP BY dep.department_id, dep.dept_name, dep.budget
ORDER BY total_revenue DESC;


-- ============================================================
-- DIAGNOSTIC ANALYSIS — "Why did it happen?"
-- ============================================================

-- 5. Which doctors drive the most revenue? (identify high performers)
WITH DoctorRevenue AS (
    SELECT
        d.doctor_id,
        d.full_name          AS doctor_name,
        d.specialization,
        dep.dept_name,
        d.salary,
        COUNT(a.appointment_id)   AS appointments,
        SUM(a.treatment_cost)     AS total_revenue,
        ROUND(SUM(a.treatment_cost) / d.salary, 2) AS revenue_to_salary_ratio
    FROM appointments a
    JOIN doctors     d   ON a.doctor_id     = d.doctor_id
    JOIN departments dep ON d.department_id = dep.department_id
    WHERE a.status = 'Completed'
    GROUP BY d.doctor_id, d.full_name, d.specialization, dep.dept_name, d.salary
)
SELECT *,
       RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank
FROM   DoctorRevenue
ORDER  BY total_revenue DESC;


-- 6. Identify patients with repeated visits for the same diagnosis
--    (possible chronic condition management issue)
SELECT
    p.full_name        AS patient_name,
    a.diagnosis,
    COUNT(*)           AS repeat_visits,
    SUM(a.treatment_cost) AS cumulative_cost
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
WHERE a.status = 'Completed'
GROUP BY p.patient_id, p.full_name, a.diagnosis
HAVING repeat_visits > 1
ORDER BY repeat_visits DESC, cumulative_cost DESC;


-- 7. Cancelled / pending appointments — potential revenue leakage
SELECT
    a.status,
    COUNT(*)            AS count,
    SUM(a.treatment_cost) AS potential_revenue_lost
FROM appointments a
WHERE a.status IN ('Cancelled', 'Pending')
GROUP BY a.status;


-- ============================================================
-- PRESCRIPTIVE ANALYSIS — "What actions should be taken?"
-- ============================================================

-- 8. Doctors with LOW appointment volume — may need scheduling intervention
WITH DoctorLoad AS (
    SELECT
        d.doctor_id,
        d.full_name         AS doctor_name,
        d.specialization,
        dep.dept_name,
        COUNT(a.appointment_id) AS total_appointments,
        AVG(COUNT(a.appointment_id)) OVER () AS avg_appointments_all_doctors
    FROM doctors     d
    JOIN departments dep ON d.department_id = dep.department_id
    LEFT JOIN appointments a ON d.doctor_id = a.doctor_id AND a.status = 'Completed'
    GROUP BY d.doctor_id, d.full_name, d.specialization, dep.dept_name
)
SELECT
    doctor_name,
    specialization,
    dept_name,
    total_appointments,
    ROUND(avg_appointments_all_doctors, 1) AS avg_across_hospital,
    CASE
        WHEN total_appointments < avg_appointments_all_doctors * 0.5
        THEN 'UNDER-UTILISED — Review scheduling'
        WHEN total_appointments > avg_appointments_all_doctors * 1.5
        THEN 'OVER-WORKED — Consider hiring support'
        ELSE 'Normal Load'
    END AS recommendation
FROM DoctorLoad
ORDER BY total_appointments;


-- 9. Patients with high cumulative spend — flag for insurance / welfare plan
WITH PatientTotalSpend AS (
    SELECT
        p.patient_id,
        p.full_name AS patient_name,
        p.city,
        SUM(a.treatment_cost) AS total_spend,
        COUNT(a.appointment_id) AS visits,
        NTILE(4) OVER (ORDER BY SUM(a.treatment_cost)) AS spend_quartile
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.status = 'Completed'
    GROUP BY p.patient_id, p.full_name, p.city
)
SELECT
    patient_name,
    city,
    total_spend,
    visits,
    spend_quartile,
    CASE spend_quartile
        WHEN 4 THEN 'HIGH RISK — Enrol in insurance programme'
        WHEN 3 THEN 'MODERATE — Monitor closely'
        ELSE        'STABLE — Standard follow-up'
    END AS action_required
FROM PatientTotalSpend
ORDER BY total_spend DESC;


-- 10. Department budget vs revenue — funding reallocation suggestion
WITH BudgetGap AS (
    SELECT
        dep.dept_name,
        dep.budget,
        COALESCE(SUM(a.treatment_cost), 0) AS actual_revenue,
        (COALESCE(SUM(a.treatment_cost), 0) - dep.budget) AS surplus_deficit
    FROM departments dep
    LEFT JOIN doctors      d ON dep.department_id = d.department_id
    LEFT JOIN appointments a ON d.doctor_id       = a.doctor_id AND a.status = 'Completed'
    GROUP BY dep.department_id, dep.dept_name, dep.budget
)
SELECT
    dept_name,
    budget,
    actual_revenue,
    surplus_deficit,
    CASE
        WHEN surplus_deficit > 0  THEN 'SURPLUS — Consider re-investing in equipment'
        WHEN surplus_deficit < 0  THEN 'DEFICIT — Review costs or increase patient capacity'
        ELSE                           'BREAK-EVEN'
    END AS financial_recommendation
FROM BudgetGap
ORDER BY surplus_deficit DESC;
