{% snapshot cities_aggregation_snapshot %}

{{
    config(
        strategy='timestamp',
        unique_key='city',
        updated_at='updated_at',
        target_schema='villeideal'
    )
}}

    {{union_all()}}

{% endsnapshot %}