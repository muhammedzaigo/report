CREATE MATERIALIZED VIEW public.mv_attendances AS
SELECT 
    a.id,

    a.attendance_status,
    a.attendance_type,

    a.user_id,
    u.name AS user_name,

    a.date,
    a.clock_in_time,
    a.clock_out_time,

    a.clock_in_location,
    a.clock_in_latitude,
    a.clock_in_longitude,

    a.clock_out_location,
    a.clock_out_latitude,
    a.clock_out_longitude,

    a.is_auto_clockout,

    -- --------------------
    -- Meta
    -- --------------------
    a.status,
    a.created_at,
    a.updated_at,
    a.created_by,
    a.updated_by,
    a.workspace_id,
    a.tenant_id,
    created_user.name AS created_by_name,
    updated_user.name AS updated_by_name,

    -- --------------------
    -- Custom Fields
    -- --------------------
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields

FROM tracking_schema.attendances a

-- --------------------
-- User joins
-- --------------------
LEFT JOIN user_schema.users u
    ON a.user_id = u.id

LEFT JOIN user_schema.users created_user
    ON a.created_by = created_user.id

LEFT JOIN user_schema.users updated_user
    ON a.updated_by = updated_user.id

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
    FROM public.mv_attendance_custom_fields cf
    WHERE cf.attendance_id = a.id
      AND cf.tenant_id = a.tenant_id
      AND cf.workspace_id = a.workspace_id
) cf_agg ON true

WHERE a.status NOT IN ('deleted', 'draft');
