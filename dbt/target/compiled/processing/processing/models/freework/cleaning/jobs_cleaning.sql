

with source_data as (
select 
*
from `dev-env-368414`.`freework`.`job_list`
where cast(cast(insert_date as timestamp) as date) = "2024-05-22"

)

select  
*
from source_data