{{config(
    materialized="incremental",
    unique_key='job_id')}}

with source_data as (
with jobs_table as 
(
select
distinct 
job, salary_min,salary_max,tjm_min,
tjm_max,start, job_type, duration, experience, remote, location, key_skills, insert_date, description
from {{ref('jobs_cleaning_aggregation')}} 
where job<>''
{% if is_incremental() %}
  and insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
)

select distinct

{{dbt_utils.generate_surrogate_key(
    ['j.job', 
'j.salary_min',
'j.salary_max',
'j.tjm_min',
'j.tjm_max',
'j.start',
'j.duration',
'j.key_skills',
'j.description',
'e.experience_id',
'l.location_id',
't.job_type_id',
'j.insert_date'])}} as job_id,
j.job, 
j.salary_min,
j.salary_max,
j.tjm_min,
j.tjm_max,
j.start,
j.duration,
j.key_skills,
e.experience_id,
l.location_id,
t.job_type_id,
j.insert_date
from
jobs_table j
left outer join {{ref('jobs_modeling_experience')}} e
on j.experience=e.experience
left outer join {{ref('jobs_modeling_location')}} l
on j.location=l.location
left outer join {{ref('jobs_modeling_type')}} t
on j.job_type=t.job_type
)
select * from source_data