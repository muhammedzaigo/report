CREATE MATERIALIZED VIEW public.mv_invoice_payments_agg AS
SELECT 
    inv.invoice_id,
    string_agg(pm.name, ', ' ORDER BY pm.name) as payment_method_names,
    string_agg(pm.payment_category, ', ' ORDER BY pm.payment_category) as payment_method_payment_categorys,
    array_agg(
	    pm.id::text
	) AS payment_method_ids,

    jsonb_agg(
        DISTINCT jsonb_build_object(
            'payment_method_id', inv.payment_method_id,
            'payment_type', inv.payment_type,
            'paid_date', inv.paid_date,
            'paid_amount', inv.paid_amount,
            'reference', inv.reference,
            'payment_category',pm.payment_category,
            'name',pm.name
        )
    ) as invoice_payments
    
FROM accounting_schema.invoice_payments inv
LEFT JOIN accounting_schema.payment_methods pm 
    ON inv.payment_method_id = pm.id 
    AND pm.status = 'active'
WHERE inv.status = 'active'
GROUP BY inv.invoice_id;
