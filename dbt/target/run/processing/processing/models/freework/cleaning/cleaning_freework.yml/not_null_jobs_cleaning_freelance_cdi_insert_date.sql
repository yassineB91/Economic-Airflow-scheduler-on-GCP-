select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select insert_date
from `processing-452316`.`freework`.`jobs_cleaning_freelance_cdi`
where insert_date is null



      
    ) dbt_internal_test