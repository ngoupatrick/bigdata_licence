-- merge: insert new records and update existing
-- delete+insert

{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge',
    indexes=[
      {'columns': ['id'], 'type': 'hash'},
      {'columns': ['id','code'], 'unique': True}
    ]
) }}


WITH base_data AS (
    SELECT
        id,
        code,
        name,
        address,
        create_at,
        gender,
        COALESCE(status, TRUE) as status,
        CAST(current_timestamp AS TIMESTAMP(6)) as ingested_at,
        'boutique_a' as source
    FROM {{ source('boutique_a_source', 'client') }}
)

SELECT
    *,
    -- Extraction des composants temporels
    EXTRACT(YEAR FROM ingested_at) as ingested_year,
    EXTRACT(MONTH FROM ingested_at) as ingested_month,
    EXTRACT(DAY FROM ingested_at)   as ingested_day,
    EXTRACT(HOUR FROM ingested_at)  as ingested_hour,
    EXTRACT(MINUTE FROM ingested_at) as ingested_minute
FROM base_data

{% if is_incremental() %}
  -- Optionnel : si vous voulez limiter la lecture source (date ou id: unique_key)
  -- WHERE source_date > (SELECT max(updated_at) FROM {{ this }})
  WHERE id > (SELECT max(id) FROM {{ this }})
{% endif %}


