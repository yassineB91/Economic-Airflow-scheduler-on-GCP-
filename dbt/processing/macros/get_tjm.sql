{% macro get_tjm(column_name,mode) %}
    {% if mode =='min' %}
        safe_cast(split(split({{column_name}},",")[SAFE_OFFSET(1)],"-")[SAFE_OFFSET(0)] as numeric)
        {% else %}
        safe_cast(replace(split(split({{column_name}},",")[SAFE_OFFSET(1)],"-")[SAFE_OFFSET(1)]," €/j","") as numeric)
    {% endif %}
{% endmacro %}