vim-vdbc [![Build Status](https://travis-ci.org/kamichidu/vim-vdbc.svg?branch=master)](https://travis-ci.org/kamichidu/vim-vdbc)
====================================================================================================
The generic database interface for vim.

This plug-in intended to give some generic API to vim plug-in developers, and high-speed database
accessing (via vim's libcall feature).

Implemented features:

1. transaction support
1. prepared statement support
1. introspection support (depends on a driver)


Installation
----------------------------------------------------------------------------------------------------
You can choose a driver you want to use it.
Available drivers are:

1. pg
1. pg\_libpq
1. sqlite3
1. sqlite3\_libsqlite3

After choosing your favourite driver, you can write following settings to `$MYVIMRC`.

1. pg

    ```vim:
    NeoBundle 'kamichidu/vim-vdbc', {
    \   'depends': ['Shougo/vimproc.vim'],
    \   'external_commands': 'psql',
    \}
    ```

1. pg\_libpq

    ```vim:
    NeoBundle 'kamichidu/vim-vdbc', {
    \   'build': {
    \       'unix':    'make -f Makefile pg_libpq',
    \       'windows': 'make -f Makefile.win64 pg_libpq',
    \   },
    \}
    ```

1. sqlite3

    ```vim:
    NeoBundle 'kamichidu/vim-vdbc', {
    \   'depends': ['Shougo/vimproc.vim'],
    \   'external_commands': 'sqlite3',
    \}
    ```

1. sqlite3\_libsqlite3

    On this driver, we bundled sqlite3 sources and dynamic library for windows
    64-bit. If you use windows 64-bit, you can use sqlite3\_libsqlite3 driver without compiling it.

    ```vim:
    NeoBundle 'kamichidu/vim-vdbc', {
    \   'build': {
    \       'unix': 'make -f Makefile sqlite3_libsqlite3',
    \   },
    \}
    ```


How to Use
----------------------------------------------------------------------------------------------------
Basic usage is below:
```vim
" driver is one of {'pg', 'pg_libpq', 'sqlite3', 'sqlite3_libsqlite3'}
try
    let conn= vdbc#connect_by_dsn('vdbc:sqlite3*:dbname=:memory:')

    call conn.execute('create table a_table (column1 integer, column2 varchar)')
    " => [[1, 'hoge'], [2, 'fuga'], ...]
    echo conn.select_as_list('select * from a_table where column2 = ?', ['param'])
    " => [{'column1': 1, 'column2': 'hoge'}, {'column1': 2, 'column2': 'fuga'}, ...]
    echo conn.select_as_dict('select * from a_table where column2 = ?', ['param'])
finally
    if exists('conn')
        call conn.disconnect()
    endif
endtry
```

See `:help vdbc-contents` for more details.
