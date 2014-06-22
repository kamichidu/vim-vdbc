" The MIT License (MIT)
"
" Copyright (c) 2014 kamichidu
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
let s:save_cpo= &cpo
set cpo&vim

let s:D= vdbc#Data_Dict()
let s:S= vdbc#Data_String()

let s:driver= {
\   'name': 'pg',
\   'psql':  {},
\   'prepare_counter': 0,
\   'attrs': {
\       'host':     'localhost',
\       'port':     5432,
\       'encoding': 'utf8',
\   },
\}

function! s:driver.connect(config)
    let self.attrs= extend(self.attrs, deepcopy(a:config))

    let parts= ['psql']

    if has_key(self.attrs, 'host')
        call add(parts, '--host ' . self.attrs.host)
    endif
    if has_key(self.attrs, 'port')
        call add(parts, '--port ' . self.attrs.port)
    endif
    if has_key(self.attrs, 'username')
        call add(parts, '--username ' . self.attrs.username)
    endif
    if has_key(self.attrs, 'dbname')
        call add(parts, '--dbname ' . self.attrs.dbname)
    endif

    let psql_cmd= join(parts + ['--no-password', '--no-align', '--quiet'], ' ')

    let self.psql= vdbc#process#open(psql_cmd)

    call s:eval(self.psql, {
    \   'query':       '\encoding UTF-8',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \})
endfunction

function! s:driver.prepare(args)
    let query= s:S.substitute_last(a:args.query, ';$', '')
    let cnt= 0
    while query =~# '?'
        let cnt+= 1
        let query= s:S.replace_first(query, '?', '$' . cnt)
    endwhile

    let name= printf('autogen_%08d', self.prepare_counter)
    let self.prepare_counter+= 1

    call s:eval(self.psql, {
    \   'query': 'prepare ' . name . ' as ' . query . ';',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \})

    return name
endfunction

function! s:driver.deallocate(args)
    call s:eval(self.psql, {
    \   'query': 'deallocate ' . a:args.statement_id . ';',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \})
endfunction

function! s:driver.execute(args)
    let query_parts= ['execute', a:args.statement_id]

    if !empty(a:args.bind_values)
        let query_parts+= ['(']
        let query_parts+= [join(map(a:args.bind_values, 'string(v:val)'), ',')]
        let query_parts+= [')']
    endif

    let query_parts+= [';']

    call join(s:eval(self.psql, {
    \   'query':       join(query_parts, ' '),
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \}), "\n")
endfunction

function! s:driver.select_as_list(args)
    let query_parts= ['execute', a:args.statement_id]

    if !empty(a:args.bind_values)
        let query_parts+= ['(']
        let query_parts+= [join(map(a:args.bind_values, 'string(v:val)'), ',')]
        let query_parts+= [')']
    endif

    let query_parts+= [';']

    return s:eval(self.psql, {
    \   'query':       join(query_parts, ' '),
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \})
endfunction

function! s:driver.select_as_dict(args)
    let query_parts= ['execute', a:args.statement_id]

    if !empty(a:args.bind_values)
        let query_parts+= ['(']
        let query_parts+= [join(map(a:args.bind_values, 'string(v:val)'), ',')]
        let query_parts+= [')']
    endif

    let query_parts+= [';']

    let records= s:eval(self.psql, {
    \   'query':       join(query_parts, ' '),
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'off',
    \})
    let labels= get(a:args, 'keys', records[0])

    return map(records[1 : -2], 's:D.make(labels, v:val)')
endfunction

function! s:driver.disconnect()
    call self.psql.writeln('\q')
    call self.psql.waitpid()
endfunction

function! s:driver.begin()
    call s:eval(self.psql, {
    \   'query':       'begin',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \})
endfunction

function! s:driver.commit()
    call s:eval(self.psql, {
    \   'query':       'commit',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \})
endfunction

function! s:driver.rollback()
    call s:eval(self.psql, {
    \   'query':       'rollback',
    \   'encoding':    self.attrs.encoding,
    \   'tuples_only': 'on',
    \   'output':      0,
    \})
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

function! s:driver.schemata(args)
    let query= join(readfile(globpath(&runtimepath, 'resources/sql/pg_schemata.sql')), "\n")

    return self.select_as_dict({'query': query})
endfunction

function! s:driver.tables(args)
    let query= join(readfile(globpath(&runtimepath, 'resources/sql/pg_tables.sql')), "\n")

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

    call a:psql.writeln('\t ' . get(a:args, 'tuples_only', 'off'))
    " output query result to temporary file
    call a:psql.writeln('\o ' . ofilename)
    call a:psql.writeln(s:make_query(a:args.query))
    " reset
    call a:psql.writeln('\o')

    call a:psql.writeln('\echo <<<youjo>>>')

    let [out, err]= a:psql.read('<<<youjo>>>')

    if !empty(err)
        throw printf("vdbc: an error occured `%s'", substitute(err, '\%(\r\n\|\r\|\n\)', "\n", 'g'))
    endif

    if !get(a:args, 'output', 1)
        return []
    endif

    let query_output= join(readfile(ofilename), "\n")

    return map(
    \   split(iconv(query_output, a:args.encoding, &encoding), "\n"),
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

function! vdbc#driver#pg#define()
    return deepcopy(s:driver)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
