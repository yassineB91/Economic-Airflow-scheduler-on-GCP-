

{{ config(materialized='table') }}

with source_data as (
select 
*
from {{ source('raw_cities','val_doise') }}


)

select  
city,
{{get_note('Commerces')}}  as Commerces,
{{get_note('Culture')}}  as Culture,
{{get_note('Enseignement')}}  as Enseignement,
{{get_note('Environnement')}} as Environnement,
{{get_note('Qualit___de_vie')}}  as Qualite_de_vie,
{{get_note('sant__')}}  as sante,
{{get_note('sports_et_loisirs')}} as sport_et_loisir,
{{get_note('s__curit__')}}  as securite,
{{get_note('Transports')}}  as transport,
"hauts-de-seine" as departement,
current_date() as updated_at
from source_data


