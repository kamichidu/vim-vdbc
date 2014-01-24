let s:save_cpo= &cpo
set cpo&vim

let s:V= vital#of('vdbc')
let s:PM= s:V.import('ProcessManager')
let s:D=  s:V.import('Data.Dict')
let s:L=  s:V.import('Data.List')
unlet s:V

let s:driver= {
\   '_config': {},
\   '_psql': '',
\   '_tag': '<<youjo>>',
\}

""
" @function vdbc.execute
" @param query {String}
"
function! s:driver.execute(query, ...)
    call self._eval({'query': a:query, 'tuples_only': 'on'})
endfunction

""
" @function vdbc.select_as_list
" @param query {String}
" @return a list of list
"
function! s:driver.select_as_list(query, ...)
    return self._select_as_list({'query': a:query, 'tuples_only': 'on'})
endfunction

""
" @function vdbc.select_as_dict
" @param query {String}
" @return a list of dict
"
function! s:driver.select_as_dict(query, ...)
    let l:args= get(a:000, 0, {})
    let l:list= self._select_as_list({'query': a:query, 'tuples_only': 'off'})

    if empty(l:list)
        return []
    endif

    let l:keys= get(l:args, 'keys', l:list[0])

    return map(l:list[1 : -2], 's:D.make(l:keys, v:val)')
endfunction

function! s:driver.schemas(args)
endfunction

""
" @function vdbc.tables
" @param args {dict}
" @return a list of string
"
function! s:driver.tables(args)
    return self.select_as_dict(join([
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
    \))
endfunction

function! s:driver.columns(args)
endfunction

function! s:driver.foreign_keys(args)
endfunction

function! s:driver.indices(args)
endfunction

function! s:driver.sequences(args)
endfunction

function! s:driver.views(args)
endfunction

""
" 
" @function vdbc.disconnect
"
function! s:driver.disconnect()
    call s:PM.term(self._psql)
endfunction

function! s:driver._select_as_list(args)
    let l:output= self._eval(a:args)
    let l:records= split(iconv(l:output, self._config.encoding, &encoding), "\r\\=\n")

    return map(l:records, 'split(v:val, "|", 1)')
endfunction

function! s:driver._eval(args)
    call s:PM.writeln(self._psql, '\t ' . get(a:args, 'tuples_only', 'off'))
    call s:PM.writeln(self._psql, self._make_query(a:args.query))
    call s:PM.writeln(self._psql, '\echo ' . self._tag)

    let [l:stdout, l:stderr, l:status]= s:PM.read_wait(self._psql, self._config.timeout_length, [self._tag . "\r\\=\n"])

    if l:status ==# 'timedout'
        throw join(['vdbc: query timed out!', l:stderr], "\n    ")
    elseif l:status !=# 'matched' || !empty(l:stderr)
        throw 'vdbc: got an error (' . l:stderr . ')'
    endif

    return l:stdout
endfunction

function! s:driver._make_query(query)
    if a:query =~# ';\s*$'
        return a:query
    else
        return a:query . ';'
    endif
endfunction

""
" @function vdbc#driver#pg#connect
" @param config {Dict}
" @return {Dict}
" @see vdbc
"
function! vdbc#driver#pg#connect(config)
    let l:obj= deepcopy(s:driver)

    let l:obj._config= {}
    let l:obj._config.host= get(a:config, 'host', 'localhost')
    let l:obj._config.port= get(a:config, 'port', 5432)
    let l:obj._config.username= get(a:config, 'username', 'anonymouse')
    let l:obj._config.dbname= get(a:config, 'dbname', 'unknown')
    let l:obj._config.timeout_length= get(a:config, 'timeout_length', 2.0)
    let l:obj._config.encoding= get(a:config, 'encoding', &encoding)

    let l:obj._psql= 'youjo'

    let l:cmd= join([
    \       'psql',
    \       '--host', a:config.host,
    \       '--port', a:config.port,
    \       '--username', a:config.username,
    \       '--dbname', a:config.dbname,
    \       '--no-password',
    \       '--no-align',
    \       '--quiet',
    \   ],
    \   ' '
    \)
    call s:PM.touch(l:obj._psql, l:cmd)

    return l:obj
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
