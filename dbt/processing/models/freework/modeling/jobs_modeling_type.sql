{{config(
    materialized="incremental",
    unique_key='job_type_id')}}

with source_data as (
with type as (select
distinct 
job_type
from {{ref('jobs_cleaning_aggregation')}}
{% if is_incremental() %}
  where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
)
select
{{dbt_utils.generate_surrogate_key(['job_type'])}} as job_type_id, 
job_type
from type
)

select * from source_data