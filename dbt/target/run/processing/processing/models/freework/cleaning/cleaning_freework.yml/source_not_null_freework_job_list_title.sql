select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select title
from `dev-env-368414`.`freework`.`job_list`
where title is null



      
    ) dbt_internal_test