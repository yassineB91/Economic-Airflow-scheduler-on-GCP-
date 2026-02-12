{% set old_location_model_query %}
select * from {{ref('jobs_modeling_location')}}
{% endset %}

{% set new_location_model_query %}
select * from {{ref('jobs_modeling_location_standardized')}}
{% endset %}

-- Compare the 'location' column values between the old and new location models using the primary key 'location_id'
{% set audit_query= audit_helper.compare_column_values(
    a_query=old_location_model_query,
    b_query=new_location_model_query,
    primary_key="location_id",
    column_to_compare="location") %}
{% set audit_results= run_query(audit_query) %}  {# Executes the audit query to compare column values and stores the results #}
{% set audit_results= run_query(audit_query) %}

{% if execute %}
    -- Print the audit results table to verify the comparison of 'location' column values
    {% do audit_results.print_table() %}
{% endif %}