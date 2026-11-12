with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

customer_orders as (

        select
        customer_id,

        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders
    from orders

    group by customer_id

),

customer_payments as (

    select
        orders.customer_id,
        sum(amount) as total_amount

    from payments

    left join orders on
         payments.order_id = orders.order_id

    group by orders.customer_id

),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order,
        customer_orders.most_recent_order,
        customer_orders.number_of_orders,
        customer_payments.total_amount as customer_lifetime_value,

        -- Average order value: lifetime value / number of orders, rounded to 2 decimals
        -- (currency precision) and stored as a decimal, so no floating point noise.
        -- It is only calculated when both inputs exist and there is at least one order.
        -- Otherwise it is NULL, never a misleading 0 and never a division by zero.
        -- Zero and negative values are kept as they are (not hidden) and are
        -- explained by average_order_value_status below.
        case
            when customer_orders.number_of_orders > 0 and customer_payments.total_amount is not null
                then cast(round(customer_payments.total_amount / customer_orders.number_of_orders, 2) as decimal(18, 2))
        end as average_order_value,

        -- Says why average_order_value can be trusted or not, so odd cases get noticed
        -- by tests instead of silently flowing into reports. Checked in this order:
        --   no_orders               customer has no orders (average does not apply)
        --   no_payments             orders exist, but no payments were found for them
        --   total_paid_is_negative  the customer's payments add up to less than zero
        --                           (e.g. refunds are larger than what was paid)
        --   total_paid_is_zero      orders exist, but the customer's payments add up to exactly 0
        --                           (e.g. bought in store, or a free replacement part)
        --   ok                      normal positive average
        case
            when customer_orders.number_of_orders is null or customer_orders.number_of_orders = 0 then 'no_orders'
            when customer_payments.total_amount is null then 'no_payments'
            when customer_payments.total_amount < 0 then 'total_paid_is_negative'
            when customer_payments.total_amount = 0 then 'total_paid_is_zero'
            else 'ok'
        end as average_order_value_status

    from customers

    left join customer_orders
        on customers.customer_id = customer_orders.customer_id

    left join customer_payments
        on  customers.customer_id = customer_payments.customer_id

)

select * from final
