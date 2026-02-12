
  
    

    create or replace table `processing-452316`.`freework`.`jobs_cleaning`
      
    
    

    OPTIONS()
    as (
      

with source_data as (
select 
*
from `processing-452316`.`freework`.`job_list`
where cast(cast(insert_date as timestamp) as date) = "2024-05-22"

)

select  
*
from source_data
    );
  