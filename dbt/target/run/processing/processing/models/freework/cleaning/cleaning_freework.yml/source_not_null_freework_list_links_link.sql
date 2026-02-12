select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select link
from `processing-452316`.`freework`.`list_links`
where link is null



      
    ) dbt_internal_test