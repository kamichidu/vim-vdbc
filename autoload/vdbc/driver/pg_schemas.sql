select
    null as "catalog",
    nsp.nspname as "name"
from
    pg_namespace as nsp
;
