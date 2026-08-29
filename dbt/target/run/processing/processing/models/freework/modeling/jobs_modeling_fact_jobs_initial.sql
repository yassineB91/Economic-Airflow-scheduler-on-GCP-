
  
    

    create or replace table `dev-env-368414`.`freework`.`jobs_modeling_fact_jobs_initial`
      
    
    

    OPTIONS()
    as (
      

with source_data as (
with jobs_table as 
(
select
distinct 
job, salary_min,salary_max,tjm_min,
tjm_max,start, job_type, duration, experience, remote, location, key_skills, insert_date, description
from `dev-env-368414`.`freework`.`jobs_cleaning_aggregation` 
where job<>''

)

select distinct

to_hex(md5(cast(coalesce(cast(j.job as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.salary_min as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.salary_max as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.tjm_min as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.tjm_max as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.start as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.duration as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.key_skills as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.description as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(e.experience_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(l.location_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.job_type_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(j.insert_date as string), '_dbt_utils_surrogate_key_null_') as string))) as job_id,
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
left outer join `dev-env-368414`.`freework`.`jobs_modeling_experience` e
on j.experience=e.experience
left outer join `dev-env-368414`.`freework`.`jobs_modeling_location` l
on j.location=l.location
left outer join `dev-env-368414`.`freework`.`jobs_modeling_type` t
on j.job_type=t.job_type
)
select * from source_data
    );
  