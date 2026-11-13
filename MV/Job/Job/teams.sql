CREATE MATERIALIZED  VIEW public.mv_job_teams_agg AS
SELECT 
    jat.job_id,
    string_agg(t.name, ', ' ORDER BY t.name) as team_names,
    array_agg(t.id::text) AS assigned_teams_ids,
    jsonb_agg(
        jsonb_build_object(
            'team_id', t.id,
            'team_name', t.name
        ) ORDER BY t.name
    ) as assigned_teams
FROM job_schema.job_assigned_teams jat
INNER JOIN user_schema.teams t ON jat.team_id = t.id
WHERE jat.status = 'active'
GROUP BY jat.job_id;