
    
    

with dbt_test__target as (

  select city as unique_field
  from `dev-env-368414`.`freework`.`cities_cleaning_val_doise`
  where city is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


