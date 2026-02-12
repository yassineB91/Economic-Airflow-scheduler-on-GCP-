select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select job_id
from `processing-452316`.`freework`.`jobs_modeling_fact_jobs`
where job_id is null



      
    ) dbt_internal_test