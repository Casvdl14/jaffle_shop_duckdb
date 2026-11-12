-- Singular dbt test: passes when this query returns zero rows (severity: error).
-- Each returned row is a customer whose average order value is negative.
--
-- NULL values (no orders, or no payments) are not flagged: a NULL comparison is
-- never true, and "no data" is not the same as a negative average. Those cases
-- are reported by assert_average_order_value_edge_cases instead.

select
    customer_id,
    average_order_value,
    average_order_value_status
from {{ ref('customers') }}
where average_order_value < 0
