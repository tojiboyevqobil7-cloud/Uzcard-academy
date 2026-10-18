SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE 'scoring\_%'
ORDER BY tablename;


SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name LIKE 'scoring\_%'
ORDER BY table_name, ordinal_position;

SELECT *
FROM public.scoring_payments
ORDER BY contract_id, installment_no
LIMIT 30;

SELECT
    contract_id,
    installment_no,
    due_date,
    paid_date,
    due_amount_uzs,
    paid_amount_uzs
FROM public.scoring_payments
ORDER BY contract_id, installment_no
LIMIT 50;

SELECT
    paid_date,
    due_date,
    paid_date - due_date AS days_late
FROM public.scoring_payments
LIMIT 30;

SELECT
    MAX(paid_date - due_date) AS max_days_late
FROM public.scoring_payments;

SELECT
    paid_date - due_date AS days_late,
    COUNT(*) AS payments_count
FROM public.scoring_payments
WHERE paid_date IS NOT NULL
GROUP BY paid_date - due_date
ORDER BY days_late;


SELECT
    MIN(issue_date) AS min_issue_date,
    MAX(issue_date) AS max_issue_date,
    COUNT(*) AS contracts_count
FROM public.scoring_contracts;


SELECT
    MIN(decision_date) AS min_decision_date,
    MAX(decision_date) AS max_decision_date,
    COUNT(*) AS applications_count
FROM public.scoring_applications;

SELECT
    COUNT(*) AS total_contracts,
    COUNT(*) FILTER (
        WHERE issue_date <= DATE '2024-11-30'
    ) AS full_6m_window,
    COUNT(*) FILTER (
        WHERE issue_date > DATE '2024-11-30'
    ) AS incomplete_6m_window
FROM public.scoring_contracts;



SELECT
    c.contract_id,
    c.application_id,
    c.client_id,
    c.issue_date,
    MAX(p.paid_date - p.due_date) AS max_days_late
FROM public.scoring_contracts c
JOIN public.scoring_payments p
    ON c.contract_id = p.contract_id
WHERE c.issue_date <= DATE '2024-11-30'
  AND p.due_date >= c.issue_date
  AND p.due_date < c.issue_date + INTERVAL '6 months'
GROUP BY
    c.contract_id,
    c.application_id,
    c.client_id,
    c.issue_date
ORDER BY max_days_late DESC;


SELECT
    COUNT(*) AS total,
    COUNT(*) FILTER (
        WHERE max_days_late >= 30
    ) AS bad
FROM (
    SELECT
        c.contract_id,
        MAX(p.paid_date - p.due_date) AS max_days_late
    FROM public.scoring_contracts c
    JOIN public.scoring_payments p
        ON c.contract_id = p.contract_id
    WHERE c.issue_date <= DATE '2024-11-30'
      AND p.due_date >= c.issue_date
      AND p.due_date < c.issue_date + INTERVAL '6 months'
    GROUP BY c.contract_id
) x;



SELECT
    COUNT(*) AS contracts_total,
    COUNT(*) FILTER (
        WHERE EXISTS (
            SELECT 1
            FROM public.scoring_payments p
            WHERE p.contract_id = c.contract_id
        )
    ) AS contracts_with_payments
FROM public.scoring_contracts c
WHERE c.issue_date <= DATE '2024-11-30';


SELECT
    c.contract_id,
    MAX(p.paid_date - p.due_date) AS max_days_late
FROM public.scoring_contracts c
JOIN public.scoring_payments p
    ON c.contract_id = p.contract_id
WHERE c.issue_date <= DATE '2024-11-30'
  AND p.due_date >= c.issue_date
  AND p.due_date < c.issue_date + INTERVAL '6 months'
GROUP BY c.contract_id
ORDER BY max_days_late DESC;




SELECT
    COUNT(DISTINCT c.contract_id) AS contracts_with_6m_payments
FROM public.scoring_contracts c
JOIN public.scoring_payments p
    ON c.contract_id = p.contract_id
WHERE c.issue_date <= DATE '2024-11-30'
  AND p.due_date >= c.issue_date
  AND p.due_date < c.issue_date + INTERVAL '6 months';


SELECT
    COUNT(*) AS total_contracts,
    COUNT(*) FILTER (WHERE max_days_late >= 30) AS bad_contracts,
    COUNT(*) FILTER (WHERE max_days_late < 30) AS good_contracts
FROM (
    SELECT
        c.contract_id,
        MAX(p.paid_date - p.due_date) AS max_days_late
    FROM public.scoring_contracts c
    JOIN public.scoring_payments p
        ON c.contract_id = p.contract_id
    WHERE c.issue_date <= DATE '2024-11-30'
      AND p.due_date >= c.issue_date
      AND p.due_date < c.issue_date + INTERVAL '6 months'
    GROUP BY c.contract_id
) x;

%%sql

SELECT COUNT(*) AS rejected_count
FROM public.scoring_applications
WHERE LOWER(final_decision) = 'rejected';

%%sql

SELECT COUNT(*) AS applications_without_customer
FROM public.scoring_applications a
LEFT JOIN public.scoring_customers c
    ON a.client_id = c.customer_id
WHERE c.customer_id IS NULL;


%%sql

SELECT
    a.application_id,
    a.client_id,
    a.decision_date,
    a.final_decision
FROM public.scoring_applications a
LEFT JOIN public.scoring_customers c
    ON a.client_id = c.customer_id
WHERE c.customer_id IS NULL
LIMIT 100;

