CREATE MATERIALIZED VIEW public.mv_tasks AS
SELECT 
    /* CORE JOB IDENTIFIERS */
    j.id,
    j.job_no as task_no,

    /* CUSTOMER INFORMATION */
    j.customer_type,
    j.company_id,
    comp.name AS company_name,
    j.contact_id,
    cont.name AS contact_name,
    j.lead_id,
    l.name AS lead_name,

    j.location_id,
    loc.name AS primary_location_name,
    j.location,

    j.title,
    j.description,
    j.job_start_date,
    j.job_start_time,
    j.job_end_date,
    j.job_end_time,

    /* JOB BASIC INFO */
    j.job_type,

    /* TIME TRACKING */
    j.tenant_id,
    j.workspace_id,
    j.created_by,
    j.updated_by,
    j.updated_at,
    j.created_at,
    j.status,

    /* JOB CLASSIFICATIONS */
    j.task_priority_id,
    pr.option AS priority_name,
        
    j.task_status_id,
    stat.option AS status_name,
    stat.slug AS status_slug,

	j.task_owner_id,
	task_owner.name as task_owner_name,
	
    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,

    techs.technician_names,
    techs.assigned_technicians_ids,
    techs.assigned_technicians,
    
    forms.form_names,
    forms.form_ids,
    forms.assign_forms,
    
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields

FROM job_schema.jobs j
LEFT JOIN job_schema.task_defaultfield_option pr ON pr.id = j.priority_id AND pr.status = 'active'
LEFT JOIN job_schema.task_defaultfield_option stat ON stat.id = j.task_status_id AND stat.status = 'active'
LEFT JOIN user_schema.companies comp ON j.company_id = comp.id::text
LEFT JOIN user_schema.contacts cont ON j.contact_id = cont.id::text
LEFT JOIN user_schema.locations loc ON j.location_id = loc.id::text
LEFT JOIN job_schema.leads l ON j.lead_id = l.id AND l.status = 'active'
LEFT JOIN user_schema.users created_user ON j.created_by = created_user.id
LEFT JOIN user_schema.users updated_user ON j.updated_by = updated_user.id
LEFT JOIN user_schema.users task_owner ON j.task_owner_id = task_owner.id::text
LEFT JOIN public.mv_job_technicians_agg techs ON techs.job_id = j.id
LEFT JOIN public.mv_task_forms_agg forms ON forms.task_id = j.id

LEFT JOIN LATERAL (
    SELECT jsonb_agg(jsonb_build_object(
        'id', cf.id,
        'customfield_id', cf.customfield_id,
        'field_name', cf.field_name,
        'field_label', cf.field_label,
        'field_type', cf.field_type,
        'required', cf.required,
        'value', cf.value,
        'value_json', cf.value_json,
        'value_date', cf.value_date,
        'value_time', cf.value_time,
        'selected_options', cf.selected_options,
        'searchable_value', cf.searchable_value
    )) AS custom_fields
    FROM public.mv_task_custom_fields cf
    WHERE cf.task_id = j.id
) cf_agg ON true

WHERE j.status NOT IN ('DELETED', 'DRAFT')  AND j.job_type = 'Task'
GROUP BY
    j.id, j.job_no, j.customer_type, j.company_id, comp.name, j.contact_id, j.task_priority_id, j.task_status_id, stat.option, stat.slug,
    cont.name, j.lead_id, l.name, j.title, j.description, j.job_type, j.location, j.location_id, loc.name,  j.job_start_date, j.job_start_time, 
    j.job_end_date, j.job_end_time,  j.tenant_id, 
    j.workspace_id, j.created_by, j.updated_by, j.updated_at, j.created_at, j.status, 
     j.priority_id, pr.option, created_user.name, updated_user.name, techs.technician_names, 
    techs.assigned_technicians_ids, techs.assigned_technicians,
    forms.form_names, forms.form_ids, forms.assign_forms, task_owner.name, j.task_owner_id,
     cf_agg.custom_fields;
