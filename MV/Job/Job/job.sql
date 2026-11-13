CREATE MATERIALIZED VIEW public.mv_jobs AS
SELECT 
    /* CORE JOB IDENTIFIERS */
    j.id,
    j.encrypted_id,
    j.job_no,

    /* CUSTOMER INFORMATION */
    j.customer_type,
    j.company_id,
    comp.name AS company_name,
    j.contact_id,
    cont.name AS contact_name,
    j.lead_id,
    l.name AS lead_name,

    /* JOB BASIC INFO */
    j.title,
    j.description,
    j.job_type,
    j.job_status,
    j.service_category,
    j.location,
    j.estimated_hours,
    j.estimated_minutes,
    j.location_id,
    loc.name AS primary_location_name,
    
    /* SCHEDULING */
    j.job_created_from,
    j.job_start_date,
    j.job_start_time,
    j.job_end_date,
    j.job_end_time,
    j.assign_to,

    /* TIME TRACKING */
    j.actual_time_spent,
    j.job_value,
    j.tenant_id,
    j.workspace_id,
    j.created_by,
    j.updated_by,
    j.updated_at,
    j.created_at,
    j.status,

    /* JOB CLASSIFICATIONS */
    j.business_unit_id,
    bu.option AS business_unit_name,
    j.service_type_id,
    st.option AS service_type_name,
    j.priority_id,
    pr.option AS priority_name,
    
    /* AMC INFORMATION */
    j.amc_id,
    amc.title AS amc_title,

    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,

    techs.technician_names,
    techs.assigned_technicians_ids,
    techs.assigned_technicians,
    
    time_track.job_add_times,
    cost_track.job_add_costs,
    
    teams.team_names,
    teams.assigned_teams_ids,
    teams.assigned_teams,

    checklists.checklist_names,
    checklists.checklist_ids,
    checklists.assign_checklists,
    
    amc_assets.amc_asset_names,
    amc_assets.amc_asset_ids,
    amc_assets.job_amc_assets,
    
    amc_servies.amc_service_names,
    amc_servies.amc_service_ids,
    amc_servies.job_amc_services,
    
    assets.asset_names,
    assets.asset_ids,
    assets.job_assets,

    COALESCE(
        array_agg(DISTINCT jt.tag ORDER BY jt.tag)
        FILTER (WHERE jt.tag IS NOT NULL),
        ARRAY[]::text[]
    ) AS tags,

    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields,
    COALESCE(cf_add_on_agg.add_on_custom_fields, '[]'::jsonb) AS add_on_custom_fields

FROM job_schema.jobs j
LEFT JOIN job_schema.job_defaultfield_option bu ON bu.id = j.business_unit_id AND bu.status = 'active'
LEFT JOIN job_schema.job_defaultfield_option st ON st.id = j.service_type_id AND st.status = 'active'
LEFT JOIN job_schema.job_defaultfield_option pr ON pr.id = j.priority_id AND pr.status = 'active'
LEFT JOIN user_schema.companies comp ON j.company_id = comp.id::text
LEFT JOIN user_schema.contacts cont ON j.contact_id = cont.id::text
LEFT JOIN user_schema.locations loc ON j.location_id = loc.id::text
LEFT JOIN job_schema.leads l ON j.lead_id = l.id AND l.status = 'active'
LEFT JOIN job_schema.amcs amc ON j.amc_id = amc.id AND amc.status = 'active'
LEFT JOIN user_schema.users created_user ON j.created_by = created_user.id
LEFT JOIN user_schema.users updated_user ON j.updated_by = updated_user.id
LEFT JOIN job_schema.job_tags jt ON jt.job_id = j.id
LEFT JOIN public.mv_job_technicians_agg techs ON techs.job_id = j.id
LEFT JOIN public.mv_job_teams_agg teams ON teams.job_id = j.id
LEFT JOIN public.mv_job_checklists_agg checklists ON checklists.job_id = j.id
LEFT JOIN public.mv_job_time_tracking_agg time_track ON time_track.job_id = j.id
LEFT JOIN public.mv_job_cost_tracking_agg cost_track ON cost_track.job_id = j.id
LEFT JOIN public.mv_job_assets_agg assets ON assets.job_id = j.id
LEFT JOIN public.mv_job_amc_services_agg amc_servies ON amc_servies.job_id = j.id
LEFT JOIN public.mv_job_amc_assets_agg amc_assets ON amc_assets.job_id = j.id

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
        'editor', cf.editor,
        'selected_options', cf.selected_options,
        'searchable_value', cf.searchable_value
    )) AS custom_fields
    FROM public.mv_job_custom_fields cf
    WHERE cf.job_id = j.id
) cf_agg ON true

