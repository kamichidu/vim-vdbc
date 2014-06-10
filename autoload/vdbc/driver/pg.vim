let s:save_cpo= &cpo
set cpo&vim

let s:D= vdbc#Data_Dict()

let s:driver= {
\   'psql':  {},
\   'attrs': {
\       'host':     'localhost',
\       'port':     5432,
\       'encoding': 'utf8',
\   },
\}

function! vdbc#driver#pg#connect(config)
    let driver= deepcopy(s:driver)

    let driver.attrs= extend(driver.attrs, deepcopy(a:config))

    let parts= ['psql']

    if has_key(driver.attrs, 'host')
        call add(parts, '--host ' . driver.attrs.host)
    endif
    if has_key(driver.attrs, 'port')
        call add(parts, '--port ' . driver.attrs.port)
    endif
    if has_key(driver.attrs, 'username')
        call add(parts, '--username ' . driver.attrs.username)
    endif
    if has_key(driver.attrs, 'dbname')
        call add(parts, '--dbname ' . driver.attrs.dbname)
    endif

    let psql_cmd= join(parts + ['--no-password', '--no-align', '--quiet'], ' ')

    let driver.psql= vimproc#popen3(psql_cmd)

    " attach utility functions
    function! driver.psql.stdin.writeln(...)
        call self.write(get(a:000, 0, '') . "\n")
    endfunction

    call driver.execute({'query': '\encoding UTF-8'})

    return driver
endfunction

function! s:driver.execute(args)
    call join(s:eval(self.psql, {
    \   'query':       a:args.query,
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \}), "\n")
endfunction

function! s:driver.select_as_list(args)
    return s:eval(self.psql, {
    \   'query':       a:args.query,
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \})
endfunction

function! s:driver.select_as_dict(args)
    let records= s:eval(self.psql, {
    \   'query':       a:args.query,
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'off',
    \})
    let labels= get(a:args, 'keys', records[0])

    return map(records[1 : -2], 's:D.make(labels, v:val)')
endfunction

function! s:driver.disconnect()
    call self.psql.stdin.writeln('\q')
    call self.psql.waitpid()
endfunction

function! s:driver.databases(args)
    let records= s:eval(self.psql, {
    \   'query':       '\l',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \})
    let labels= ['name', 'owner', 'encoding', 'collate', 'ctype', 'access_privileges']

    return map(records, 's:D.make(labels, v:val)')
endfunction

function! s:driver.schemas(args)
    return self.select_as_dict(join([
    \       ' select                    ',
    \       '     null as "catalog",    ',
    \       '     nsp.nspname as "name" ',
    \       ' from                      ',
    \       '     pg_namespace as nsp   ',
    \   ],
    \   ''
    \))
endfunction

function! s:driver.tables(args)
    let query= join([
    \       ' select                             ',
    \       '     null as "catalog",             ',
    \       '     nsp.nspname as "schema",       ',
    \       '     cls.relname as "name",         ',
    \       '     ''table'' as "type",           ',
    \       '     rem.description as "remarks"   ',
    \       ' from                               ',
    \       '     pg_class as cls                ',
    \       '     inner join                     ',
    \       '         pg_namespace as nsp        ',
    \       '     on                             ',
    \       '         cls.relnamespace = nsp.oid ',
    \       '     left join                      ',
    \       '         pg_description as rem      ',
    \       '     on                             ',
    \       '         cls.oid = rem.objoid and   ',
    \       '         rem.objsubid = 0           ',
    \       ' where                              ',
    \       '     cls.relkind = ''r'' and        ',
    \       '     nsp.nspname = ''public''       ',
    \   ],
    \   ''
    \)
    return self.select_as_dict({'query': query})
endfunction

function! s:eval(psql, args)
    if get(a:args, 'output', 1)
        let ofilename= tempname()
    elseif vimproc#util#is_windows()
        let ofilename= 'nul'
    else
        let ofilename= '/dev/null'
    endif

    call a:psql.stdin.writeln('\t ' . get(a:args, 'tuples_only', 'off'))
    " output query result to temporary file
    call a:psql.stdin.writeln('\o ' . ofilename)
    call a:psql.stdin.writeln(s:make_query(a:args.query))
    " reset
    call a:psql.stdin.writeln('\o')

    call a:psql.stdin.writeln('\echo <<<youjo>>>')

    let [out, err]= ['', '']
    while !a:psql.stdout.eof
        let out.= a:psql.stdout.read()
        let err.= a:psql.stderr.read()

        if out =~# '\%(^\|\r\=\n\)<<<youjo>>>\r\=\n'
            break
        endif
    endwhile

    if !empty(err)
        throw printf("vdbc: an error occured `%s'", err)
    endif

    if !get(a:args, 'output', 1)
        return []
    endif

    let query_output= join(readfile(ofilename), "\n")

    return map(
    \   split(iconv(query_output, a:args.encoding, &encoding), '\r\=\n'),
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

let &cpo= s:save_cpo
unlet s:save_cpo
