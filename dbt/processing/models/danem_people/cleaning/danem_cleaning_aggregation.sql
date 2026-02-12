{{ config(
    materialized = 'incremental',
    partition_by = {'field': 'insert_date', 'data_type': 'timestamp'},
    incremental_strategy = 'insert_overwrite'
) }}

with aggregated_jobs as (
    select * from {{ref('danem_cleaning_cdi')}}
    {% if is_incremental() %}
    where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
    {% endif %}

    union all 

    select * from {{ref('danem_cleaning_freelance')}}
    {% if is_incremental() %}
    where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
    {% endif %}
) 
select * from aggregated_jobs