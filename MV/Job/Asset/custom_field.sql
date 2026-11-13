CREATE MATERIALIZED VIEW public.mv_asset_custom_fields AS
SELECT 
    ccfv.entity_id as asset_id,
    c.workspace_id,
    c.tenant_id,
    ccf.id as customfield_id,
    ccf.label as field_name,
    ccf.field_type,
    ccf.label as field_label,
    ccf.required,
    
    -- All value types (only one will be populated based on field_type)
    ccfv.id,
    ccfv.value,
    ccfv.value_json,
    ccfv.value_date,
    ccfv.value_time,
    ccfv.editor,
    
    -- Selected option values for choice types (single_dropdown, multiple_dropdown, radio, checkbox, tag)
    CASE 
        WHEN ccf.field_type IN ('single_dropdown', 'multiple_dropdown', 'radio', 'checkbox', 'tag') 
        THEN (
            SELECT COALESCE(
                array_agg(ccfo.option ORDER BY ccfo.option),
                ARRAY[]::text[]
            )
            FROM job_schema.asset_customfield_option ccfo
            WHERE ccfo.customfield_id = ccf.id
                AND ccfo.id = ANY(
                    SELECT jsonb_array_elements_text(ccfv.value_json::jsonb)::uuid
                )
                AND ccfo.status = 'active'
        )
        ELSE ARRAY[]::text[]
    END as selected_options,
    
    -- Create a unified searchable column including option values
    COALESCE(
        ccfv.value,
        CASE 
            WHEN ccf.field_type IN ('single_dropdown', 'multiple_dropdown', 'radio', 'checkbox', 'tag') 
            THEN (
                SELECT string_agg(ccfo.option, ', ')
                FROM job_schema.asset_customfield_option ccfo
                WHERE ccfo.customfield_id = ccf.id
                    AND ccfo.id = ANY(
                        SELECT jsonb_array_elements_text(ccfv.value_json::jsonb)::uuid
                    )
                    AND ccfo.status = 'active'
            )
            ELSE ccfv.value_json::text
        END,
        ccfv.value_date::text,
        ccfv.value_time::text,
        ''
    ) as searchable_value,
    
    -- Metadata
    ccfv.created_at,
    ccfv.updated_at
    
FROM job_schema.asset_customfield_value ccfv
INNER JOIN job_schema.asset_customfield ccf 
    ON ccfv.customfield_id = ccf.id
    AND ccf.status = 'active'
INNER JOIN job_schema.assets c
    ON ccfv.entity_id = c.id
    AND c.status NOT IN ('deleted', 'draft')
WHERE ccfv.status = 'active';


CREATE INDEX idx_mv_asset_cf_asset_id
ON public.mv_asset_custom_fields(asset_id);

CREATE INDEX idx_mv_asset_cf_customfield_id
ON public.mv_asset_custom_fields(customfield_id);

CREATE INDEX idx_mv_asset_cf_tenant_workspace
ON public.mv_asset_custom_fields(tenant_id, workspace_id);

CREATE INDEX idx_mv_asset_cf_field_name
ON public.mv_asset_custom_fields(field_name);

CREATE INDEX idx_mv_asset_cf_field_type
ON public.mv_asset_custom_fields(field_type);

CREATE INDEX idx_mv_asset_cf_value
ON public.mv_asset_custom_fields(value);

CREATE INDEX idx_mv_asset_cf_value_date
ON public.mv_asset_custom_fields(value_date);

CREATE INDEX idx_mv_asset_cf_searchable_gin
ON public.mv_asset_custom_fields
USING gin (to_tsvector('simple', searchable_value));

CREATE INDEX idx_mv_asset_cf_selected_options_gin
ON public.mv_asset_custom_fields
USING gin (selected_options);

CREATE INDEX idx_mv_asset_cf_asset_field
ON public.mv_asset_custom_fields(asset_id, field_name);

CREATE INDEX idx_mv_asset_cf_workspace_field_value
ON public.mv_asset_custom_fields(workspace_id, field_name, value);

CREATE UNIQUE INDEX idx_mv_asset_cf_unique
ON public.mv_asset_custom_fields(asset_id, customfield_id);
