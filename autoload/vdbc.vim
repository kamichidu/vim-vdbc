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
let s:V= vital#of('vital')
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
    let drivers= split(globpath(&runtimepath, 'autoload/vdbc/driver/*.vim'), '\%(\r\n\|\r\|\n\)')

    return map(drivers, 'fnamemodify(v:val, ":t:r")')
endfunction

let s:available_drivers= s:available_drivers()

let s:vdbc= {
\   'driver': {},
\   'attrs':  {},
\}

" required methods
function! s:vdbc.execute(query, ...)
    call self.driver.execute(extend(deepcopy(get(a:000, 0, {})), {'query': a:query}))
endfunction

function! s:vdbc.select_as_list(query, ...)
    return self.driver.select_as_list(extend(deepcopy(get(a:000, 0, {})), {'query': a:query}))
endfunction

function! s:vdbc.select_as_dict(query, ...)
    return self.driver.select_as_dict(extend(deepcopy(get(a:000, 0, {})), {'query': a:query}))
endfunction

function! s:vdbc.disconnect()
    call self.driver.disconnect()
endfunction

" optional methods
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

function! s:vdbc.schemas(...)
    call s:throw_if_unsupported(self.driver, 'schemas')

    let args= get(a:000, 0, {})
    let args= extend(
    \   {
    \       'catalog': '%',
    \       'schema':  '%',
    \   },
    \   args
    \)

    return self.driver.schemas(args)
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

    if !s:L.has(s:available_drivers, config.driver)
        throw printf("vdbc: driver `%s' does not exists. availables are {%s}", config.driver, join(s:available_drivers, ', '))
    endif

    let obj= deepcopy(s:vdbc)

    let obj.driver= vdbc#driver#{config.driver}#connect(config)
    let obj.attrs=  config

    return obj
endfunction

function! s:throw_if_unsupported(driver, fname)
    if !has_key(a:driver, a:fname)
        throw printf("vdbc: `%s()' is not supported by `%s' driver", a:fname, a:driver.name)
    endif
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
