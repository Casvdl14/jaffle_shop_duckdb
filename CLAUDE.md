# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A small, self-contained dbt project (`jaffle_shop`) running on a local DuckDB file. It is a playground for testing dbt scripts, not a best-practice reference: it deliberately uses seeds instead of sources. The default branch is `duckdb`.

## Commands

Setup needs Python >= 3.13. Run `uv sync` and activate the virtualenv it creates (`.venv`). Run everything from the repo root, where `profiles.yml` lives, so no `--profiles-dir` is needed.

```bash
dbt build                                   # seed + run + test, in DAG order
dbt build --select +customers               # a model plus everything upstream
dbt test --select stg_payments              # tests for one model
dbt docs generate && dbt docs serve
sqlfluff lint models                        # lint (config in .sqlfluff)
sqlfluff fix models                         # auto-fix layout
```

After changing a model, run `dbt build --select +<model>` and lint the files you touched.

## Architecture

Lineage is linear and three layers deep. Materializations are set in `dbt_project.yml`:

```
seeds/raw_*.csv  ->  models/staging/stg_*.sql  (views)  ->  models/customers.sql, models/orders.sql  (tables)
```

- **Seeds** stand in for a source database, so staging selects from them with `ref('raw_...')`.
- **Staging** only renames columns and converts units. Seeds hold amounts in cents, and `stg_payments` converts them to dollars.
- **`customers`** (`models/customers.sql`) reads all three staging models. Payments carry no customer key, so it joins `stg_payments` to `stg_orders` on `order_id` to reach `customer_id`. All joins are left joins, so customers without orders or payments stay in the output with NULL aggregates. The lifetime-value column is `customer_lifetime_value`.
- **`orders`** pivots payments into one `<method>_amount` column per payment method with a Jinja loop over `payment_methods`, a list set at the top of `models/orders.sql` (marts sit directly in `models/`, not in subfolders). **Adding a payment method means changing that list, the `accepted_values` test in `models/staging/schema.yml`, and the column docs/tests in `models/schema.yml`.**

## Conventions

- Staging renames `id` to `<entity>_id` (`customer_id`, `order_id`, `payment_id`) and `user_id` to `customer_id`, so downstream models join on matching names.
- Models are written as CTEs: imports first (`source` in staging), then `renamed`, and `final` in the marts. Follow that shape in new models.
- Tests are generic tests declared in the two `schema.yml` files.
- SQL files contain Jinja. Edit the source `.sql` files, never the rendered copies in `target/`.

## Known issues

- `models/schema.yml` documents a `customers` column `total_order_amount`, but the model outputs `customer_lifetime_value`.
- `etc/jaffle_shop_erd.png` is exported by hand from `etc/dbdiagram_definition.txt` at dbdiagram.io, so update the PNG manually after editing the text.
- `improvements.txt` lists proposed changes that were deliberately **not** applied yet. Don't implement them unless asked.
