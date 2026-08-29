select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select departement
from `dev-env-368414`.`freework`.`cities_cleaning`
where departement is null



      
    ) dbt_internal_test