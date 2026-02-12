

with source_data as (
select 
*
from `processing-452316`.`villeideal`.`val_doise`


)

select  
city,
trim(REPLACE(Commerces,"-",""))  as Commerces,
trim(REPLACE(Culture,"-",""))  as Culture,
trim(REPLACE(Enseignement,"-",""))  as Enseignement,
trim(REPLACE(Environnement,"-",""))  as Environnement,
trim(REPLACE(Qualit__de_vie,"-",""))  as Qualite_de_vie,
trim(REPLACE(sant_,"-",""))  as sante,
trim(REPLACE(sport_et_loisir,"-",""))  as sport_et_loisir,
trim(REPLACE(s_curit_,"-",""))  as securite,
trim(REPLACE(Transports,"-",""))  as transport,
"val_d'oise" as departement
from source_data