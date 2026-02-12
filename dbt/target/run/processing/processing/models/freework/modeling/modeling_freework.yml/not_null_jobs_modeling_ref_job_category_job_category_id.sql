select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select job_category_id
from `processing-452316`.`freework`.`jobs_modeling_ref_job_category`
where job_category_id is null



      
    ) dbt_internal_test