

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
from `processing-452316`.`freework`.`jobs_cleaning_freelance_cdi`


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
from `processing-452316`.`freework`.`jobs_cleaning_cdi`


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
from `processing-452316`.`freework`.`jobs_cleaning_freelance`

)
select  
*
from source_data