{{config(
    materialized="incremental",
    unique_key=['job_id'])}}

with source_data as (
with jobs as (
select  distinct array_to_string(TEXT_ANALYZE(REGEXP_REPLACE(NORMALIZE(job, NFD), r"\pM", ''), analyzer=>'PATTERN_ANALYZER'),' ') as title,job, job_id
from {{ref('jobs_modeling_fact_jobs_initial')}}
{% if is_incremental() %}
  where insert_date >= (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
)
select distinct title,job,job_id,
case
when title like '%technicien%'
then "Technicien"

------------------------------
when title like '%po%' or title like '%product%owner%' or title like '%chef%projet%' or title like '%chef de projet%' or title like '%product'  or title like '%project%manager%' or title like '%change%' or title like '%pmo%' or title like '%pm' or title like '%pilote projet%' or title like'%coordinat%projet%' or title like'%coordinateur%' 
then "Project manager/ Product Owner"

------------------------------
when title like '%architecte%' or title like '%architect%'
then "Architect"
-------------------------------
when title like '%data%engineer%' or title like '%informatica%' or title like '%talend%' or title like '%odi%'  or title like '%etl%'  or title like '%kafka%' or title like '%ingenieur%data%' or title like '%data%ingenieur%' or title like '%tech%data%'
then "Data Engineer"

-------------------------------
when title like '%data%scientist%' or title like '%machine%learning%'
then "Data Scientist/ ML Engineer"

-------------------------------
when title like '%data management%' or title like '%rgpd%' or  title like '%gdpr%' or title like '%data governance%' or title like '%data gouvernance%' or title like '%management data%' or title like '%mdm%'
then "Data management Consultant"

-------------------------------
when title like '%data analyst%' or title like '%analyste%data%' or title like '%tableau%' or title like '%powerbi%' or title like '%power%bi%' or title like '%sas%' or title like '%qlik%' or title like '%business%intelligence%' or title like '% bi %'
then "Data analyst/ visualization/ BI"

-------------------------------
when title like '%devops%' or title like '%kubernetes%' or title like '%ansible%' or title like '%sauvegarde%' or title like '%supervision%' or title like '%infra%' or title like '%sysops%' or title like '%elk%' or  title like '%elastic search%'
then 'Devops Engineer'

-------------------------------
when title like '%scrum master%' or title like '%master%'
then "Scrum Master"

-------------------------------
when title like '%coach%'
then "Agile Coach" 

------------------------------
when title like '%testeur%' or title like '%test%' or title like '%qa%' or title like '%recette%' or title like '%quality%' 
then "Tester/ Software Quality Engineer"

-------------------------------
when title like '%dev%' or title like '%java%'or title like '%drupal%' or title like '%developpeur%'  or title like '%backend%'  or title like '%frontend%'  or title like '%php%' or title like '%software%' or title like '%react%' or title like '%front%' or title like '%js%' or title like '%angular%' or title like '%golang%' or title like '%net' or title like '%concepteur%' or title like '%ingenieur etudes%'
or title like '%full%stack%'
then 'Developer'


------------------------------
when title like '%erp%' or title like '%sap%' or title like '%dynamics%' or title like '%oracle ebs%' or title like '%sd%' or title like '%mm%' or title like '%fi co%' or  title like '%hana%' or  title like '%wms%' or  title like '%salesforce%' or  title like '%sales force%' or  title like '%microsoft%' or  title like '%sage%' or  title like '%ivalua%' or  title like '%maximo%' or  title like '%workday%' or  title like '%jd%edward%' or  title like '%odoo%' or  title like '%genesys%'
then "ERP Consultant"

------------------------------

when title like '%directeur%' or title like '%direction%' or title like '%manager%' or title like '%cto%' or title like '%chef exploitation%'
then "Management"

------------------------------
when title like '%dba%' or title like '%oracle%' or title like '%sql%'  or title like '%mongo%db%'  or title like '%bdd%' or title like '%base%donnees%' 
then "DBA"

------------------------------
when title like '%business analyst%' or title like '%business analysis%' or title like '%fonctionnel%' or title like '%moa%' or title like '%maitrise%ouvrage%'
or title like '%technico%' or title like '%ouvrage%'
then "Business Analyst /MOA"

------------------------------


when title like '%securite%' or title like '%cyber%' or title like '%security%' or title like '%soc%' or title like '%siem%' or title like '%pentester%' or title like '%antivirus%'
then "Cyber Security Consultant"



------------------------------
when title like '%reseau%' or title like '%network%' or title like '%cisco%' or title like '%rssi%'  or title like '%telecom%'
then "Network/Telecommunication Consultant"

------------------------------
when title like '%cloud%' or title like '%gcp%' or title like '%aws%' or title like '%azure%' or title like '%google cloud%' or title like '%alibaba%'
then "Cloud"

-----------------------------
when title like '%vmware%' or title like '%virtualisation%'
then "Virtualization Consulatnt"

-----------------------------
when title like '%linux%' or title like '%admin%' or title like '%administrateur%' or title like '%administration%' or title like '%autosys%' or title like '%solaris%' or title like '%production%' or title like '%as400%' or title like  '%ordonnanceur%' or title like  '%middleware%'  or title like  '%ibm%mq%'   or title like '%ingenieur%systeme%'
or title like '%windows%' or title like '%365%' or title like '%modern%workplace%' or title like '%ingenieur%system%' or title like '%integrateur%' or title like '%analyste exploitation%'
then "System Administration/ Infrastructure"

-----------------------------
when title like '%controleur%gestion%' or title like '%controle%gestion%' or title like '%administration%'
then "Controleur de Gestion"

-----------------------------
when title like '%servicenow%' or title like '%service now%' or title like '%aveva%' or title like '%cmdb%'
then "CMDB Consultant"

-----------------------------
else "other"
end as job_category
from jobs )

select * from source_data