## The SQL Script

```sql
WITH target_info AS (
    -- Filter for only Oracle Database instances
    SELECT 
        target_name, 
        display_name, 
        target_type 
    FROM mgmt$target 
    WHERE target_type = 'oracle_database'
),
availability AS (
    -- Get current availability and the time it last changed
    SELECT 
        target_name, 
        availability_status, 
        last_status_change 
    FROM mgmt$availability_current
),
blackouts AS (
    -- Get active blackouts and their start times
    SELECT 
        target_name, 
        start_time, 
        end_time, 
        'Active' as blackout_status
    FROM mgmt$blackout
    WHERE (end_time > SYSDATE OR end_time IS NULL) 
      AND start_time <= SYSDATE
)
SELECT 
    t.target_name AS "Target Name",
    t.display_name AS "Display Name",
    CASE 
        WHEN b.blackout_status = 'Active' THEN 'In Blackout'
        WHEN a.availability_status = 'Down' THEN 'Down/Stopped'
        ELSE 'Up' 
    END AS "Current State",
    CASE 
        WHEN b.blackout_status = 'Active' THEN b.start_time 
        ELSE a.last_status_change 
    END AS "Since Date",
    ROUND(SYSDATE - CASE WHEN b.blackout_status = 'Active' THEN b.start_time ELSE a.last_status_change END, 2) AS "Days Elapsed"
FROM 
    target_info t
JOIN 
    availability a ON t.target_name = a.target_name
LEFT JOIN 
    blackouts b ON t.target_name = b.target_name
WHERE 
    -- CONDITION 1: Instance is Down and has been down for more than 7 days
    (a.availability_status = 'Down' AND a.last_status_change < SYSDATE - 7)
    OR 
    -- CONDITION 2: Instance is in Blackout and has been in blackout for more than 7 days
    (b.blackout_status = 'Active' AND b.start_time < SYSDATE - 7)
ORDER BY 
    "Days Elapsed" DESC;
```

### Explanation of the Logic:

1.  **`target_info` (CTE):** I used `mgmt$target` to ensure we are only looking at `oracle_database` targets. This prevents the report from being 
cluttered with hosts, listeners, or switches.
2.  **`availability` (CTE):** I used `mgmt$availability_current`. This is the most accurate table for the current "Up/Down" state and provides the 
`last_status_change` timestamp, which tells us *when* it stopped.
3.  **`blackouts` (CTE):** I queried `mgmt$blackout`. A target is considered in blackout if the `start_time` has passed and the `end_time` is either in 
the future or NULL (infinite blackout).
4.  **Priority Logic:** In the `CASE` statement, **Blackout takes precedence**. If a database is both Down AND in Blackout, it is usually categorized as 
"In Blackout" because monitoring is intentionally suppressed.
5.  **The "For a While" Filter:**
    *   I used `SYSDATE - 7` as the threshold (7 days). 
    *   **You can change the number `7`** to `30` (one month) or `1` (one day) depending on your specific definition of "a while."

### How to run this:
1.  Log into your **OEM Console**.
2.  Go to **Enterprise $\rightarrow$ Monitoring $\rightarrow$ Repository SQL Worksheet**.
3.  Paste the script and execute.

### Performance Note:
If you have thousands of targets, `mgmt$` views can sometimes be slow because they are complex views. If you find the query hanging, you can replace the 
`mgmt$` views with the underlying base tables (e.g., `MGMT_TARGET`, `MGMT_AVAILABILITY_CURRENT`), though the `mgmt$` views are recommended for 
compatibility across different OEM versions.

