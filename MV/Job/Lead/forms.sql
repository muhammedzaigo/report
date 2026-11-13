CREATE MATERIALIZED VIEW public.mv_lead_forms_agg AS
SELECT 
    ac.lead_id,

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
            'for_lead', cs.for_lead
        )
        ORDER BY cs.name
    ) AS assign_forms

FROM job_schema.assign_checklists ac

JOIN job_schema.checklist_settings cs
  ON cs.id = ac.checklist_settings_id

WHERE
    -- ✅ lead only
    ac.lead_id IS NOT NULL

    -- ✅ form meant for lead
    AND cs.for_lead = TRUE

    -- ✅ active records
    AND ac.status = 'active'
    AND cs.status = 'active'

GROUP BY ac.lead_id;
