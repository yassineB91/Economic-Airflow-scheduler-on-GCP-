select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select city
from `dev-env-368414`.`freework`.`cities_cleaning_val_doise`
where city is null



      
    ) dbt_internal_test