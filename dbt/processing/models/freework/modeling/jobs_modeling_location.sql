{{config(
    materialized="incremental",
    unique_key='location_id')}}

with source_data as (
with exp as (select
distinct 
location
from {{ref('jobs_cleaning_aggregation')}}
{% if is_incremental() %}
  where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
)
select 
{{dbt_utils.generate_surrogate_key(['location'])}} as location_id,
location
from exp)
select * from source_data
