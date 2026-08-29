
  
    

    create or replace table `dev-env-368414`.`freework`.`cities_cleaning_val_doise`
      
    
    

    OPTIONS()
    as (
      

with source_data as (
select 
*
from `dev-env-368414`.`villeideal`.`val_doise`


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
"val_d'oise" as departement,
current_date() as updated_at
from source_data
    );
  