vim-vdbc [![Build Status](https://travis-ci.org/kamichidu/vim-vdbc.svg?branch=master)](https://travis-ci.org/kamichidu/vim-vdbc)
====================================================================================================
database interface for vim.


Installation
----------------------------------------------------------------------------------------------------
```vim:
NeoBundle 'kamichidu/vim-vdbc', {
\   'depends': ['Shougo/vimproc.vim'],
\   'build': {
\       'unix':    'make -f Makefile',
\       'windows': 'make -f Makefile.win64',
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
