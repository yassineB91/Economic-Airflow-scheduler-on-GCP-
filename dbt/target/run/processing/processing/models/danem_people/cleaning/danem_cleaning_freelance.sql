
  
    

    create or replace table `processing-452316`.`danem_people`.`danem_cleaning_freelance`
      
    partition by timestamp_trunc(insert_date, day)
    

    OPTIONS()
    as (
      

with src_freelance as (
select 
*
from `processing-452316`.`danem_people`.`job_list` where job_type="Freelance"

)
,

 stg_freelance as (
select
SPLIT(link, '/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(link, '/')) - 2)] AS  title,
link,
case
when lower(split(salary_tjm,' ')[0]) like '%tjm%'
then ''
when split(salary_tjm,' ')[0] like '%-%'
then replace(split(split(salary_tjm,' ')[0],'-')[1],'€','')
else replace(split(salary_tjm,' ')[0],'€','')
end tjm,
sector as job_category_class,
description,
 insert_date,
location_country,
location_region
from src_freelance)

select * from stg_freelance
    );
  