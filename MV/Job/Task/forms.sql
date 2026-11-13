CREATE MATERIALIZED VIEW public.mv_task_forms_agg AS
SELECT 
    ac.job_id as task_id,
 
    COUNT(*) AS form_count,

    string_agg(
        cs.name,
        ', '
        ORDER BY cs.name
    ) AS form_names,

	array_agg(
	    cs.id::text
	) AS form_ids,

    jsonb_agg(
        jsonb_build_object(
            'id', cs.id,
            'name', cs.name,
            'description', cs.description,
            'for_task', cs.for_task
        )
        ORDER BY cs.name
    ) AS assign_forms

FROM job_schema.assign_checklists ac

JOIN job_schema.checklist_settings cs
  ON cs.id = ac.checklist_settings_id

WHERE
    -- ✅ task only
    ac.job_id IS NOT NULL

    -- ✅ checklist meant for task
    AND cs.for_task = TRUE

    -- ✅ active records
    AND ac.status = 'active'
    AND cs.status = 'active'

GROUP BY ac.job_id;
