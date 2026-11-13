SET ROLE reporting_user;
CREATE MATERIALIZED VIEW public.mv_leads AS
SELECT 
    /* CORE LEAD IDENTIFIERS */
    l.id,
    l.lead_no,

    /* CUSTOMER INFORMATION */
    l.customer_type,
    l.company_id,
    comp.name AS company_name,
    l.contact_id,
    cont.name AS contact_name,

    /* LEAD DETAILS */
    l.name,
    l.description,
    l.email,
    l.phone_number,
    l.country_code,
    l.lead_value,


    l.created_location,
    l.created_latitude,
    l.created_longitude,


    l.lead_location,
    l.lead_location_latitude,
    l.lead_location_longitude,


    l.is_converted_customer,
    l.status,
    l.last_comment,

    /* LOCATION */
    l.location_id,
    loc.name AS primary_location_name,

    /* PRIORITY */
    l.priority_id,
    pr.option AS priority_name,

    -- /* LEAD STATUS */
    l.lead_status_id,
    ls.option AS lead_status_name,
    ls.color_code AS lead_status_color,

    /* FOLLOW UP */
    l.follow_up_date,
    l.follow_up_time,

    /* OWNERSHIP */
    l.lead_owner_id,
    lead_owner.name AS lead_owner_name,
    l.assign_to_id,
    assign_to.name AS assign_to_name,

    /* AUDIT */
    l.tenant_id,
    l.workspace_id,
    l.created_by,
    l.updated_by,
    l.created_at,
    l.updated_at,
    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,

    /* forms */
    forms.form_names,
    forms.form_ids,
    forms.assign_forms,

    /* TAGS */
    COALESCE(
        array_agg(DISTINCT jt.tag ORDER BY jt.tag)
        FILTER (WHERE jt.tag IS NOT NULL),
        ARRAY[]::text[]
    ) AS tags,

    /* CUSTOM FIELDS */
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields

FROM job_schema.leads l

/* LOOKUPS */
LEFT JOIN job_schema.lead_defaultfield_option pr
    ON pr.id = l.priority_id AND pr.status = 'active'

LEFT JOIN job_schema.lead_defaultfield_option ls
    ON ls.id = l.lead_status_id AND ls.status = 'active'

LEFT JOIN user_schema.companies comp
    ON l.company_id = comp.id::text

LEFT JOIN user_schema.contacts cont
    ON l.contact_id = cont.id::text

LEFT JOIN user_schema.locations loc
    ON l.location_id = loc.id::text

LEFT JOIN user_schema.users lead_owner
    ON l.lead_owner_id = lead_owner.id::text

LEFT JOIN user_schema.users assign_to
    ON l.assign_to_id = assign_to.id::text
	
LEFT JOIN user_schema.users created_user
    ON l.created_by = created_user.id

LEFT JOIN user_schema.users updated_user
    ON l.updated_by = updated_user.id

/* TAGS */
LEFT JOIN job_schema.lead_tags jt
    ON jt.lead_id = l.id

/* forms */
LEFT JOIN public.mv_lead_forms_agg forms
    ON forms.lead_id = l.id

/* CUSTOM FIELDS (LATERAL) */
LEFT JOIN LATERAL (
    SELECT jsonb_agg(
        jsonb_build_object(
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
        )
    ) AS custom_fields
    FROM public.mv_job_custom_fields cf
    WHERE cf.job_id = l.id
) cf_agg ON true

WHERE l.status NOT IN ('deleted', 'draft')

GROUP BY
    l.id,
    l.lead_no,
    l.customer_type,
    l.company_id,
    comp.name,
    l.contact_id,
    cont.name,
    l.name,
    l.description,
    l.email,
    l.phone_number,
    l.country_code,
    l.lead_value,
    l.is_converted_customer,
    l.last_comment,
    l.status,
    l.location_id,
    loc.name,
    l.priority_id,
    pr.option,
    l.lead_status_id,
    ls.option,
    ls.color_code,
    l.follow_up_date,
    l.follow_up_time,
    l.lead_owner_id,
	lead_owner.name,
    l.assign_to_id,
	assign_to.name,
    l.tenant_id,
    l.workspace_id,
    l.created_by,
    l.updated_by,
    l.created_at,
    l.updated_at,
    created_user.name,
    updated_user.name,
    forms.form_names,
    forms.form_ids,
    forms.assign_forms,
    cf_agg.custom_fields,
    
    l.created_location,
    l.created_latitude,
    l.created_longitude,


    l.lead_location,
    l.lead_location_latitude,
    l.lead_location_longitude;


CREATE UNIQUE INDEX idx_mv_leads_pk
ON public.mv_leads(id);

CREATE INDEX idx_mv_leads_tenant_workspace
ON public.mv_leads(tenant_id, workspace_id);

CREATE INDEX idx_mv_leads_lead_no
ON public.mv_leads(lead_no);

CREATE INDEX idx_mv_leads_company
ON public.mv_leads(company_id);

CREATE INDEX idx_mv_leads_contact
ON public.mv_leads(contact_id);

CREATE INDEX idx_mv_leads_status
ON public.mv_leads(status);

CREATE INDEX idx_mv_leads_priority
ON public.mv_leads(priority_id);

CREATE INDEX idx_mv_leads_created_at
ON public.mv_leads(created_at);

CREATE INDEX idx_mv_leads_updated_at
ON public.mv_leads(updated_at);

CREATE INDEX idx_mv_leads_tags_gin
ON public.mv_leads
USING gin (tags);
