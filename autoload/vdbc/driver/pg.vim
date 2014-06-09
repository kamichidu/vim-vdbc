let s:save_cpo= &cpo
set cpo&vim

let s:D= vdbc#Data_Dict()
let s:L= vdbc#Data_List()
let s:S= vdbc#Data_String()

let s:driver= {
\   'psql':  {},
\   'attrs': {
\       'host':     'localhost',
\       'port':     5432,
\       'encoding': &encoding,
\   },
\}

""
" @function vdbc#driver#pg#connect
" @param config {Dict}
" @return {Dict}
" @see vdbc
"
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

    return driver
endfunction

""
" @function vdbc.execute
" @param query {String}
"
function! s:driver.execute(args)
    call s:eval(self.psql, {
    \   'query':       a:args.query,
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \})
endfunction

""
" @function vdbc.select_as_list
" @param query {String}
" @return a list of list
"
function! s:driver.select_as_list(args)
    return s:eval(self.psql, {
    \   'query':       a:args.query,
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \})
endfunction

""
" @function vdbc.select_as_dict
" @param query {String}
" @return a list of dict
"
function! s:driver.select_as_dict(args)
    let records= s:eval(self.psql, {
    \   'query':       a:args.query,
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'off',
    \})
    let labels= get(a:args, 'keys', records[0])

    return map(records[1 : -2], 's:D.make(labels, v:val)')
endfunction

""
" 
" @function vdbc.disconnect
"
function! s:driver.disconnect()
    call self.psql.stdin.write('\q' . "\n")
    call self.psql.waitpid()
endfunction

""
" @function vdbc.tables
" @param args {dict}
" @return a list of string
"
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
    call a:psql.stdin.write('\t ' . get(a:args, 'tuples_only', 'off') . "\n")
    call a:psql.stdin.write(s:make_query(a:args.query) . "\n")
    call a:psql.stdin.write('\echo ' . '<<<youjo>>>' . "\n")

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

    let out= s:S.substitute_last(out, '\%(^\|\r\=\n\)<<<youjo>>>\r\=\n', '')

    return map(
    \   split(iconv(out, a:args.encoding, &encoding), '\r\=\n'),
    \   'split(v:val, "|", 1)'
    \)
endfunction

function! s:make_query(query)
    if a:query =~# ';\s*$'
        return a:query
    elseif a:query =~# '\\\w\+\s*$'
        return a:query
    else
        return a:query . ';'
    endif
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
