
  
    

    create or replace table `processing-452316`.`freework`.`cities_aggregation`
      
    
    

    OPTIONS()
    as (
      

with source_data as (

select *, 'yvelines'as departement  from `processing-452316`.`raw`.`yvelines`
union all
select *, 'essone'as departement from `processing-452316`.`raw`.`essone`
union all
select *, 'seine_et_marne'as departement from `processing-452316`.`raw`.`seine_et_marne`
union all
select *, 'seine_saint_denis'as departement from `processing-452316`.`raw`.`seine_saint_denis`

)

select *
from source_data
    );
  