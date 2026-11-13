CREATE MATERIALIZED VIEW public.mv_job_amc_services_agg AS
SELECT 
    ja.job_id,
    COUNT(DISTINCT i.id) as amc_service_count,
    string_agg(DISTINCT i.item_name, ', ' ORDER BY i.item_name) as amc_service_names,
    array_agg(i.id::text ) AS amc_service_ids,

    jsonb_agg(
        jsonb_build_object(
            'id', i.id,
            'name', i.item_name
        )
    ) as job_amc_services
FROM job_schema.job_amc_or_assets ja
INNER JOIN accounting_schema.inventory_items i
    ON ja.service_id = i.id::text
WHERE ja.status = 'active' AND ja.service_category = 'Amc' AND ja.amc_type = 'Service'
  AND i.status = 'active' AND i.item_type = 'Service'
GROUP BY ja.job_id;
