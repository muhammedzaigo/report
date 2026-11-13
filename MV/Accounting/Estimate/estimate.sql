CREATE MATERIALIZED VIEW public.mv_estimates AS
SELECT
    e.id,
    e.encrypted_id,

    e.customer_type,
    e.company_id,
    comp.name AS company_name,
    e.contact_id,
    cont.name AS contact_name,
    e.lead_id,
    l.name AS lead_name,

    e.job_id,
    e.location_id,
    loc.name AS primary_location_name,

    e.status_id,
    stat.option AS status_name,
    stat.slug AS status_slug,

    e.sales_person_id,
    sales_person.name AS sales_person_name,

    e.shipping_location,
    e.billing_location,
    e.estimate_no,
    e.expiry_date,
    e.created_date,
    e.reference,
    e.total,
    e.title,

    e.terms_and_condition_setting_id,
    term.name AS terms_and_condition_name,

    e.priority_id,
    pr.option AS priority_name,

    e.tenant_id,
    e.workspace_id,
    e.created_by,
    e.updated_by,
    e.updated_at,
    e.created_at,
    e.status,

    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,

    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields,
    COALESCE(cf_summary_agg.summary_custom_fields, '[]'::jsonb) AS summary_custom_fields,
    COALESCE(cf_secondary_agg.secondary_custom_fields, '[]'::jsonb) AS secondary_custom_fields

FROM accounting_schema.estimates e

LEFT JOIN accounting_schema.estimate_defaultfield_option stat
    ON stat.id = e.status_id AND stat.status = 'active'

LEFT JOIN accounting_schema.estimate_defaultfield_option pr
    ON pr.id = e.priority_id AND pr.status = 'active'

LEFT JOIN accounting_schema.estimate_terms_and_condition_settings term
    ON term.id = e.terms_and_condition_setting_id AND term.status = 'active'

LEFT JOIN user_schema.companies comp ON e.company_id = comp.id::text
LEFT JOIN user_schema.contacts cont ON e.contact_id = cont.id::text
LEFT JOIN user_schema.locations loc ON e.location_id = loc.id::text
LEFT JOIN job_schema.leads l ON e.lead_id = l.id::text AND l.status = 'active'

LEFT JOIN user_schema.users created_user ON e.created_by = created_user.id
LEFT JOIN user_schema.users updated_user ON e.updated_by = updated_user.id
LEFT JOIN user_schema.users sales_person ON e.sales_person_id = sales_person.id::text

LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(cf.*)) AS custom_fields
    FROM public.mv_estimate_custom_fields cf
    WHERE cf.estimate_id = e.id
) cf_agg ON true

LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(cfs.*)) AS summary_custom_fields
    FROM public.mv_estimate_summary_custom_fields cfs
    WHERE cfs.estimate_id = e.id
) cf_summary_agg ON true

LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(cfs.*)) AS secondary_custom_fields
    FROM public.mv_estimate_secondary_custom_fields cfs
    WHERE cfs.estimate_id = e.id
) cf_secondary_agg ON true

WHERE e.status NOT IN ('DELETED', 'DRAFT');

CREATE UNIQUE INDEX idx_mv_estimates_pk
ON public.mv_estimates(id);

CREATE INDEX idx_mv_estimates_tenant_workspace
ON public.mv_estimates(tenant_id, workspace_id);

CREATE INDEX idx_mv_estimates_estimate_no
ON public.mv_estimates(estimate_no);

CREATE INDEX idx_mv_estimates_encrypted_id
ON public.mv_estimates(encrypted_id);

CREATE INDEX idx_mv_estimates_company
ON public.mv_estimates(company_id);

CREATE INDEX idx_mv_estimates_contact
ON public.mv_estimates(contact_id);

CREATE INDEX idx_mv_estimates_lead
ON public.mv_estimates(lead_id);

CREATE INDEX idx_mv_estimates_status_id
ON public.mv_estimates(status_id);

CREATE INDEX idx_mv_estimates_priority
ON public.mv_estimates(priority_id);

CREATE INDEX idx_mv_estimates_sales_person
ON public.mv_estimates(sales_person_id);
