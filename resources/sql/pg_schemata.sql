-- $1 schema filter
select
    null as "catalog",
    nsp.nspname as "name"
from
    pg_namespace as nsp
where
    nsp.nspname like ?
;
