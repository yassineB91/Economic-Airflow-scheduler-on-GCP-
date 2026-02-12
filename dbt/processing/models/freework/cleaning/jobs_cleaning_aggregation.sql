{{ config(
    materialized = 'incremental',
    partition_by = {'field': 'insert_date', 'data_type': 'timestamp'},
    incremental_strategy = 'insert_overwrite'
) }}

with source_data as (
select
distinct
job,
job_type,
salary_min,
salary_max,
tjm_min,
tjm_max,
start,
duration,
experience,
remote,
location,
key_skills,
insert_date,
 description
from {{ref('jobs_cleaning_freelance_cdi')}}
{% if is_incremental() %}
  where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}

union all

select
distinct
job,
job_type,
salary_min,
salary_max,
cast(null as numeric) as tjm_min,
cast(null as numeric)  as tjm_max,
start,
duration,
experience,
remote,
location,
key_skills,
insert_date,
 description
from {{ref('jobs_cleaning_cdi')}}
{% if is_incremental() %}
  where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}

union all

select
distinct
job,
job_type,
cast(null as numeric) as salary_min,
cast(null as numeric) as salary_max,
tjm_min,
tjm_max,
start,
duration,
experience,
remote,
location,
key_skills,
insert_date,
 description
from {{ref('jobs_cleaning_freelance')}}
{% if is_incremental() %}
  where insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
)
select  
*
from source_data 