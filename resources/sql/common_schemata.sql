select
    catalog_name as "catalog",
    schema_name  as "schema"
from
    information_schema.schemata
where
    catalog_name like ? and
    schema_name  like ?
order by
    "catalog",
    "schema"
;