LEFT JOIN LATERAL (
    SELECT jsonb_agg(jsonb_build_object(
        'id', cfaddon.id,
        'customfield_id', cfaddon.customfield_id,
        'field_name', cfaddon.field_name,
        'field_label', cfaddon.field_label,
        'field_type', cfaddon.field_type,
        'required', cfaddon.required,
        'value', cfaddon.value,
        'value_json', cfaddon.value_json,
        'value_date', cfaddon.value_date,
        'value_time', cfaddon.value_time,
        'editor', cfaddon.editor,
        'selected_options', cfaddon.selected_options,
        'searchable_value', cfaddon.searchable_value
    )) AS add_on_custom_fields
    FROM public.mv_job_add_on_custom_fields cfaddon
    WHERE cfaddon.job_id = j.id
) cf_add_on_agg ON true

WHERE j.status NOT IN ('deleted', 'draft') AND j.job_type = 'Job'
GROUP BY
    j.id, j.encrypted_id, j.job_no, j.customer_type, j.company_id, comp.name, j.contact_id, 
    cont.name, j.lead_id, l.name, j.title, j.description, j.job_type, j.job_status, 
    j.service_category, j.location, j.location_id, loc.name, j.estimated_hours, 
    j.estimated_minutes, j.job_created_from, j.job_start_date, j.job_start_time, 
    j.job_end_date, j.job_end_time, j.actual_time_spent, j.job_value, j.tenant_id, 
    j.workspace_id, j.created_by, j.updated_by, j.updated_at, j.created_at, j.status, 
    j.business_unit_id, bu.option, j.service_type_id, st.option, j.priority_id, pr.option, 
    j.amc_id, amc.title, created_user.name, updated_user.name, techs.technician_names, 
    j.assign_to, techs.assigned_technicians_ids, techs.assigned_technicians, time_track.job_add_times, 
    cost_track.job_add_costs, teams.team_names, teams.assigned_teams_ids, teams.assigned_teams, 
    checklists.checklist_names, checklists.checklist_ids, checklists.assign_checklists, 
    amc_assets.amc_asset_names, amc_assets.amc_asset_ids, amc_assets.job_amc_assets, 
    amc_servies.amc_service_names, amc_servies.amc_service_ids, amc_servies.job_amc_services, 
    assets.asset_names, assets.asset_ids, assets.job_assets, cf_agg.custom_fields, 
    cf_add_on_agg.add_on_custom_fields;

CREATE UNIQUE INDEX idx_mv_jobs_pk
ON public.mv_jobs(id);

CREATE INDEX idx_mv_jobs_tenant_workspace
ON public.mv_jobs(tenant_id, workspace_id);

CREATE INDEX idx_mv_jobs_job_no
ON public.mv_jobs(job_no);

CREATE INDEX idx_mv_jobs_encrypted_id
ON public.mv_jobs(encrypted_id);

CREATE INDEX idx_mv_jobs_company
ON public.mv_jobs(company_id);

CREATE INDEX idx_mv_jobs_contact
ON public.mv_jobs(contact_id);

CREATE INDEX idx_mv_jobs_lead
ON public.mv_jobs(lead_id);

CREATE INDEX idx_mv_jobs_job_status
ON public.mv_jobs(job_status);

CREATE INDEX idx_mv_jobs_job_type
ON public.mv_jobs(job_type);

CREATE INDEX idx_mv_jobs_service_category
ON public.mv_jobs(service_category);

CREATE INDEX idx_mv_jobs_priority
ON public.mv_jobs(priority_id);

CREATE INDEX idx_mv_jobs_business_unit
ON public.mv_jobs(business_unit_id);

CREATE INDEX idx_mv_jobs_service_type
ON public.mv_jobs(service_type_id);

CREATE INDEX idx_mv_jobs_start_date
ON public.mv_jobs(job_start_date);

CREATE INDEX idx_mv_jobs_end_date
ON public.mv_jobs(job_end_date);

CREATE INDEX idx_mv_jobs_created_at
ON public.mv_jobs(created_at);

CREATE INDEX idx_mv_jobs_updated_at
ON public.mv_jobs(updated_at);

CREATE INDEX idx_mv_jobs_amc
ON public.mv_jobs(amc_id);

CREATE INDEX idx_mv_jobs_technicians_gin
ON public.mv_jobs
USING gin (assigned_technicians_ids);

CREATE INDEX idx_mv_jobs_teams_gin
ON public.mv_jobs
USING gin (assigned_teams_ids);

CREATE INDEX idx_mv_jobs_tags_gin
ON public.mv_jobs
USING gin (tags);
