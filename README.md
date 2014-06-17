vim-vdbc
====================================================================================================
database interface for vim.


Installation
----------------------------------------------------------------------------------------------------
```vim:
NeoBundle 'kamichidu/vim-vdbc', {
\   'depends': ['Shougo/vimproc.vim'],
\   'build': {
\       'unix':    'make -f Makefile',
\       'windows': 'make -f Makefile.w64',
\   },
\}
```


How to Use
----------------------------------------------------------------------------------------------------
```vim:
let conn= vdbc#connect({
\   'driver':   'pg_libpq',
\   'host':     'localhost',
\   'port':     5432,
\   'username': 'hogehoge',
\   'password': 'password',
\   'dbname':   'dbname',
\})

echo conn.select_as_list('select * from table')

call conn.disconnect()
```
