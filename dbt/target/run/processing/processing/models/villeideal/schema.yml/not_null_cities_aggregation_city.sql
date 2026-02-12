select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select city
from `processing-452316`.`freework`.`cities_aggregation`
where city is null



      
    ) dbt_internal_test