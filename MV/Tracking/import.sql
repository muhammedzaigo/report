IMPORT FOREIGN SCHEMA public
LIMIT  TO (
    visit_customfield_value,
    visit_customfield,
    visit_customfield_option,
    visits,
    trip_customfield_value,
    trip_customfield,
    trip_customfield_option,
    trips,
    
    attendance_customfield_value,
    attendance_customfield,
    attendance_customfield_option,
    attendances
)
FROM SERVER tracking_server
INTO tracking_schema;
