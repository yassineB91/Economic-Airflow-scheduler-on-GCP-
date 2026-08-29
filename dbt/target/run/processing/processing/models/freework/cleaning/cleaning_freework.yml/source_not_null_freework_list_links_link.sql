select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select link
from `dev-env-368414`.`freework`.`list_links`
where link is null



      
    ) dbt_internal_test