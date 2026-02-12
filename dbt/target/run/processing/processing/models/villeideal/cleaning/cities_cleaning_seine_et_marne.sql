
  
    

    create or replace table `processing-452316`.`freework`.`cities_cleaning_seine_et_marne`
      
    
    

    OPTIONS()
    as (
      

with source_data as (
select 
*
from `processing-452316`.`villeideal`.`seine_et_marne`


)

select  
city,

Commerces/100
  as Commerces,

Culture/100
  as Culture,

Enseignement/100
  as Enseignement,

Environnement/100
 as Environnement,

Qualit___de_vie/100
  as Qualite_de_vie,

sant__/100
  as sante,

sports_et_loisirs/100
 as sport_et_loisir,

s__curit__/100
  as securite,

Transports/100
  as transport,
"Seine-et-marne" as departement,
current_date() as updated_at
from source_data
    );
  