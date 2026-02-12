select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select job_type
from `processing-452316`.`freework`.`jobs_cleaning_freelance_cdi`
where job_type is null



      
    ) dbt_internal_test