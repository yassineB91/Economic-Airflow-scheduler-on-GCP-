{% macro get_skills(column_name) %}
    trim((replace(replace(replace({{column_name}},"[",""),"]",""),"'","")))
{% endmacro %}