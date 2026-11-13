CREATE MATERIALIZED VIEW public.mv_job_assets_agg AS
SELECT 
    ja.job_id,
    COUNT(DISTINCT a.id) as asset_count,
    string_agg(DISTINCT a.name, ', ' ORDER BY a.name) as asset_names,
    array_agg(a.id::text ) AS asset_ids,

    jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'name', a.name
        )
    ) as job_assets
FROM job_schema.job_amc_or_assets ja
INNER JOIN job_schema.assets a
    ON ja.asset_id = a.id
WHERE ja.status = 'active' AND ja.service_category = 'Asset'
  AND a.status = 'active'
GROUP BY ja.job_id;
