

with danem as
(SELECT
  jca.title as job ,jca.description,jca.salary,jca.insert_date,concat(jca.location_region,", ",jca.location_country) as location, to_hex(md5(cast(coalesce(cast(jca.link as string), '_dbt_utils_surrogate_key_null_') as string))) as link_id,
  COALESCE(
    REGEXP_EXTRACT(LOWER(jca.description), r'\b((?:au\s+moins\s+)?(?:\d+|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix)(?:\s*(?:à|a|-|et|ou|to)\s*(?:\d+|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix))?)\s*(?:an(?:s|née?s?)|years?)\b'),
    REGEXP_EXTRACT(LOWER(jca.description), r'\b((?:au\s+moins\s+)?(?:\d+|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix)(?:\s*(?:à|a|-|et|ou|to)\s*(?:\d+|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix))?)\s*(?:an(?:s|née?s?)|years?)\s+d\'expérience'),
    REGEXP_EXTRACT(LOWER(jca.description), r'expérience\s+(?:de|d\'?)\s*((?:au\s+moins\s+)?(?:\d+|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix)(?:\s*(?:à|a|-|et|ou|to)\s*(?:\d+|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix))?)\s*(?:an(?:s|née?s?)|years?)'),
    REGEXP_EXTRACT(LOWER(jca.description), r'(première\s+expérience)'),
    REGEXP_EXTRACT(LOWER(jca.description), r'(expérience\s+confirmée)')
  ) AS experience,
  case 
when jca.salary like '%000%' or LENGTH(jca.salary)>3  then 'CDI'
else 'Freelance'
end job_type,
array_to_string(TEXT_ANALYZE(REGEXP_REPLACE(NORMALIZE(jca.title, NFD), r"\pM", ''), analyzer=>'PATTERN_ANALYZER'),' ') as title,
coalesce(t.Technology,'') as skill
from `dev-env-368414`.`danem_people`.`danem_cleaning_aggregation` jca
left JOIN 
    `dev-env-368414`.`freework`.`technologies` t
  on 
    LOWER(jca.description) LIKE CONCAT('%', LOWER(t.Technology), '%') and jca.description is not null and jca.description<>""
where jca.job_category_class in ("Big Data","ERP &amp; CRM","Télécommunications","Systèmes / Réseaux et Télécoms","Cybersécurité","Business Intelligence","Développement Web &amp; Mobile")
 
),
stg_job as (
select job,description, experience,salary,job_type,
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
end as profile, location, insert_date,link_id,
ARRAY_AGG(skill) AS matched_skills
from danem
GROUP BY  job,description, experience,salary,job_type,profile,location, insert_date,link_id)

select * from stg_job


