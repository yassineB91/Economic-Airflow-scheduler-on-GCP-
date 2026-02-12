

with source_data as (

select *, 'yvelines'as departement  from `processing-452316`.`villeideal`.`yvelines`
union all
select *, 'essone'as departement from `processing-452316`.`villeideal`.`essone`
union all
select *, 'seine_et_marne'as departement from `processing-452316`.`villeideal`.`seine_et_marne`
union all
select *, 'seine_saint_denis'as departement from `processing-452316`.`villeideal`.`seine_saint_denis`

)

select *
from source_data