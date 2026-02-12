with location as (
  select distinct location_id, location, split(location,",")[0] as loc
 from `processing-452316`.`freework`.`jobs_modeling_location` )
 select distinct l.location, l.loc,
 case
 when l.loc=c.nom_commune then c.nom_commune
 when l.loc=c.nom_commune_complet then c.nom_commune_complet
 when l.loc=c.nom_departement then c.nom_departement
 when l.loc=c.nom_region then c.nom_region 
 else l.loc
 end location_to_display
  from location l
 left outer join `processing-452316`.`freework`.`communes` c
 on l.loc=c.nom_commune or l.loc=c.nom_commune_complet or l.loc=c.nom_departement or l.loc=c.nom_region 
 where l.location not like "%<%" and l.location not like "%Télétravail%" and l.location not like ""