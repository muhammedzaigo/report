IMPORT FOREIGN SCHEMA public
LIMIT TO (
    task_customfield_option,
    task_customfield_value,
    task_customfield,

    jobs,

    assign_checklists,
    checklist_settings,

    leads,
    lead_defaultfield_option,
    lead_settings_status,
    lead_tags,
    lead_customfield_option,
    lead_customfield_value,
    lead_customfield,

    job_add_on_customfield_option,
    job_add_on_customfield_value,
    job_add_on_customfield,
    task_defaultfield_option,
    assets,
    job_amc_or_assets,

    job_add_costs,
    job_cost_tracking_settings,

    job_customfield_option,
    job_customfield_value,
    job_customfield,

    job_assigned_teams,
    job_assigned_technicians,

    job_time_tracking_settings,
    job_add_times,

    job_defaultfield_option,

    amcs,
    job_tags,

    asset_defaultfield_option,
    asset_customfield_option,
    asset_customfield_value,
    asset_customfield,

    amc_customfield_option,
    amc_customfield_value,
    amc_customfield
)
FROM SERVER job_server
INTO job_schema;
