select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select job_type
from `dev-env-368414`.`freework`.`jobs_cleaning_cdi`
where job_type is null



      
    ) dbt_internal_test