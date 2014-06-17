select
    null as "catalog",
    nsp.nspname as "schema",
    cls.relname as "name",
    'table' as "type",
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
    cls.relkind = 'r' and
    nsp.nspname = 'public'
;
