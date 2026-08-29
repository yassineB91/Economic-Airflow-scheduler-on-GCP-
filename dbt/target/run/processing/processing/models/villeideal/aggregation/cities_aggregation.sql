
  
    

    create or replace table `dev-env-368414`.`freework`.`cities_aggregation`
      
    
    

    OPTIONS()
    as (
      

with source_data as (

select *, 'yvelines'as departement  from `dev-env-368414`.`villeideal`.`yvelines`
union all
select *, 'essone'as departement from `dev-env-368414`.`villeideal`.`essone`
union all
select *, 'seine_et_marne'as departement from `dev-env-368414`.`villeideal`.`seine_et_marne`
union all
select *, 'seine_saint_denis'as departement from `dev-env-368414`.`villeideal`.`seine_saint_denis`

)

select *
from source_data
    );
  