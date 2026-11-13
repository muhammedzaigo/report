CREATE MATERIALIZED VIEW public.mv_trips AS
SELECT 
    v.id,

    -- --------------------
    -- Customer Info
    -- --------------------
    v.customer_type,
    v.company_id,
    comp.name AS company_name,
    v.contact_id,
    cont.name AS contact_name,
    v.lead_id,
    l.name AS lead_name,

    -- --------------------
    -- User Info
    -- --------------------
    v.user_id,
    u.name AS user_name,

    -- --------------------
    -- Visit Info
    -- --------------------
    v.job_id,
    v.route_id,
    v.task_id,

    v.trip_purpose,
    v.from_location,
    v.to_location,
    v.remarks,
    
    v.start_date,
    v.start_time,
    v.total_km,
    v.travel_hours,
    v.travel_minutes,
    v.trip_type,
    v.end_date,
    v.end_time,
    v.trip_status,

    -- --------------------
    -- Meta
    -- --------------------
    v.status,
    v.created_at,
    v.updated_at,
    v.created_by,
    v.updated_by,
    v.workspace_id,
    v.tenant_id,
    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,

    -- --------------------
    -- Custom Fields
    -- --------------------
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields

FROM tracking_schema.trips v

-- --------------------
-- Customer joins
-- --------------------
LEFT JOIN job_schema.leads l
    ON v.lead_id = l.id::text
    AND l.status = 'active'

LEFT JOIN user_schema.contacts cont
    ON v.contact_id = cont.id::text

LEFT JOIN user_schema.companies comp
    ON v.company_id = comp.id::text

-- --------------------
-- User joins
-- --------------------
LEFT JOIN user_schema.users u
    ON v.user_id = u.id::text

LEFT JOIN user_schema.users created_user
    ON v.created_by = created_user.id

LEFT JOIN user_schema.users updated_user
    ON v.updated_by = updated_user.id

-- --------------------
-- Custom fields (LATERAL)
-- --------------------
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
            'selected_options', cf.selected_options,
            'searchable_value', cf.searchable_value
        )
        ORDER BY cf.field_name
    ) AS custom_fields
    FROM public.mv_trip_custom_fields cf
    WHERE cf.trip_id = v.id
      AND cf.tenant_id = v.tenant_id
      AND cf.workspace_id = v.workspace_id
) cf_agg ON true

WHERE v.status NOT IN ('deleted', 'draft');
