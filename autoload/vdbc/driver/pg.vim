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

let s:driver= {
\   'name': 'pg',
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

    let driver.psql= vdbc#process#open(psql_cmd)

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
    call self.psql.writeln('\q')
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

function! vdbc#driver#pg#get()
    return deepcopy(s:driver)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
