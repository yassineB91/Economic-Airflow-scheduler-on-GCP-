select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select city
from `processing-452316`.`freework`.`cities_cleaning_val_de_marne`
where city is null



      
    ) dbt_internal_test