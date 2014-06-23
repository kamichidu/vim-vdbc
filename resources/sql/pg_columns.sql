-- $1 schema
-- $2 table
-- $3 column
select
    null                 as "catalog",
    nsp.nspname          as "schema",
    cls.relname          as "table",
    att.attname          as "name",
    typ.typname          as "type_name",
    att.attnum           as "ordinal_position",
    (not att.attnotnull) as "nullable",
    rem.description      as "remarks"
from
    pg_class as cls
    inner join pg_namespace as nsp on (
        nsp.oid = cls.relnamespace
    )
    inner join pg_attribute as att on (
        att.attrelid = cls.oid
    )
    inner join pg_type as typ on (
        typ.oid = att.atttypid
    )
    left join pg_description as rem on (
        rem.objoid = cls.oid and
        rem.objsubid = att.attnum
    )
where
    nsp.nspname like ? and
    cls.relname like ? and
    att.attname like ?
order by
    "catalog",
    "schema",
    "table",
    "ordinal_position"
;
