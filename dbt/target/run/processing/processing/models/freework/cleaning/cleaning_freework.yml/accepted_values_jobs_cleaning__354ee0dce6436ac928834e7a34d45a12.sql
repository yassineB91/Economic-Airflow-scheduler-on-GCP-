select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        job_type as value_field,
        count(*) as n_records

    from `dev-env-368414`.`freework`.`jobs_cleaning_aggregation`
    group by job_type

)

select *
from all_values
where value_field not in (
    'CDI or Freelance','Freelance','Freelance'
)



      
    ) dbt_internal_test