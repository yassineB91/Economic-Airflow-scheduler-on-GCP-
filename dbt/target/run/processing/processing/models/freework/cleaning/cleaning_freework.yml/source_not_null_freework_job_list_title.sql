select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select title
from `processing-452316`.`freework`.`job_list`
where title is null



      
    ) dbt_internal_test