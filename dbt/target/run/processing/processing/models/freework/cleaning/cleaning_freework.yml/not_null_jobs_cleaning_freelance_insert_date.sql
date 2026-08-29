select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select insert_date
from `dev-env-368414`.`freework`.`jobs_cleaning_freelance`
where insert_date is null



      
    ) dbt_internal_test