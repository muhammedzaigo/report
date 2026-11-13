CREATE MATERIALIZED VIEW public.mv_amc_services_agg AS
SELECT 
    ja.amc_id,
    COUNT(DISTINCT i.id) as amc_service_count,
    string_agg(DISTINCT i.item_name, ', ' ORDER BY i.item_name) as amc_service_names,
    array_agg(i.id::text ) AS amc_service_ids,

    jsonb_agg(
        jsonb_build_object(
            'id', i.id,
            'name', i.item_name
        )
    ) as amc_services
FROM job_schema.amc_types ja
INNER JOIN accounting_schema.inventory_items i
    ON ja.service_id = i.id
WHERE ja.status = 'active' AND ja.type = 'service'
GROUP BY ja.amc_id;