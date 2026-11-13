CREATE MATERIALIZED VIEW public.mv_invoices AS
SELECT
    inv.id,
    inv.encrypted_id,

    inv.customer_type,
    inv.company_id,
    comp.name AS company_name,
    inv.contact_id,
    cont.name AS contact_name,

    inv.job_id,
    inv.location_id,
    loc.name AS primary_location_name,

    inv.status_id,
    stat.option AS status_name,

    inv.invoice_owner_id,
    invoice_owner.name AS invoice_owner_name,

    inv.shipping_location,
    inv.billing_location,
    inv.invoice_no,
    inv.due_date,
    inv.created_date,
    inv.reference,
    inv.total,
    inv.paid_amount,
    inv.due_amount,
    inv.title,

    inv.terms_and_condition_setting_id,
    term.name AS terms_and_condition_name,

    inv.priority_id,
    pr.option AS priority_name,

    inv.tenant_id,
    inv.workspace_id,
    inv.created_by,
    inv.updated_by,
    inv.updated_at,
    inv.created_at,
    inv.status,

    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,

    payments.payment_method_names,
    payments.payment_method_payment_categorys,
    payments.payment_method_ids,
    payments.invoice_payments,

    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields,
    COALESCE(cf_summary_agg.summary_custom_fields, '[]'::jsonb) AS summary_custom_fields,
    COALESCE(cf_secondary_agg.secondary_custom_fields, '[]'::jsonb) AS secondary_custom_fields

FROM accounting_schema.invoices inv

LEFT JOIN accounting_schema.invoice_defaultfield_option stat
    ON stat.id = inv.status_id AND stat.status = 'active'

LEFT JOIN accounting_schema.invoice_defaultfield_option pr
    ON pr.id = inv.priority_id AND pr.status = 'active'

LEFT JOIN accounting_schema.invoice_terms_and_condition_settings term
    ON term.id = inv.terms_and_condition_setting_id AND term.status = 'active'

LEFT JOIN user_schema.companies comp ON inv.company_id = comp.id::text
LEFT JOIN user_schema.contacts cont ON inv.contact_id = cont.id::text
LEFT JOIN user_schema.locations loc ON inv.location_id = loc.id::text

LEFT JOIN user_schema.users created_user ON inv.created_by = created_user.id
LEFT JOIN user_schema.users updated_user ON inv.updated_by = updated_user.id
LEFT JOIN user_schema.users invoice_owner ON inv.invoice_owner_id = invoice_owner.id::text
LEFT JOIN public.mv_invoice_payments_agg payments ON payments.invoice_id = inv.id

LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(cf.*)) AS custom_fields
    FROM public.mv_invoice_custom_fields cf
    WHERE cf.invoice_id = inv.id
) cf_agg ON true

LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(cfs.*)) AS summary_custom_fields
    FROM public.mv_invoice_summary_custom_fields cfs
    WHERE cfs.invoice_id = inv.id
) cf_summary_agg ON true

LEFT JOIN LATERAL (
    SELECT jsonb_agg(row_to_json(cfs.*)) AS secondary_custom_fields
    FROM public.mv_invoice_secondary_custom_fields cfs
    WHERE cfs.invoice_id = inv.id
) cf_secondary_agg ON true

WHERE inv.status NOT IN ('DELETED', 'DRAFT');

CREATE UNIQUE INDEX idx_mv_invoices_pk
ON public.mv_invoices(id);

CREATE INDEX idx_mv_invoices_tenant_workspace
ON public.mv_invoices(tenant_id, workspace_id);

CREATE INDEX idx_mv_invoices_invoice_no
ON public.mv_invoices(invoice_no);

CREATE INDEX idx_mv_invoices_encrypted_id
ON public.mv_invoices(encrypted_id);

CREATE INDEX idx_mv_invoices_company
ON public.mv_invoices(company_id);

CREATE INDEX idx_mv_invoices_contact
ON public.mv_invoices(contact_id);

CREATE INDEX idx_mv_invoices_status_id
ON public.mv_invoices(status_id);

CREATE INDEX idx_mv_invoices_priority
ON public.mv_invoices(priority_id);

CREATE INDEX idx_mv_invoices_sales_person
ON public.mv_invoices(invoice_owner_id);
