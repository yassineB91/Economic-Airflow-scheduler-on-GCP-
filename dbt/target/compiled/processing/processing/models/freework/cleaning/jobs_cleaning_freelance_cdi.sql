

with source_data as (
select 
split(title,"-")[0] as job,
"CDI or Freelance" as job_type,

    
        safe_cast(replace(split(split(salary_tjm,",")[SAFE_OFFSET(0)],"-")[SAFE_OFFSET(1)],"k €/an","000") as numeric)
    
 as salary_min,

    
        safe_cast(replace(split(split(salary_tjm,",")[SAFE_OFFSET(0)],"-")[SAFE_OFFSET(1)],"k €/an","000") as numeric)
    
 as salary_max,

    
        safe_cast(split(split(salary_tjm,",")[SAFE_OFFSET(1)],"-")[SAFE_OFFSET(0)] as numeric)
        
 as tjm_min,

    
        safe_cast(replace(split(split(salary_tjm,",")[SAFE_OFFSET(1)],"-")[SAFE_OFFSET(1)]," €/j","") as numeric)
    
 as tjm_max,
 start,
 duration,
 experience,
 remote,
 location,
 key_skills,
 insert_date,
 description
from `dev-env-368414`.`freework`.`job_list`
 where  key_skills like '%Freelance%'and key_skills  like '%CDI%'

)

select  
*
from source_data