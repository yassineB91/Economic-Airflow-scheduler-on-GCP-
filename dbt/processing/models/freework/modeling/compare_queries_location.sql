{% set old_location_model %}

select 
location_id,
location 
from {{ref('jobs_modeling_location')}}
{% endset %}

{% set new_location_model %}

select location_id,
location
from {{ref('jobs_modeling_location_standardized')}}
{% endset %}

{{audit_helper.compare_queries(
    a_query=old_location_model,
    b_query=new_location_model,
    primary_key="location_id",
    summarize= true
)}}

