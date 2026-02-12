select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select location_id
from `processing-452316`.`freework`.`jobs_modeling_location`
where location_id is null



      
    ) dbt_internal_test