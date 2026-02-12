{{ config(
    materialized = 'incremental',
    partition_by = {'field': 'insert_date', 'data_type': 'timestamp'},
    incremental_strategy = 'insert_overwrite'
) }}

with src_freelance as (
select 
*
from {{source('danem_people','job_list')}} where job_type="Freelance"
{% if is_incremental() %}
  and insert_date > (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
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