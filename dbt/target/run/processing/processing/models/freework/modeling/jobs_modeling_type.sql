
  
    

    create or replace table `processing-452316`.`freework`.`jobs_modeling_type`
      
    
    

    OPTIONS()
    as (
      

with source_data as (
with type as (select
distinct 
job_type
from `processing-452316`.`freework`.`jobs_cleaning_aggregation`

)
select
to_hex(md5(cast(coalesce(cast(job_type as string), '_dbt_utils_surrogate_key_null_') as string))) as job_type_id, 
job_type
from type
)

select * from source_data
    );
  