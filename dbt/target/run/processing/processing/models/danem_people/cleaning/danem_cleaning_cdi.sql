
  
    

    create or replace table `dev-env-368414`.`danem_people`.`danem_cleaning_cdi`
      
    partition by timestamp_trunc(insert_date, day)
    

    OPTIONS()
    as (
      

with src_cdi as (
select 

*
from `dev-env-368414`.`danem_people`.`job_list` where job_type="CDI"

),
 stg_cdi as (
select
SPLIT(link, '/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(link, '/')) - 2)] AS  title,
link,
case
when salary_tjm like '%-%' then replace(replace(split(replace(replace(replace(replace(split(salary_tjm,'-')[1],',',''),'.',''),'k','000'),'K','000'),' ')[0],'€',''),'CHF','')
when salary_tjm like '%Négociable%' then ''
else replace(replace(split(replace(replace(replace(replace(replace(salary_tjm,'par an',''),',',''),'.',''),'k','000'),'K','000'),' ')[0],'€',''),'CHF','')
end salary,
sector as job_category_class,
description,
 insert_date,
location_country,
location_region

from src_cdi)

select * from stg_cdi
    );
  