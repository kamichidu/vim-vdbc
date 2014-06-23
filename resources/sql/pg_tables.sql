-- $1 schema
-- $2 table
-- $3 relkind (posix regex)
select
    null as "catalog",
    nsp.nspname as "schema",
    cls.relname as "name",
    (
        case cls.relkind
            when 'r' then 'table'
            when 'v' then 'view'
            else          ''
        end
    ) as "type",
    rem.description as "remarks"
from
    pg_class as cls
    inner join
        pg_namespace as nsp
    on
        cls.relnamespace = nsp.oid
    left join
        pg_description as rem
    on
        cls.oid = rem.objoid and
        rem.objsubid = 0
where
    nsp.nspname like ? and
    cls.relname like ? and
    cls.relkind ~ ?
order by
    "schema",
    "type",
    "name"
;
