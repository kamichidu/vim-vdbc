set runtimepath+=./.vim-test/*
filetype plugin indent on

describe ''
describe '{pg} driver can give information for meta data'
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

    it 'can NOT get catalog information by catalogs()'
        Expect expr { g:C.catalogs() } to_throw 'not supported'
    end

    it 'can get schema information by schemata()'
        Expect g:C.schemata({'schema': 'public'}) ==# [
        \   {'catalog': '', 'name': 'public'},
        \]
    end

    it 'can get table or view information by tables()'
        Expect g:C.tables({'schema': 'public'}) ==# [
        \   {'catalog': '', 'schema': 'public', 'name': 'mr_test', 'type': 'table', 'remarks': ''},
        \]
    end

    it 'can get column information by columns()'
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
    end
end
