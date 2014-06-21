let s:save_cpo= &cpo
set cpo&vim

let s:D= vdbc#Data_Dict()

let s:driver= {
\   'name': 'sqlite3',
\   'sqlite3':  {},
\   'attrs': {
\       'encoding': 'utf8',
\   },
\}

function! vdbc#driver#sqlite3#connect(config)
    let self.attrs= extend(self.attrs, deepcopy(a:config))

    let parts= ['sqlite3']

    if has_key(self.attrs, 'dbname')
        call add(parts, self.attrs.dbname)
    endif

    let sqlite3_cmd= join(parts, ' ')

    let self.sqlite3= vdbc#process#open(sqlite3_cmd)
endfunction

function! s:driver.execute(args)
    call join(s:eval(self.sqlite3, {
    \   'query':  a:args.query,
    \   'mode':   'tabs',
    \   'output': 0,
    \}), "\n")
endfunction

function! s:driver.select_as_list(args)
    return s:eval(self.sqlite3, {
    \   'query': a:args.query,
    \   'mode':  'tabs',
    \})
endfunction

function! s:driver.select_as_dict(args)
    let records= s:eval(self.sqlite3, {
    \   'query': a:args.query,
    \   'mode':  'tabs',
    \})
    let labels= get(a:args, 'keys', records[0])

    return map(records[1 : -2], 's:D.make(labels, v:val)')
endfunction

function! s:driver.disconnect()
    call self.sqlite3.writeln('.q')
    call self.sqlite3.waitpid()
endfunction

function! s:driver.databases(args)
    let records= s:eval(self.sqlite3, {
    \   'query':       '.databases',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \})
    let labels= ['name', 'name', 'file']

    return map(records, 's:D.make(labels, v:val)')
endfunction

function! s:driver.schemas(args)
    let query= join(readfile(globpath(&runtimepath, 'resources/sql/sqlite3_schemas.sql')), "\n")

    return self.select_as_dict({'query': query})
endfunction

function! s:driver.tables(args)
    let query= join(readfile(globpath(&runtimepath, 'resources/sql/sqlite3_tables.sql')), "\n")

    return self.select_as_dict({'query': query})
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

function! vdbc#driver#sqlite3#get()
    return deepcopy(s:driver)
endfunction

function! vdbc#driver#sqlite3#define()
    return deepcopy(s:driver)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
