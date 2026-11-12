{{ config(severity='warn') }}

-- Singular dbt test with severity "warn": the build keeps going, but dbt prints a
-- warning with the number of customers returned here, so the cases get noticed.
-- Each row is a customer who has orders but a suspicious average order value:
--   no_payments         orders exist, but no payments were found for them
--   total_paid_is_zero  payments add up to exactly 0 (e.g. in-store purchase, free replacement part)
-- It is a warning and not an error because these can be real business cases.
-- Negative values are not listed here: assert_average_order_value_not_negative fails on those.

select
    customer_id,
    number_of_orders,
    customer_lifetime_value,
    average_order_value_status
from {{ ref('customers') }}
where average_order_value_status in ('no_payments', 'total_paid_is_zero')
