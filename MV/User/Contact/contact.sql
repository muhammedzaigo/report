CREATE MATERIALIZED VIEW public.mv_contacts AS
SELECT 
    c.id,
    c.contact_id,
    c.name,
    c.email,
    c.tax_number,
    c.status,
    c.opening_balance,
    c.credit,
    c.debit,    

    c.created_at,
    c.updated_at,
    c.created_by,
    c.updated_by,
    c.workspace_id,
    c.tenant_id,
    c.company_id,
    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,
    
    -- Phone numbers
    COALESCE(
        array_agg(DISTINCT
            CASE
                WHEN cp.country_code IS NOT NULL AND cp.country_code <> ''
                THEN cp.country_code || ' ' || COALESCE(cp.phone_number, '')
                ELSE cp.phone_number
            END
        ) FILTER (WHERE cp.id IS NOT NULL AND cp.phone_number IS NOT NULL),
        ARRAY[]::text[]
    ) AS phone_no,
    
    -- Tags
    COALESCE(
        array_agg(DISTINCT ct.tag ORDER BY ct.tag)
        FILTER (WHERE ct.tag IS NOT NULL),
        ARRAY[]::text[]
    ) AS tags,
    
    -- Locations
    COALESCE(
        array_agg(DISTINCT cl.id::text) FILTER (WHERE cl.id IS NOT NULL),
        ARRAY[]::text[]
    ) AS locations_ids,
    COALESCE(
        jsonb_agg(DISTINCT jsonb_build_object(
            'id', cl.id,
            'name', cl.name
        )) FILTER (WHERE cl.id IS NOT NULL),
        '[]'::jsonb
    ) AS locations,
    
    -- Associate Users
    COALESCE(
        array_agg(DISTINCT cau_user.id::text) FILTER (WHERE cau_user.id IS NOT NULL),
        ARRAY[]::text[]
    ) AS associate_user_ids,
    string_agg(
        DISTINCT cau_user.name,
        ', '
        ORDER BY cau_user.name
    ) AS associate_user_names,
    COALESCE(
        jsonb_agg(DISTINCT jsonb_build_object(
            'id', cau_user.id,
            'name', cau_user.name
        )) FILTER (WHERE cau_user.id IS NOT NULL),
        '[]'::jsonb
    ) AS associate_users,
    
    -- Custom Fields from lateral join
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields,
    COALESCE(cc_agg.custom_fields, '[]'::jsonb) AS company_custom_fields
    
FROM user_schema.contacts c
LEFT JOIN user_schema.contact_phone_no cp 
    ON c.id = cp.contact_id AND cp.status = 'active'
LEFT JOIN user_schema.contact_tags ct 
    ON c.id = ct.contact_id AND ct.status = 'active'
LEFT JOIN user_schema.contact_locations cl 
    ON c.id = cl.contact_id AND cl.status = 'active'
LEFT JOIN user_schema.contact_associate_users cau 
    ON c.id = cau.contact_id AND cau.status = 'active'
LEFT JOIN user_schema.users cau_user 
    ON cau.user_id = cau_user.id
LEFT JOIN user_schema.users created_user 
    ON c.created_by = created_user.id
LEFT JOIN user_schema.users updated_user 
    ON c.updated_by = updated_user.id
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
    FROM public.mv_contact_custom_fields cf
    WHERE cf.contact_id = c.id
        AND cf.tenant_id = c.tenant_id
        AND cf.workspace_id = c.workspace_id
) cf_agg ON true
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
    FROM public.mv_company_contact_custom_fields cf
    WHERE cf.contact_id = c.id
        AND cf.tenant_id = c.tenant_id
        AND cf.workspace_id = c.workspace_id
) cc_agg ON true

WHERE c.status NOT IN ('deleted', 'draft')

GROUP BY 
    c.id, c.contact_id, c.name, c.email, c.tax_number, c.status,
    c.created_at, c.updated_at, c.created_by, c.updated_by,
    c.workspace_id, c.tenant_id, c.company_id,
    created_user.name, updated_user.name,
    c.opening_balance,
    c.credit,
    c.debit,   
    cf_agg.custom_fields,
    cc_agg.custom_fields;