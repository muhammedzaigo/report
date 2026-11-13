IMPORT FOREIGN SCHEMA public
LIMIT  TO (
    invoice_payments,
    invoice_defaultfield_option,
    payment_methods,
    invoices,
    invoice_secondary_customfield_option, 
    invoice_secondary_customfield_value, 
    invoice_secondary_customfield,
    invoice_terms_and_condition_settings,
    invoice_customfield_option,
    invoice_customfield,
    invoice_customfield_value,
    invoice_summary_customfield_option,
    invoice_summary_customfield_value,
    invoice_summary_customfield,

    estimates,
    estimate_defaultfield_option,
    estimate_terms_and_condition_settings,
    estimate_customfield_option,
    estimate_customfield,
    estimate_customfield_value,
    estimate_summary_customfield_option,
    estimate_summary_customfield,
    estimate_summary_customfield_value,
    estimate_secondary_customfield_option,
    estimate_secondary_customfield,
    estimate_secondary_customfield_value

    inventory_items
    )
FROM SERVER accounting_server
INTO accounting_schema;
