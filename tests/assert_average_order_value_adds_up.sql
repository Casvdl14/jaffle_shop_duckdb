-- Singular dbt test: passes when this query returns zero rows (severity: error).
-- Consistency check on the calculation itself: for customers with a value,
-- average_order_value * number_of_orders must land back on customer_lifetime_value.
-- The allowed difference is half a cent per order, because the average is rounded to 2 decimals.
-- This catches a wrong divisor (e.g. orders counted twice) or a wrong numerator.

select
    customer_id,
    number_of_orders,
    customer_lifetime_value,
    average_order_value
from {{ ref('customers') }}
where
    average_order_value is not null
    and abs(average_order_value * number_of_orders - customer_lifetime_value) > 0.005 * number_of_orders
