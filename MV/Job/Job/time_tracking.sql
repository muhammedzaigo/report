CREATE MATERIALIZED VIEW public.mv_job_time_tracking_agg AS
SELECT 
    jat.job_id,
    jsonb_agg(
        DISTINCT jsonb_build_object(
            'hours', jat.hours,
            'minutes', jat.minutes
        )
    ) as job_add_times
    
FROM job_schema.job_add_times jat
LEFT JOIN job_schema.job_time_tracking_settings tts 
    ON jat.time_tracking_service_id = tts.id 
    AND tts.status = 'active'
WHERE jat.status = 'active'
GROUP BY jat.job_id;
