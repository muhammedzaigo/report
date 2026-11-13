CREATE MATERIALIZED VIEW public.mv_job_cost_tracking_agg AS
SELECT 
    jac.job_id,
    jsonb_agg(
        jsonb_build_object(
            'id', jac.id,
            'cost', jac.cost
        )
    ) as job_add_costs
FROM job_schema.job_add_costs jac
LEFT JOIN job_schema.job_cost_tracking_settings cts 
    ON jac.cost_tracking_category_id = cts.id 
    AND cts.status = 'active'
WHERE jac.status = 'active'
GROUP BY jac.job_id;
