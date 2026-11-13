CREATE MATERIALIZED VIEW public.mv_job_checklists_agg AS
SELECT 
    ac.job_id,

    COUNT(*) AS checklist_count,

    string_agg(
        cs.name,
        ', '
        ORDER BY cs.name
    ) AS checklist_names,

	array_agg(
	    cs.id::text
	) AS checklist_ids,

    jsonb_agg(
        jsonb_build_object(
            'id', cs.id,
            'name', cs.name,
            'description', cs.description,
            'for_job', cs.for_job
        )
        ORDER BY cs.name
    ) AS assign_checklists

FROM job_schema.assign_checklists ac

JOIN job_schema.checklist_settings cs
  ON cs.id = ac.checklist_settings_id

WHERE
    -- ✅ job only
    ac.job_id IS NOT NULL
    -- ✅ checklist meant for job
    AND cs.for_job = TRUE

    -- ✅ active records
    AND ac.status = 'active'
    AND cs.status = 'active'

GROUP BY ac.job_id;
