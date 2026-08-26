

with source_data as (
with job_skill as (
SELECT 
distinct 
job,

    trim((replace(replace(replace(skills,"[",""),"]",""),"'","")))
 as skill
 FROM `dev-env-368414`.`freework`.`jobs_cleaning_aggregation` ,
 unnest(split(key_skills,",")) as skills
 where 
    trim((replace(replace(replace(skills,"[",""),"]",""),"'","")))
<>"CDI"
 and 
    trim((replace(replace(replace(skills,"[",""),"]",""),"'","")))
 <>"Freelance"

 )
 select js.skill,js.job , j.job_id, s.skill_id
 from job_skill js
 left outer join `dev-env-368414`.`freework`.`jobs_modeling_fact_jobs_initial` j
 on js.job=j.job
 left outer join `dev-env-368414`.`freework`.`jobs_modeling_skills` s
 on js.skill=s.skill)
 select * from source_data