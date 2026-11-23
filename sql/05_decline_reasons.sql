-- Q5. Why are applications declined?
-- Table: credit_decisions (+ applications, customers for the city breakdown, cards for activation)
-- One row in credit_decisions = one credit decision (17,009 rows).


-- 5.1  Overall: how many applications are approved vs declined
SELECT
    decision,
    count(*)                                         AS decisions,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct_of_decisions
FROM credit_decisions
GROUP BY decision
ORDER BY decisions DESC;


-- 5.2  Decline reasons ranked by frequency.
--      reason_type separates what the risk model decided from what is a process issue:
--        risk_model  = the applicant really looks risky (income, debt load, history, thin file)
--        process     = the bank could not verify income documents -> fixable operationally
--        policy      = a hard business rule, not a model judgement
SELECT
    decline_reason,
    CASE
        WHEN decline_reason = 'income_unverified' THEN 'process'
        WHEN decline_reason = 'policy_rule'       THEN 'policy'
        ELSE 'risk_model'
    END                                                AS reason_type,
    count(*)                                           AS declines,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct_of_declines
FROM credit_decisions
WHERE decision = 'declined'
GROUP BY decline_reason
ORDER BY declines DESC;


-- 5.3  Same thing rolled up to the three reason types
SELECT
    CASE
        WHEN decline_reason = 'income_unverified' THEN 'process'
        WHEN decline_reason = 'policy_rule'       THEN 'policy'
        ELSE 'risk_model'
    END                                                AS reason_type,
    count(*)                                           AS declines,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct_of_declines
FROM credit_decisions
WHERE decision = 'declined'
GROUP BY reason_type
ORDER BY declines DESC;


-- 5.4  Is the process problem everywhere or in one place?
--      Share of declines that are 'income_unverified', by applicant city.
SELECT
    cu.city,
    count(*)                                                        AS declines,
    count(*) FILTER (WHERE cd.decline_reason = 'income_unverified') AS income_unverified,
    round(100.0 * count(*) FILTER (WHERE cd.decline_reason = 'income_unverified')
          / count(*), 1)                                            AS pct_income_unverified
FROM credit_decisions AS cd
JOIN applications     AS a  ON a.application_id = cd.application_id
JOIN customers        AS cu ON cu.customer_id   = a.customer_id
WHERE cd.decision = 'declined'
GROUP BY cu.city
ORDER BY pct_income_unverified DESC;


-- 5.5  Manual review vs automated decisions:
--      volume, approval rate, and median time from KYC to decision (in hours).
--      Time is counted in minutes and divided by 60 (date_diff in hours/days rounds down).
SELECT
    cd.decision_type,
    count(*)                                                        AS decisions,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1)              AS pct_of_decisions,
    round(100.0 * count(*) FILTER (WHERE cd.decision = 'approved')
          / count(*), 1)                                            AS approval_rate_pct,
    round(median(date_diff('minute', a.kyc_completed_at, cd.decided_at)) / 60.0, 1)
                                                                    AS median_hours_to_decision
FROM credit_decisions AS cd
JOIN applications     AS a ON a.application_id = cd.application_id
GROUP BY cd.decision_type
ORDER BY decisions DESC;


-- 5.6  Does the slow manual path cost anything later?
--      Card activation rate for approved applicants, by how they were decided.
--      LEFT JOIN is not needed here: every approved decision has exactly one card.
SELECT
    cd.decision_type,
    count(*)                                         AS cards_issued,
    count(c.activated_at)                            AS cards_activated,
    round(100.0 * count(c.activated_at) / count(*), 1) AS activation_rate_pct
FROM cards            AS c
JOIN credit_decisions AS cd ON cd.application_id = c.application_id
GROUP BY cd.decision_type
ORDER BY cards_issued DESC;
