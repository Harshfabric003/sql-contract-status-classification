# Foundry Contract Status Classification (SQL)

A SQL query that classifies each customer's current contract as **New**, **Retained**, or **Converted** by comparing it against their previous-period contract — a common pattern in customer lifecycle, renewals, and revenue-retention analysis.

Built as a clean, self-contained demo on a fictional schema. You can copy the whole file into any MySQL instance and run it end to end.

## The problem

Given a table of contracts spanning two periods, determine for every foundry (customer) with a *current* contract:

| Status | Definition |
|-----------|--------------------------------------------------------|
| **New** | No contract existed in the previous period |
| **Retained** | Had a previous contract and kept the **same** tier |
| **Converted** | Had a previous contract but **changed** tier |

## The approach

The query does a **self-join** on a single `foundry_contracts` table — joining each current-period row (`cur`) to the same foundry's previous-period row (`prev`) — then applies `CASE` logic:

```sql
CASE
    WHEN prev.contract_id IS NULL          THEN 'NEW'
    WHEN prev.contract_tier = cur.contract_tier THEN 'RETAINED'
    ELSE 'CONVERTED'
END AS contract_status
```

A `LEFT JOIN` is key: foundries with no prior contract still appear (with `NULL` on the previous side), which is what lets us flag them as **New**.

## How to run

1. Open `foundry_contract_status.sql` in MySQL Workbench, DBeaver, or any MySQL client.
2. Run the whole script — it creates the table, inserts sample data, and runs the query.

## Expected output

| foundry_id | foundry_name | previous_tier | current_tier | contract_status |
|-----------|---------------------|---------------|--------------|-----------------|
| 1 | Northwind Type Co. | Basic | Basic | RETAINED |
| 2 | Emberline Foundry | Standard | Premium | CONVERTED |
| 3 | Glyph & Co. | NULL | Standard | NEW |
| 4 | Serif Society | Premium | Premium | RETAINED |
| 5 | Baseline Design | Basic | Standard | CONVERTED |

## Notes

- Dialect: **MySQL 8.0+**. The query is standard enough to run on most engines with minor tweaks.
- Schema and data are fictional and created purely to demonstrate the technique.
- The same pattern extends naturally to churn detection (previous contract exists, current does not), tier-upgrade vs. downgrade splits, and multi-period trend analysis using window functions.
