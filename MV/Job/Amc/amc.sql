CREATE MATERIALIZED VIEW public.mv_amcs AS
SELECT 
    a.id,
    a.location_id,
    loc.name AS primary_location_name,

    a.title,
    a.customer_type,
    a.company_id,
    comp.name AS company_name,
    a.contact_id,
    cont.name AS contact_name,
    a.status,

    a.prefix,
    a.number,
    a.amc_location,

    a.description,

    a.amc_type,
    a.value,
    a.no_of_visit,
    a.contract,
    a.reminder,
    a.start_date,
    a.expiry_date,

    a.created_at,
    a.updated_at,
    a.created_by,
    a.updated_by,
    a.workspace_id,
    a.tenant_id,
    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,
    -- Custom Fields from lateral join
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields
FROM job_schema.amcs a
LEFT JOIN user_schema.companies comp ON a.company_id = comp.id::text
LEFT JOIN user_schema.contacts cont ON a.contact_id = cont.id::text
LEFT JOIN user_schema.locations loc ON a.location_id = loc.id::text
LEFT JOIN user_schema.users created_user ON a.created_by = created_user.id
LEFT JOIN user_schema.users updated_user ON a.updated_by = updated_user.id
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
    FROM public.mv_amc_custom_fields cf
    WHERE cf.amc_id = a.id
        AND cf.tenant_id = a.tenant_id
        AND cf.workspace_id = a.workspace_id
) cf_agg ON true
WHERE a.status NOT IN ('deleted', 'draft')
GROUP BY 
    a.id, a.location_id,loc.name, a.title, a.status, a.customer_type, a.company_id, comp.name, a.contact_id, cont.name,
    a.prefix, a.number, a.amc_location, a.description, a.amc_type, a.value,  a.no_of_visit, a.contract, a.reminder, a.start_date, a.expiry_date,
    a.created_at, a.updated_at, a.created_by, a.updated_by,
    a.workspace_id, a.tenant_id, created_user.name, updated_user.name,
    cf_agg.custom_fields;

-- Recommended: Add a unique index to allow concurrent refresh
CREATE UNIQUE INDEX idx_mv_amcs_id ON public.mv_amcs (id);