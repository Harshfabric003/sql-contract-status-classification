-- =============================================================================
-- Foundry Contract Status Classification
-- -----------------------------------------------------------------------------
-- Classifies each foundry's CURRENT contract as one of:
--   NEW       -> foundry has no prior (previous-period) contract
--   RETAINED  -> foundry had a prior contract and kept the SAME type/tier
--   CONVERTED -> foundry had a prior contract but CHANGED type/tier
--
-- Technique: self-join a single contracts table (current period vs. previous
-- period) and apply CASE logic to derive the status.
--
-- Dialect: MySQL 8.0+
-- Note: Uses a fictional schema and sample data. Not tied to any real system.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Schema
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS foundry_contracts;

CREATE TABLE foundry_contracts (
    contract_id     INT AUTO_INCREMENT PRIMARY KEY,
    foundry_id      INT            NOT NULL,
    foundry_name    VARCHAR(100)   NOT NULL,
    contract_period VARCHAR(10)    NOT NULL,   -- e.g. '2024' (previous), '2025' (current)
    contract_tier   VARCHAR(30)    NOT NULL,   -- e.g. 'Basic', 'Standard', 'Premium'
    is_active       TINYINT(1)     NOT NULL DEFAULT 1
);


-- -----------------------------------------------------------------------------
-- 2. Sample data  (fictional foundries)
--    Previous period = '2024', current period = '2025'
-- -----------------------------------------------------------------------------
INSERT INTO foundry_contracts (foundry_id, foundry_name, contract_period, contract_tier, is_active) VALUES
    -- Foundry 1: had Basic in 2024, still Basic in 2025  -> RETAINED
    (1, 'Northwind Type Co.',   '2024', 'Basic',    1),
    (1, 'Northwind Type Co.',   '2025', 'Basic',    1),

    -- Foundry 2: had Standard in 2024, upgraded to Premium in 2025 -> CONVERTED
    (2, 'Emberline Foundry',    '2024', 'Standard', 1),
    (2, 'Emberline Foundry',    '2025', 'Premium',  1),

    -- Foundry 3: no 2024 contract, first contract in 2025 -> NEW
    (3, 'Glyph & Co.',          '2025', 'Standard', 1),

    -- Foundry 4: had Premium in 2024, still Premium in 2025 -> RETAINED
    (4, 'Serif Society',        '2024', 'Premium',  1),
    (4, 'Serif Society',        '2025', 'Premium',  1),

    -- Foundry 5: had Basic in 2024, moved to Standard in 2025 -> CONVERTED
    (5, 'Baseline Design',      '2024', 'Basic',    1),
    (5, 'Baseline Design',      '2025', 'Standard', 1),

    -- Foundry 6: only a 2024 contract, nothing current -> excluded from result
    (6, 'Old Press Letters',    '2024', 'Standard', 1);


-- -----------------------------------------------------------------------------
-- 3. Classification query
--    LEFT JOIN current-period rows to same foundry's previous-period rows.
-- -----------------------------------------------------------------------------
SELECT
    cur.foundry_id,
    cur.foundry_name,
    prev.contract_tier              AS previous_tier,
    cur.contract_tier               AS current_tier,
    CASE
        WHEN prev.contract_id IS NULL
            THEN 'NEW'
        WHEN prev.contract_tier = cur.contract_tier
            THEN 'RETAINED'
        ELSE 'CONVERTED'
    END                             AS contract_status
FROM foundry_contracts AS cur
LEFT JOIN foundry_contracts AS prev
       ON prev.foundry_id      = cur.foundry_id
      AND prev.contract_period = '2024'          -- previous period
WHERE cur.contract_period = '2025'               -- current period
  AND cur.is_active = 1
ORDER BY cur.foundry_id;


-- -----------------------------------------------------------------------------
-- Expected output:
--   foundry_id | foundry_name        | previous_tier | current_tier | contract_status
--   -----------+---------------------+---------------+--------------+----------------
--   1          | Northwind Type Co.  | Basic         | Basic        | RETAINED
--   2          | Emberline Foundry   | Standard      | Premium      | CONVERTED
--   3          | Glyph & Co.         | NULL          | Standard     | NEW
--   4          | Serif Society       | Premium       | Premium      | RETAINED
--   5          | Baseline Design     | Basic         | Standard     | CONVERTED
-- -----------------------------------------------------------------------------
