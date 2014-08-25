set runtimepath+=./.vim-test/*
filetype plugin indent on

describe 'The Introspection API'
    function! s:test_for_postgres()
        Expect g:C.catalogs() ==# []

        Expect g:C.schemata({'schema': 'public'}) ==# [
        \   {'catalog': '', 'name': 'public'},
        \]

        Expect g:C.tables({'schema': 'public'}) ==# [
        \   {'catalog': '', 'schema': 'public', 'name': 'mr_test', 'type': 'table', 'remarks': ''},
        \]

        Expect g:C.columns({'schema': 'public'}) ==# [
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'tableoid', 'type_name': 'oid',     'ordinal_position': '-7', 'nullable': 'f', 'remarks': ''},
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'cmax',     'type_name': 'cid',     'ordinal_position': '-6', 'nullable': 'f', 'remarks': ''},
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'xmax',     'type_name': 'xid',     'ordinal_position': '-5', 'nullable': 'f', 'remarks': ''},
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'cmin',     'type_name': 'cid',     'ordinal_position': '-4', 'nullable': 'f', 'remarks': ''},
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'xmin',     'type_name': 'xid',     'ordinal_position': '-3', 'nullable': 'f', 'remarks': ''},
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'ctid',     'type_name': 'tid',     'ordinal_position': '-1', 'nullable': 'f', 'remarks': ''},
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'id',       'type_name': 'int4',    'ordinal_position': '1',  'nullable': 't', 'remarks': ''},
        \   {'catalog': '', 'schema': 'public', 'table': 'mr_test', 'name': 'str',      'type_name': 'varchar', 'ordinal_position': '2',  'nullable': 't', 'remarks': ''},
        \]
    endfunction

    function! s:test_for_sqlite3()
        Expect g:C.catalogs() ==# []
        Expect g:C.schemata() ==# []

        Expect g:C.tables() ==# [
        \   {'catalog': '', 'schema': '', 'name': 'mr_test', 'type': 'table', 'remarks': ''},
        \]
        Expect g:C.tables({'table': '%test'}) ==# [
        \   {'catalog': '', 'schema': '', 'name': 'mr_test', 'type': 'table', 'remarks': ''},
        \]

        Expect g:C.columns() ==# [
        \   {'catalog': '', 'schema': '', 'table': 'mr_test', 'name': 'id',  'type_name': 'integer', 'ordinal_position': '0', 'nullable': 't', 'remarks': ''},
        \   {'catalog': '', 'schema': '', 'table': 'mr_test', 'name': 'str', 'type_name': 'varchar', 'ordinal_position': '1', 'nullable': 't', 'remarks': ''},
        \]
        Expect g:C.columns({'column': '%t%'}) ==# [
        \   {'catalog': '', 'schema': '', 'table': 'mr_test', 'name': 'str', 'type_name': 'varchar', 'ordinal_position': '1', 'nullable': 't', 'remarks': ''},
        \]
    endfunction

    describe 'vdbc.driver.pg'
        before
            let g:C= vdbc#connect({
            \   'driver':   'pg',
            \   'dbname':   'test_vdbc',
            \   'username': 'postgres',
            \})
        end

        after
            call g:C.disconnect()
        end

        it 'is okay to use it'
            call s:test_for_postgres()
        end
    end

    describe 'vdbc.driver.pg_libpq'
        before
            let g:C= vdbc#connect({
            \   'driver':   'pg_libpq',
            \   'dbname':   'test_vdbc',
            \   'username': 'postgres',
            \})
        end

        after
            call g:C.disconnect()
        end

        it 'is okay to use it'
            call s:test_for_postgres()
        end
    end

    describe 'vdbc.driver.sqlite3'
        before
            let g:C= vdbc#connect({
            \   'driver':   'sqlite3',
            \   'dbname':   './test_vdbc.db',
            \})
        end

        after
            call g:C.disconnect()
        end

        it 'is okay to use it'
            call s:test_for_sqlite3()
        end
    end

    describe 'vdbc.driver.sqlite3_libsqlite3'
        before
            let g:C= vdbc#connect({
            \   'driver':   'sqlite3_libsqlite3',
            \   'dbname':   './test_vdbc.db',
            \})
        end

        after
            call g:C.disconnect()
        end

        it 'is okay to use it'
            call s:test_for_sqlite3()
        end
    end
end
