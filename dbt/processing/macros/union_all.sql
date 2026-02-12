{% macro union_all(tables_list=['cities_cleaning_hauts_de_seine',
                    'cities_cleaning_paris',
                    'cities_cleaning_seine_saint_denis',
                    'cities_cleaning_val_de_marne',
                    'cities_cleaning_val_doise']) %}
    {% set query %}
        {% for table in tables_list %}
            SELECT * FROM {{ref(table)}}
            {% if not loop.last %}
                UNION ALL
            {% endif %}
        {% endfor %}
    {% endset %}
    {{return(query)}}

{% endmacro %}