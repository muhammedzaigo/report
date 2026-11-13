CREATE MATERIALIZED VIEW public.mv_job_technicians_agg AS
SELECT 
    jat.job_id,
	string_agg(u.name, ', ' ORDER BY u.name) as technician_names,
    array_agg(u.id::text ) AS assigned_technicians_ids,
    jsonb_agg(
        jsonb_build_object(
            'user_id', u.id,
            'name', u.name
        ) ORDER BY u.name
    ) as assigned_technicians
FROM job_schema.job_assigned_technicians jat
INNER JOIN user_schema.users u ON jat.user_id = u.id
WHERE jat.status = 'active'
GROUP BY jat.job_id;
