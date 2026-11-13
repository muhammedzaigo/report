CREATE MATERIALIZED VIEW public.mv_users AS
SELECT
    u.id,
    u.name,
    u.email,
    u.user_name,
    u.country_code,
    u.phone_number,
    u.image,
    u.designation,
    u.is_account_owner,
    u.user_type,
    u.sales_target,
    u.service_target,

    u.account_type_id,
    at.name AS account_type_name,

    u.status,
    u.created_at,
    u.updated_at,
    u.created_by,
    u.updated_by,
    u.tenant_id,
    u.reporting_manager_id,

    cu.name AS created_by_name,
    uu.name AS updated_by_name,
    rmu.name AS reporting_manager_name,

    /* -------- Workspaces -------- */
    COALESCE(
        array_agg(DISTINCT w.id::text)
        FILTER (WHERE w.id IS NOT NULL),
        ARRAY[]::text[]
    ) AS workspace_ids,

	string_agg(
        DISTINCT w.name,
        ', '
        ORDER BY w.name
    ) AS workspace_names,

    /* -------- Tags -------- */
    COALESCE(
        array_agg(DISTINCT ut.tag ORDER BY ut.tag)
        FILTER (WHERE ut.tag IS NOT NULL),
        ARRAY[]::text[]
    ) AS tags,

    /* -------- Locations -------- */
    COALESCE(
        array_agg(DISTINCT l.id::text)
        FILTER (WHERE l.id IS NOT NULL),
        ARRAY[]::text[]
    ) AS location_ids,


	string_agg(
        DISTINCT l.name,
        ', '
        ORDER BY l.name
    ) AS location_names,

    MAX(CASE WHEN ula.is_primary THEN l.id::text END) AS primary_location_id,
    MAX(CASE WHEN ula.is_primary THEN l.name END) AS primary_location_name,

    /* -------- Teams -------- */
    COALESCE(
        array_agg(DISTINCT t.id::text)
        FILTER (WHERE t.id IS NOT NULL),
        ARRAY[]::text[]
    ) AS team_ids,

	string_agg(
        DISTINCT t.name,
        ', '
        ORDER BY t.name
    ) AS team_names,
	
    COALESCE(
        jsonb_agg(
            DISTINCT jsonb_build_object(
                'team_id', t.id,
                'team_name', t.name,
                'workspace_id', uta.workspace_id,
                'account_type', uta.account_type
            )
        ) FILTER (WHERE t.id IS NOT NULL),
        '[]'::jsonb
    ) AS teams,

    /* -------- Custom Fields -------- */
    COALESCE(cf_agg.custom_fields, '[]'::jsonb) AS custom_fields

FROM user_schema.users u

/* ---------- Workspace ---------- */
LEFT JOIN user_schema.user_workspace_association uwa
    ON uwa.user_id = u.id

LEFT JOIN user_schema.workspaces w
    ON w.id = uwa.workspace_id

/* ---------- Tags ---------- */
LEFT JOIN user_schema.user_tags ut
    ON ut.user_id = u.id
   AND ut.status = 'active'

/* ---------- Locations ---------- */
LEFT JOIN user_schema.user_location_association ula
    ON ula.user_id = u.id
   AND ula.workspace_id = uwa.workspace_id

LEFT JOIN user_schema.locations l
    ON l.id = ula.location_id
   AND l.status = 'ACTIVE'

/* ---------- Teams ---------- */
LEFT JOIN user_schema.user_team_association uta
    ON uta.user_id = u.id
   AND uta.workspace_id = uwa.workspace_id

LEFT JOIN user_schema.teams t
    ON t.id = uta.team_id
   AND t.status = 'ACTIVE'

/* ---------- Metadata ---------- */
LEFT JOIN user_schema.users cu ON cu.id = u.created_by
LEFT JOIN user_schema.users uu ON uu.id = u.updated_by
LEFT JOIN user_schema.users rmu ON rmu.id = u.reporting_manager_id
LEFT JOIN user_schema.account_types at ON at.id = u.account_type_id

/* ---------- Custom Fields ---------- */
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
    FROM public.mv_user_custom_fields cf
    WHERE cf.user_id = u.id
      AND cf.tenant_id = u.tenant_id
) cf_agg ON true

WHERE u.status NOT IN ('deleted', 'draft')

GROUP BY
    u.id,
    u.name,
    u.email,
    u.user_name,
    u.country_code,
    u.phone_number,
    u.image,
    u.designation,
    u.is_account_owner,
    u.user_type,
    u.sales_target,
    u.service_target,
    u.reporting_manager_id,
    u.account_type_id,
    at.name,
    u.status,
    u.created_at,
    u.updated_at,
    u.created_by,
    u.updated_by,
    u.tenant_id,
    cu.name,
    uu.name,
    rmu.name,
    cf_agg.custom_fields;

