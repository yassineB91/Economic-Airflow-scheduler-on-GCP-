{% macro get_salary(column_name,mode) %}
    {% if mode =='min' %}
        safe_cast(replace(split(split({{column_name}},",")[SAFE_OFFSET(0)],"-")[SAFE_OFFSET(0)],"k","000") as numeric)
        {% else %}
        safe_cast(replace(split(split({{column_name}},",")[SAFE_OFFSET(0)],"-")[SAFE_OFFSET(1)],"k €/an","000") as numeric)
    {% endif %}
{% endmacro %}


