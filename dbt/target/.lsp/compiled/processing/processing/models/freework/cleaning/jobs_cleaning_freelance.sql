

with source_data as (
select 
split(title,"-")[0] as job,
"Freelance" as job_type,
safe_cast(split(salary_tjm,"-")[0] as numeric) as tjm_min,
safe_cast(split(split(split(salary_tjm,"-")[SAFE_OFFSET(1)],",")[SAFE_OFFSET(0)],"€")[SAFE_OFFSET(0)] as numeric) as tjm_max,
 start,
 duration,
 experience,
 remote,
 location,
 key_skills,
 insert_date,
 description
from `dev-env-368414`.`freework`.`job_list`
 where  key_skills like '%Freelance%'and key_skills not like '%CDI%'

  and insert_date > (select coalesce(max(insert_date), '1900-01-01') from `dev-env-368414`.`freework`.`jobs_cleaning_freelance`)

)


select  
*
from source_data 