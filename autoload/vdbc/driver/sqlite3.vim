let s:save_cpo= &cpo
set cpo&vim

let s:D= vdbc#Data_Dict()
let s:S= vdbc#Data_String()

let s:driver= {
\   'name': 'sqlite3',
\   'priority': 99,
\   'sqlite3':  {},
\   'prepare_counter': 0,
\   'prepare_queries': {},
\   'attrs': {
\       'encoding': 'utf8',
\   },
\}

function! s:driver.connect(args)
    let self.attrs= extend(self.attrs, deepcopy(a:args))

    let sqlite3_cmd= join(['sqlite3', self.attrs.dbname], ' ')

    let self.sqlite3= vdbc#process#open(sqlite3_cmd)
endfunction

function! s:driver.prepare(args)
    let self.prepare_counter+= 1

    let self.prepare_queries[self.prepare_counter]= a:args.query

    return self.prepare_counter
endfunction

function! s:driver.deallocate(args)
    unlet self.prepare_queries[a:args.statement_id]
endfunction

function! s:driver.execute(args)
    let query= s:fake_bind(self.prepare_queries[a:args.statement_id], a:args.bind_values)

    call join(s:eval(self.sqlite3, {
    \   'query':  query,
    \   'mode':   'tabs',
    \   'output': 0,
    \}), "\n")
endfunction

function! s:driver.select_as_list(args)
    let query= s:fake_bind(self.prepare_queries[a:args.statement_id], a:args.bind_values)

    return s:eval(self.sqlite3, {
    \   'query': query,
    \   'mode':  'tabs',
    \})
endfunction

function! s:driver.select_as_dict(args)
    let query= s:fake_bind(self.prepare_queries[a:args.statement_id], a:args.bind_values)

    let records= s:eval(self.sqlite3, {
    \   'query': query,
    \   'mode':  'tabs',
    \   'headers': 'on',
    \})

    if empty(records)
        return []
    endif

    let labels= get(a:args, 'keys', records[0])

    return map(records[1 : -1], 's:D.make(labels, v:val)')
endfunction

function! s:driver.disconnect()
    call self.sqlite3.writeln('.q')
    call self.sqlite3.waitpid()
endfunction

function! s:driver.connection_status()
    " XXX: maybe... always active
    return 'active'
endfunction

function! s:driver.begin()
    try
        let stmt_id= self.prepare({'query': 'begin transaction'})

        call self.execute({'statement_id': stmt_id, 'bind_values': []})
    finally
        if exists('stmt_id')
            call self.deallocate({'statement_id': stmt_id})
        endif
    endtry
endfunction

function! s:driver.commit()
    try
        let stmt_id= self.prepare({'query': 'commit transaction'})

        call self.execute({'statement_id': stmt_id, 'bind_values': []})
    finally
        if exists('stmt_id')
            call self.deallocate({'statement_id': stmt_id})
        endif
    endtry
endfunction

function! s:driver.rollback()
    try
        let stmt_id= self.prepare({'query': 'rollback transaction'})

        call self.execute({'statement_id': stmt_id, 'bind_values': []})
    finally
        if exists('stmt_id')
            call self.deallocate({'statement_id': stmt_id})
        endif
    endtry
endfunction

function! s:driver.tables(args)
    try
        let stmt_id= self.prepare({'query': 'select name, type from sqlite_master'})

        let tables= map(self.select_as_dict({'statement_id': stmt_id, 'bind_values': []}), "
        \   {
        \       'catalog': '',
        \       'schema':  '',
        \       'name':    v:val.name,
        \       'type':    v:val.type,
        \       'remarks': '',
        \   }
        \")
    finally
        if exists('stmt_id')
            call self.deallocate({'statement_id': stmt_id})
        endif
    endtry

    call filter(tables, 'v:val.catalog =~# ''\c^' . substitute(a:args.catalog, '%', '.*', 'g') . '$''')
    call filter(tables, 'v:val.schema  =~# ''\c^' . substitute(a:args.schema, '%', '.*', 'g') . '$''')
    call filter(tables, 'v:val.name    =~# ''\c^' . substitute(a:args.table, '%', '.*', 'g') . '$''')
    call filter(tables, 'v:val.type    =~# ''\c^\%(' . join(a:args.types, '\|') . '\)$''')
    return tables
endfunction

function! s:driver.columns(args)
    let tables= self.tables(extend({'types': ['table', 'view']}, a:args))
    let columns= []

    for table in tables
        try
            let stmt_id= self.prepare({'query': printf('pragma table_info(%s)', table.name)})

            let columns+= map(self.select_as_dict({'statement_id': stmt_id, 'bind_values': []}), "
            \   {
            \       'catalog':          table.catalog,
            \       'schema':           table.schema,
            \       'table':            table.name,
            \       'name':             v:val.name,
            \       'type_name':        v:val.type,
            \       'ordinal_position': v:val.cid,
            \       'nullable':         !v:val.notnull ? 't' : 'f',
            \       'remarks':          '',
            \   }
            \")
        finally
            if exists('stmt_id')
                call self.deallocate({'statement_id': stmt_id})
            endif
        endtry
    endfor

    return filter(columns, 'v:val.name =~# ''\c^' . substitute(a:args.column, '%', '.*', 'g') . '$''')
endfunction

function! s:eval(sqlite3, args)
    if get(a:args, 'output', 1)
        let ofilename= tempname()
    elseif vimproc#util#is_windows()
        let ofilename= 'nul'
    else
        let ofilename= '/dev/null'
    endif

    " output query result to temporary file
    call a:sqlite3.writeln('.headers ' . get(a:args, 'headers', 'off'))
    call a:sqlite3.writeln('.output ' . ofilename)
    call a:sqlite3.writeln(s:make_query(a:args.query))

    call a:sqlite3.writeln('.output stdout')
    call a:sqlite3.writeln('select ''<<youjo>>'';')

    let [out, err] = a:sqlite3.read('<<youjo>>')

    if !empty(err)
        throw printf("vdbc: an error occured `%s'", substitute(err, '\%(\r\n\|\r\|\n\)', "\n", 'g'))
    endif

    if !get(a:args, 'output', 1)
        return []
    endif

    let query_output= join(readfile(ofilename), "\n")

    return map(
    \   split(iconv(query_output, 'utf-8', &encoding), "\n"),
    \   'split(v:val, "|", 1)'
    \)
endfunction

function! s:make_query(query)
    if a:query =~# ';\s*$' || a:query =~# '^\s*\\'
        return a:query
    else
        return a:query . ';'
    endif
endfunction

function! s:fake_bind(query, values)
    let buffer= a:query
    for value in a:values
        let buffer= s:S.replace_first(buffer, '?', string(value))
    endfor
    return buffer
endfunction

function! vdbc#driver#sqlite3#define()
    return deepcopy(s:driver)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
