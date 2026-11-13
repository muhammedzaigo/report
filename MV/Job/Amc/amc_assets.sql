CREATE MATERIALIZED VIEW public.mv_amc_assets_agg AS
SELECT 
    ja.amc_id,
    COUNT(DISTINCT a.id) as amc_asset_count,
    string_agg(DISTINCT a.name, ', ' ORDER BY a.name) as amc_asset_names,
    array_agg(a.id::text ) AS amc_asset_ids,

    jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'name', a.name
        )
    ) as amc_assets
FROM job_schema.amc_types ja
INNER JOIN job_schema.assets a
    ON ja.asset_id = a.id
WHERE ja.status = 'active' AND ja.type = 'asset'
  AND a.status = 'active'
GROUP BY ja.amc_id;
