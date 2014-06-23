select
    table_catalog as "catalog",
    table_schema  as "schema",
    table_name    as "name",
    (
        case table_type
            when 'BASE TABLE' then 'table'
            when 'VIEW'       then 'view'
            else                   ''
        end
    ) as "type"
from
    information_schema.tables
where
    table_catalog like ? and
    table_schema  like ? and
    table_name    like ?
order by
    "catalog",
    "schema",
    "type",
    "name"
;
