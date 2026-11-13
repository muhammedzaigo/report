CREATE MATERIALIZED VIEW public.mv_companies AS
SELECT 
    c.id,
    c.company_id,
    c.lead_id,
    c.name,
    c.email,
    c.tax_number,
    c.website,
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
        array_agg(cl.id::text) FILTER (WHERE cl.id IS NOT NULL),
        ARRAY[]::text[]
    ) AS locations_ids,
    COALESCE(
        jsonb_agg(DISTINCT jsonb_build_object(
            'id', cl.id,
            'name', cl.name
        )) FILTER (WHERE cl.id IS NOT NULL),
        '[]'::jsonb
    ) AS locations,

    COALESCE(
        array_agg(DISTINCT conts.id::text) FILTER (WHERE conts.id IS NOT NULL),
        ARRAY[]::text[]
    ) AS conts_ids,
    string_agg(
        DISTINCT conts.name,
        ', '
        ORDER BY conts.name
    ) AS contact_names,
    COALESCE(
        jsonb_agg(DISTINCT jsonb_build_object(
            'id', conts.id,
            'name', conts.name
        )) FILTER (WHERE conts.id IS NOT NULL),
        '[]'::jsonb
    ) AS contacts,

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
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields

FROM user_schema.companies c
LEFT JOIN user_schema.company_phone_no cp 
    ON c.id = cp.company_id AND cp.status = 'active'
LEFT JOIN user_schema.company_tags ct 
    ON c.id = ct.company_id AND ct.status = 'active'
LEFT JOIN user_schema.company_locations cl 
    ON c.id = cl.company_id AND cl.status = 'active'
LEFT JOIN user_schema.contacts conts
    ON c.id = conts.company_id AND conts.status = 'active'
LEFT JOIN user_schema.company_associate_users cau 
    ON c.id = cau.company_id AND cau.status = 'active'
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
    FROM public.mv_company_custom_fields cf
    WHERE cf.company_id = c.id
        AND cf.tenant_id = c.tenant_id
        AND cf.workspace_id = c.workspace_id
) cf_agg ON true

WHERE c.status NOT IN ('deleted', 'draft')
GROUP BY
    c.id,
    c.company_id,
    c.lead_id,
    c.name,
    c.email,
    c.tax_number,
    c.website,
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
    created_user.name,
    updated_user.name,
	cf_agg.custom_fields;
