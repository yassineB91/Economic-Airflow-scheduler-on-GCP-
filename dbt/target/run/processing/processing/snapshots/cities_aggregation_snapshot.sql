
      merge into `dev-env-368414`.`villeideal`.`cities_aggregation_snapshot` as DBT_INTERNAL_DEST
    using `dev-env-368414`.`villeideal`.`cities_aggregation_snapshot__dbt_tmp` as DBT_INTERNAL_SOURCE
    on DBT_INTERNAL_SOURCE.dbt_scd_id = DBT_INTERNAL_DEST.dbt_scd_id

    when matched
     and DBT_INTERNAL_DEST.dbt_valid_to is null
     and DBT_INTERNAL_SOURCE.dbt_change_type in ('update', 'delete')
        then update
        set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to

    when not matched
     and DBT_INTERNAL_SOURCE.dbt_change_type = 'insert'
        then insert (`city`, `Commerces`, `Culture`, `Enseignement`, `Environnement`, `Qualite_de_vie`, `sante`, `sport_et_loisir`, `securite`, `transport`, `departement`, `updated_at`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`)
        values (`city`, `Commerces`, `Culture`, `Enseignement`, `Environnement`, `Qualite_de_vie`, `sante`, `sport_et_loisir`, `securite`, `transport`, `departement`, `updated_at`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`)


  