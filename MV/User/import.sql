IMPORT FOREIGN SCHEMA public
LIMIT TO (
    users,
    companies,
    company_phone_no,
    company_tags,
    company_locations,
    company_associate_users,

    contacts,
    contact_phone_no,
    contact_tags,
    contact_locations,
    contact_associate_users,

    company_customfield,
    company_customfield_value,
    company_customfield_option,

    contact_customfield,
    contact_customfield_value,
    contact_customfield_option,

    user_workspace_association,
    user_location_association,
    user_team_association,
    user_tags,

    locations,
    teams,
    account_types,
    workspaces,

    user_customfield,
    user_customfield_value,
    user_customfield_option
)
FROM SERVER user_server
INTO user_schema;
