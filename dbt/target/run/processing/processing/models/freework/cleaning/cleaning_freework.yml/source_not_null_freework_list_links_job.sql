select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select job
from `dev-env-368414`.`freework`.`list_links`
where job is null



      
    ) dbt_internal_test