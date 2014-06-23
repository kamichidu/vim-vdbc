select
    table_catalog    as "catalog",
    table_schema     as "schema",
    table_name       as "table",
    column_name      as "name",
    data_type        as "type_name",
    ordinal_position as "ordinal_position",
    (
        case is_nullable
            when 'YES' then true
            else            false
        end     
    ) as "nullable",
    null             as "remarks"
from
    information_schema.columns
where
    table_catalog like ? and
    table_schema  like ? and
    table_name    like ? and
    column_name   like ?
order by
    "catalog",
    "schema",
    "table",
    "ordinal_position"
;
