{{config(
    materialized="incremental",
    unique_key='experience_id')}}
    
with source_data as (
with exp as (select
distinct 
experience
from {{ref('jobs_cleaning_aggregation')}}
{% if is_incremental() %}
  where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
)
select 
{{dbt_utils.generate_surrogate_key(['experience'])}} as experience_id,
experience
from exp
)
select * from source_data
