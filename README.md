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
\       'windows': 'make -f Makefile.win64 pg_libpq',
\   },
\}
```


How to Use
----------------------------------------------------------------------------------------------------
```vim:
" driver is one of {'pg', 'pg_libpq', 'sqlite3', 'sqlite3_libsqlite3'}
let conn= vdbc#connect({
\   'driver':   'sqlite3_libsqlite3',
\   'dbname':   ':memory:',
\})

echo conn.select_as_list('select * from table')

call conn.disconnect()
```
