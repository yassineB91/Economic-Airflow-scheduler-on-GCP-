{{config(
  materialized='incremental',
  unique_key = 'job_id',
  merge_exclude_columns  = ['insert_date']

)}}

with src_jobs as (
SELECT distinct 
REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(job,r'Ã©', 'é'),r'Ã¨', 'è'),r'Ã¢', 'â'),r'Ã´', 'ô'),
r'Ã', 'í'),r'Ã«', 'ë') AS title,
REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(profil,r'Ã©', 'é'),r'Ã¨', 'è'),r'Ã¢', 'â'),r'Ã´', 'ô'),
r'Ã', 'í'),r'Ã«', 'ë') AS job_category,
REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(skills,r'Ã©', 'é'),r'Ã¨', 'è'),r'Ã¢', 'â'),r'Ã´', 'ô'),
r'Ã', 'í'),r'Ã«', 'ë') AS skills, 
REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(location,r'Ã©', 'é'),r'Ã¨', 'è'),r'Ã¢', 'â'),r'Ã´', 'ô'),
r'Ã', 'í'),r'Ã«', 'ë') AS location, 
    REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(description,r'Ã©', 'é'),r'Ã¨', 'è'),r'Ã¢', 'â'),r'Ã´', 'ô'),
r'Ã', 'í'),r'Ã«', 'ë') AS description,
    REGEXP_EXTRACT(
        LOWER(description),
        r'(\d+(?:\s?\d+)*(?:[.,]\d+)?(?:\s*(?:€|euro|euros)?(?:\s*(?:-|à|a|í)\s*\d+(?:\s?\d+)*(?:[.,]\d+)?(?:\s*(?:€|euro|euros))?)?)?(?:\s*(?:€|euro|euros)|\s*(?:€|euro|euros)\w))'
    ) AS extracted_salary,
     
COALESCE(
    -- Pattern 1: Prioritize "au moins" mentions with experience context (max 14 years for single value)
    REGEXP_EXTRACT(LOWER(description), r'\b(au\s+moins\s+(?:[1-9]|1[0-4]|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze))\s*(?:ans?|années?|years?)(?:\s*d\'?\s*exp(?:érience|é)?|\s+de\s+pratique)?\b'),

    -- Pattern 2: "au moins" mentions in general context (max 14 years for single value)
    REGEXP_EXTRACT(LOWER(description), r'\b(au\s+moins\s+(?:[1-9]|1[0-4]|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze))\s*(?:ans?|années?|years?)\b'),

    -- Pattern 3: Experience ranges and specific experience mentions without "au moins" (allowing full range for ranges)
    REGEXP_EXTRACT(LOWER(description), r'\b((?:[1-9]|1[0-4]|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze)(?:\s*(?:à|a|-|et|ou|to|\/)\s*(?:[1-9]|[1-9]\d|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dix-huit|dix-neuf|vingt|trente|quarante|cinquante))?)\s*(?:ans?|années?|years?)(?:\s*d\'?\s*exp(?:érience|é)?|\s+de\s+pratique)?\b'),

    -- Pattern 4: Experience mentioned before years without "au moins" (allowing full range for ranges)
    REGEXP_EXTRACT(LOWER(description), r'\bexp(?:érience|é)?\s+(?:de|d\'?)\s*((?:[1-9]|1[0-4]|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze)(?:\s*(?:à|a|-|et|ou|to|\/)\s*(?:[1-9]|[1-9]\d|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dix-huit|dix-neuf|vingt|trente|quarante|cinquante))?)\s*(?:ans?|années?|years?)\b'),

    -- Pattern 5: General year mentions without "au moins" (max 14 years for single value, allowing full range for ranges)
    REGEXP_EXTRACT(LOWER(description), r'\b((?:[1-9]|1[0-4]|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze)(?:\s*(?:à|a|-|et|ou|to|\/)\s*(?:[1-9]|[1-9]\d|une?|deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|treize|quatorze|quinze|seize|dix-sept|dix-huit|dix-neuf|vingt|trente|quarante|cinquante))?)\s*(?:ans?|années?|years?)\b'),

    -- Pattern 6: Qualitative experience descriptions (unchanged)
    REGEXP_EXTRACT(LOWER(description), r'\b(première\s+expérience|expérience\s+confirmée|chevronné|junior|senior|confirme\s+)\b')
) AS experience,
  insert_date

