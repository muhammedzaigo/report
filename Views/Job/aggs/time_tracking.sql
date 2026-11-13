CREATE MATERIALIZED VIEW public.mv_job_time_tracking_agg AS
SELECT 
    jat.job_id,
    COUNT(*) as time_entry_count,
    SUM(jat.hours) as total_hours,
    SUM(jat.minutes) as total_minutes,
    SUM(jat.hours * COALESCE(jat.hourly_rate, 0)) as total_labor_cost,
    jsonb_agg(
        jsonb_build_object(
            'user_id', u.id,
            'user_name', u.name,
            'hours', jat.hours,
            'minutes', jat.minutes,
            'hourly_rate', jat.hourly_rate,
            'description', jat.description,
            'service', tts.service,
            'created_at', jat.created_at
        ) ORDER BY jat.created_at DESC
    ) as time_entries
FROM job_schema.job_add_times jat
LEFT JOIN user_schema.users u ON jat.user_id = u.id
LEFT JOIN job_schema.job_time_tracking_settings tts 
    ON jat.time_tracking_service_id = tts.id 
    AND tts.status = 'active'
WHERE jat.status = 'active'
GROUP BY jat.job_id;
