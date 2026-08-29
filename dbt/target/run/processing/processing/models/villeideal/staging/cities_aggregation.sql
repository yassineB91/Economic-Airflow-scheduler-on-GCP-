
  
    

    create or replace table `dev-env-368414`.`freework`.`cities_aggregation`
      
    
    

    OPTIONS()
    as (
      

with source_data as (

select *, 'yvelines'as departement  from `dev-env-368414`.`raw`.`yvelines`
union all
select *, 'essone'as departement from `dev-env-368414`.`raw`.`essone`
union all
select *, 'seine_et_marne'as departement from `dev-env-368414`.`raw`.`seine_et_marne`
union all
select *, 'seine_saint_denis'as departement from `dev-env-368414`.`raw`.`seine_saint_denis`

)

select *
from source_data
    );
  