FROM `processing-452316.freelance_info.job_list`
 {% if is_incremental() %}
  where jca.insert_date >= (select coalesce(max(insert_date), '1900-01-01') from {{ this }})
{% endif %}
),

 stg_jobs as (
select 
 array_to_string(TEXT_ANALYZE(REGEXP_REPLACE(NORMALIZE(title, NFD), r"\pM", ''), analyzer=>'PATTERN_ANALYZER'),' ') as title,
  SPLIT(skills, ',') as skills,
  location,
  experience,
  replace(replace(trim(replace(split(replace(extracted_salary,'€',''),',')[0],'euro','')),' ',''),'.','') as extracted_salary,
  description as descr,
  array_to_string(TEXT_ANALYZE(REGEXP_REPLACE(NORMALIZE(description, NFD), r"\pM", ''), analyzer=>'PATTERN_ANALYZER'),' ') description,
  insert_date
  from src_jobs

),
stg2_jobs as (
 select 
 title,
skill,
  location,
  descr,
  experience as exp,
 CASE
      WHEN experience IN ("3", "au moins 4", "au moins 3", "4", "trois", "3 à 4", "au moins deux", "2 et 3", "2 à 3", "au moins 2", "3 ou 4", "3-5", "cinq","2-6","2-5","3 et 6",
      "3-4","2-3","au moins 2-3","4 ou 5","2 a 4","3 et 5","2/3","4/5","3/4","3/5","junior") OR experience IS NULL
        THEN "2 à 5 ans d’expérience"
      WHEN experience IN ("première expérience", "2","1","deux","1 ou 2","au moins 1","au moins un","un")  
        THEN "< 2 ans d’expérience"
      WHEN experience IN ("au moins 5", "4 et 6", "5", "7", "10", "expérience confirmée", "5-10", "8", "5 et10", "5 à 10", "6", "5 et 10", "au moins 6","au moins 5-6","au moins 7"
      ,"6-7","8-10","5-7","5-6","5 et 8","9","5-8","7 - 10","au moins 8","6-8","7-10","0 et 7","7/8","6/8","confirme ")
        THEN "5 à 10 ans d’expérience"
      WHEN experience IN ("au moins 10", "4 et 6",'4-5',"10-15","8 et 20","senior") or experience like '%chevronné%'
        THEN "> 10 ans d’expérience"
        
    END AS experience,
  case 
when extracted_salary like '%a%' then split(extracted_salary,'a')[1]
when extracted_salary like '%-%' then split(extracted_salary,'-')[1]
else extracted_salary
end extracted_salary,
  description,
  case
  when description like '%freelance%' or description like '%tjm%' or description like '%tj%' or description like '%tarif%' then "Freelance"
  when description like '%cdi%' or description like '%salaire%' or description like '%remuneration%' then 'CDI'
  else "CDI or Freelance"
  end as job_type,
  insert_date,

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

from stg_jobs
  ,
    UNNEST(skills) AS skill
)
select 
{{dbt_utils.generate_surrogate_key(['title','skill','location'])}} as job_id,
title, 
upper(replace(replace(replace(skill,"'",""),"[",""),"]","")) as skill,
location,
descr,
experience,
job_category,case
when length(extracted_salary)=3 then cast(extracted_salary as numeric)
when length(extracted_salary)=2 and cast(extracted_salary as numeric)>=30 then cast(extracted_salary as numeric)*8
when (length(extracted_salary)=2 and cast(extracted_salary as numeric)<30) or  length(extracted_salary)=4 then null
else null
end tjm,
case
when length(extracted_salary)=3 then null
when length(extracted_salary)=2 and cast(extracted_salary as numeric)>=30 then null
when (length(extracted_salary)=2 and cast(extracted_salary as numeric)<30) or  length(extracted_salary)=4 then null
when length(extracted_salary)=5 then cast(extracted_salary as numeric)
end salary,
job_type,
insert_date

from stg2_jobs