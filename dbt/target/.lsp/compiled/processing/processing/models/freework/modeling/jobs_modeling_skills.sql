

with source_data as (

with technologies as  (
SELECT 
    distinct 
    
    trim((replace(replace(replace(skills,"[",""),"]",""),"'","")))
 as skill
    FROM `dev-env-368414`.`freework`.`jobs_cleaning_aggregation`,
    unnest(split(key_skills,",")) as skills
    where 
    trim((replace(replace(replace(skills,"[",""),"]",""),"'","")))
<>"CDI"
    and 
    trim((replace(replace(replace(skills,"[",""),"]",""),"'","")))
 <>"Freelance"
    and 
    trim((replace(replace(replace(skills,"[",""),"]",""),"'","")))
 <>"CDD"

 )
 select
    to_hex(md5(cast(coalesce(cast(skill as string), '_dbt_utils_surrogate_key_null_') as string))) as skill_id,
    skill
    from technologies
)
select * from source_data