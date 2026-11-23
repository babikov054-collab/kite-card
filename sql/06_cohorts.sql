-- Q6. Are newer cohorts better or worse than older ones?
-- A cohort = all applications submitted in the same calendar month (Jan-Jun 2025).
-- Tables: applications, credit_decisions, cards, transactions, customers


-- 6.1  Funnel by cohort month.
--      LEFT JOIN keeps applications that dropped out (no decision / no card),
--      otherwise every rate would be computed only on the survivors.
--      First purchase is checked with EXISTS, so transactions do not multiply rows.
SELECT
    date_trunc('month', a.applied_at)::DATE                              AS cohort_month,
    count(*)                                                             AS applications,
    round(100.0 * count(*) FILTER (WHERE a.kyc_status = 'completed')
          / count(*), 1)                                                 AS kyc_rate_pct,
    round(100.0 * count(*) FILTER (WHERE cd.decision = 'approved')
          / count(cd.decision_id), 1)                                    AS approval_rate_pct,
    round(100.0 * count(c.activated_at) / count(c.card_id), 1)           AS card_activation_pct,
    round(100.0 * count(c.activated_at) / count(*), 1)                   AS app_to_active_card_pct,
    round(100.0 * count(*) FILTER (WHERE EXISTS (
              SELECT 1 FROM transactions AS t WHERE t.card_id = c.card_id))
          / count(*), 1)                                                 AS app_to_first_purchase_pct
FROM applications          AS a
LEFT JOIN credit_decisions AS cd ON cd.application_id = a.application_id
LEFT JOIN cards            AS c  ON c.application_id  = a.application_id
GROUP BY cohort_month
ORDER BY cohort_month;


-- 6.2  What moved the approval rate? The scoring model changed on 2025-03-15 (v1 -> v2).
--      Split each month by score version: March contains both.
SELECT
    date_trunc('month', a.applied_at)::DATE                              AS cohort_month,
    cd.score_version,
    count(*)                                                             AS decisions,
    round(100.0 * count(*) FILTER (WHERE cd.decision = 'approved')
          / count(*), 1)                                                 AS approval_rate_pct
FROM credit_decisions AS cd
JOIN applications     AS a ON a.application_id = cd.application_id
GROUP BY cohort_month, cd.score_version
ORDER BY cohort_month, cd.score_version;


-- 6.3  v1 vs v2 overall: fewer approvals, but do approved customers activate more?
SELECT
    cd.score_version,
    count(*)                                                             AS decisions,
    round(100.0 * count(*) FILTER (WHERE cd.decision = 'approved')
          / count(*), 1)                                                 AS approval_rate_pct,
    count(c.card_id)                                                     AS cards_issued,
    round(100.0 * count(c.activated_at) / count(c.card_id), 1)           AS card_activation_pct
FROM credit_decisions AS cd
LEFT JOIN cards       AS c ON c.application_id = cd.application_id
GROUP BY cd.score_version
ORDER BY cd.score_version;


-- 6.4  Sanity check: did the applicants themselves change?
--      If the mix of who applies is stable, the shift comes from the bank's side (the model).
SELECT
    date_trunc('month', a.applied_at)::DATE                              AS cohort_month,
    round(100.0 * count(*) FILTER (WHERE cu.employment_status = 'employed')
          / count(*), 1)                                                 AS employed_pct,
    round(100.0 * count(*) FILTER (WHERE cu.employment_status IN ('student', 'unemployed'))
          / count(*), 1)                                                 AS student_or_unemployed_pct,
    round(median(cu.monthly_income_eur), 0)                              AS median_income_eur,
    round(avg(2025 - cu.birth_year), 1)                                  AS avg_age,
    round(avg(a.acquisition_cost_eur), 2)                                AS avg_acquisition_cost_eur
FROM applications AS a
JOIN customers    AS cu ON cu.customer_id = a.customer_id
GROUP BY cohort_month
ORDER BY cohort_month;
