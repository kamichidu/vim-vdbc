set runtimepath+=./.vim-test/*
filetype plugin indent on

describe 'select, insert, update, delete statement'
    before
    end

    after
    end

    it 'basic usecase'
        let connect_infos= [
        \   {'driver': 'pg',                 'dbname': 'test_vdbc', 'username': 'postgres'},
        \   {'driver': 'pg_libpq',           'dbname': 'test_vdbc', 'username': 'postgres'},
        \   {'driver': 'sqlite3',            'dbname': './test_vdbc'},
        \   {'driver': 'sqlite3_libsqlite3', 'dbname': './test_vdbc'},
        \]

        for connect_info in connect_infos
            try
                let C= vdbc#connect(connect_info)

                " mr_test (id integer, str varchar)
                call C.execute('delete from mr_test')

                Expect C.select_as_list('select * from mr_test order by id') == []
                Expect C.select_as_dict('select * from mr_test order by id') == []

                try
                    let insert_stmt= C.prepare('insert into mr_test (id, str) values (?, ?)')

                    for i in range(1, 5)
                        call insert_stmt.execute([i, printf('hoge_%d', i)])
                    endfor
                finally
                    if exists('insert_stmt')
                        call insert_stmt.finish()
                    endif
                endtry

                Expect C.select_as_list('select * from mr_test order by id') == [
                \   ['1', 'hoge_1'],
                \   ['2', 'hoge_2'],
                \   ['3', 'hoge_3'],
                \   ['4', 'hoge_4'],
                \   ['5', 'hoge_5'],
                \]
                Expect C.select_as_dict('select * from mr_test order by id') == [
                \   {'id': '1', 'str': 'hoge_1'},
                \   {'id': '2', 'str': 'hoge_2'},
                \   {'id': '3', 'str': 'hoge_3'},
                \   {'id': '4', 'str': 'hoge_4'},
                \   {'id': '5', 'str': 'hoge_5'},
                \]

                call C.execute("update mr_test set str='piyo!'")

                Expect C.select_as_list('select * from mr_test order by id') == [
                \   ['1', 'piyo!'],
                \   ['2', 'piyo!'],
                \   ['3', 'piyo!'],
                \   ['4', 'piyo!'],
                \   ['5', 'piyo!'],
                \]
                Expect C.select_as_dict('select * from mr_test order by id') == [
                \   {'id': '1', 'str': 'piyo!'},
                \   {'id': '2', 'str': 'piyo!'},
                \   {'id': '3', 'str': 'piyo!'},
                \   {'id': '4', 'str': 'piyo!'},
                \   {'id': '5', 'str': 'piyo!'},
                \]

                call C.execute('delete from mr_test')

                Expect C.select_as_list('select * from mr_test order by id') == []
                Expect C.select_as_dict('select * from mr_test order by id') == []
            finally
                if exists('C')
                    call C.disconnect()
                endif
            endtry
        endfor
    end
end
