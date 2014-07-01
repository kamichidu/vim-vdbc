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

" vital
let s:V= vital#of('vdbc')
let s:L= s:V.import('Data.List')
let s:D= s:V.import('Data.Dict')
let s:S= s:V.import('Data.String')
let s:J= s:V.import('Web.JSON')
let s:M= s:V.import('Vim.Message')
unlet s:V

function! vdbc#Data_List()
    return s:L
endfunction
function! vdbc#Data_Dict()
    return s:D
endfunction
function! vdbc#Data_String()
    return s:S
endfunction
function! vdbc#Web_JSON()
    return s:J
endfunction
function! vdbc#Vim_Message()
    return s:M
endfunction

function! s:available_drivers()
    let driver_names= map(
    \   split(
    \       globpath(&runtimepath, 'autoload/vdbc/driver/*.vim'),
    \       '\%(\r\n\|\r\|\n\)'
    \   ),
    \   'fnamemodify(v:val, ":t:r")'
    \)
    let drivers= map(driver_names, 'vdbc#driver#{v:val}#define()')

    return drivers
endfunction

let s:available_drivers= s:available_drivers()

let s:vdbc= {
\   'driver': {},
\   'attrs':  {},
\}

" required methods
function! s:vdbc.prepare(query)
    let stmt_id= self.driver.prepare({'query': a:query})

    return vdbc#statement#new(self.driver, stmt_id)
endfunction

function! s:vdbc.execute(query, ...)
    try
        let stmt= self.prepare(a:query)

        call stmt.execute(get(a:000, 0, []))
    finally
        if exists('stmt')
            call stmt.finish()
        endif
    endtry
endfunction

function! s:vdbc.select_as_list(query, ...)
    try
        let stmt= self.prepare(a:query)

        return stmt.select_as_list(get(a:000, 0, []))
    finally
        if exists('stmt')
            call stmt.finish()
        endif
    endtry
endfunction

function! s:vdbc.select_as_dict(query, ...)
    try
        let stmt= self.prepare(a:query)

        return stmt.select_as_dict(get(a:000, 0, []))
    finally
        if exists('stmt')
            call stmt.finish()
        endif
    endtry
endfunction

function! s:vdbc.disconnect()
    call self.driver.disconnect()
endfunction

" optional methods
function! s:vdbc.begin()
    call s:throw_if_unsupported(self.driver, 'begin')

    call self.driver.begin()

    return vdbc#transaction#new(self.driver)
endfunction

" TODO: remove or change api
function! s:vdbc.databases(...)
    call s:throw_if_unsupported(self.driver, 'databases')

    let args= get(a:000, 0, {})

    return self.driver.databases(args)
endfunction

function! s:vdbc.catalogs(...)
    call s:throw_if_unsupported(self.driver, 'catalogs')

    let args= get(a:000, 0, {})
    let args= extend(
    \   {
    \       'catalog': '%',
    \   },
    \   args
    \)

    return self.driver.catalogs(args)
endfunction

function! s:vdbc.schemata(...)
    call s:throw_if_unsupported(self.driver, 'schemata')

    let args= get(a:000, 0, {})
    let args= extend(
    \   {
    \       'catalog': '%',
    \       'schema':  '%',
    \   },
    \   args
    \)

    return self.driver.schemata(args)
endfunction

" catalog, schema
function! s:vdbc.tables(...)
    call s:throw_if_unsupported(self.driver, 'tables')

    let args= get(a:000, 0, {})
    let args= extend(
    \   {
    \       'catalog': '%',
    \       'schema':  '%',
    \       'table':   '%',
    \       'types':   ['table', 'view'],
    \   },
    \   args
    \)

    let infos= self.driver.tables(args)

    let default_object= {
    \   'catalog': '',
    \   'schema':  '',
    \   'name':    '',
    \   'type':    '',
    \   'remarks': '',
    \}

    return map(infos, 'extend(copy(default_object), v:val)')
endfunction

" catalog, schema, table
function! s:vdbc.columns(...)
    call s:throw_if_unsupported(self.driver, 'tables')

    let args= get(a:000, 0, {})
    let args= extend(
    \   {
    \       'catalog': '%',
    \       'schema':  '%',
    \       'table':   '%',
    \       'column':  '%',
    \   },
    \   args
    \)

    let infos= self.driver.columns(args)

    let default_object= {
    \   'catalog':          '',
    \   'schema':           '',
    \   'table':            '',
    \   'name':             '',
    \   'type_name':        '',
    \   'ordinal_position': -1,
    \   'nullable':         1,
    \   'remarks':          '',
    \}

    return map(infos, 'extend(copy(default_object), v:val)')
endfunction

" catalog, schema, table
function! s:vdbc.foreign_keys(...)
    call s:throw_if_unsupported(self.driver, 'foreign_keys')

    let args= get(a:000, 0, {})

    return self.driver.foreign_keys(args)
endfunction

" catalog, schema, table
function! s:vdbc.indices(...)
    call s:throw_if_unsupported(self.driver, 'indices')

    let args= get(a:000, 0, {})

    return self.driver.indices(args)
endfunction

" catalog, schema
function! s:vdbc.sequences(...)
    call s:throw_if_unsupported(self.driver, 'sequences')

    let args= get(a:000, 0, {})

    return self.driver.sequences(args)
endfunction

"
" config
"   driver:   type('')
"   host:     type('')
"   port:     type(0)
"   username: type('')
"   dbname:   type('')
"
function! vdbc#connect(config)
    let config= deepcopy(a:config)

    if !has_key(config, 'driver')
        throw "vdbc: `driver' attribute is required."
    endif
    if !has_key(config, 'dbname')
        throw "vdbc: `dbname' attribute is required."
    endif

    let obj= deepcopy(s:vdbc)

    let obj.driver= deepcopy(s:find_driver_by_name(s:available_drivers, config.driver))
    let obj.attrs=  config

    call obj.driver.connect(config)

    return obj
endfunction

function! vdbc#connect_by_dsn(dsn)
    if a:dsn !~# '\C^vdbc:'
        throw 'vdbc: illegal dsn format.'
    endif

    let [_, driver, options]= split(a:dsn, '\\\@<!:', 1)

    let config= {
    \   'driver': driver,
    \}
    for option in split(options, '\\\@<!;')
        let [key, value]= split(option, '\\\@<!=', 1)

        let config[key]= value
    endfor

    return vdbc#connect(config)
endfunction

function! s:throw_if_unsupported(driver, fname)
    if !has_key(a:driver, a:fname)
        throw printf("vdbc: `%s()' is not supported by `%s' driver", a:fname, a:driver.name)
    endif
endfunction

function! s:find_driver_by_name(list, name)
    " name ends with `*', then we will find a driver by prefix and priority
    if a:name =~# '*$'
        let prefix= '\C^' . substitute(a:name, '*$', '', '')

        for driver in a:list
            if driver.name =~# prefix
                if !exists('found') || driver.priority < found.priority
                    let found= driver
                endif
            endif
        endfor

        if exists('found')
            return found
        endif
    else
        for driver in a:list
            if driver.name ==# a:name
                return driver
            endif
        endfor
    endif

    let driver_names= map(copy(a:list), 'v:val.name')
    throw printf("vdbc: driver `%s' does not exists. availables are {%s}", a:name, join(driver_names, ', '))
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
