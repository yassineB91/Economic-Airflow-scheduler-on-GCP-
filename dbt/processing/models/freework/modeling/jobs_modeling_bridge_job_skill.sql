{{config(
    materialized="incremental",
    unique_key=['job_id','skill_id'])}}

with source_data as (
with job_skill as (
SELECT 
distinct 
job,
{{get_skills('skills')}} as skill
 FROM {{ref('jobs_cleaning_aggregation')}} ,
 unnest(split(key_skills,",")) as skills
 where {{get_skills('skills')}}<>"CDI"
 and {{get_skills('skills')}} <>"Freelance"
{% if is_incremental() %}
  and insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
 )
 select js.skill,js.job , j.job_id, s.skill_id
 from job_skill js
 left outer join {{ref("jobs_modeling_fact_jobs_initial")}} j
 on js.job=j.job
 left outer join {{ref("jobs_modeling_skills")}} s
 on js.skill=s.skill)
 select * from source_data
