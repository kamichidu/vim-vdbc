let s:save_cpo= &cpo
set cpo&vim

" vital
let s:V= vital#of('vital')
let s:L= s:V.import('Data.List')
let s:D= s:V.import('Data.Dict')
let s:S= s:V.import('Data.String')
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
function! vdbc#Vim_Message()
    return s:M
endfunction

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

    return self.driver.catalogs(args)
endfunction

function! s:vdbc.schemas(...)
    call s:throw_if_unsupported(self.driver, 'schemas')

    let args= get(a:000, 0, {})

    return self.driver.schemas(args)
endfunction

" catalog, schema
function! s:vdbc.tables(...)
    call s:throw_if_unsupported(self.driver, 'tables')

    let args= get(a:000, 0, {})

    return self.driver.tables(args)
endfunction

" catalog, schema, table
function! s:vdbc.columns(...)
    call s:throw_if_unsupported(self.driver, 'tables')

    let args= get(a:000, 0, {})

    return self.driver.columns(l:args)
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

" catalog, schema
function! s:vdbc.views(...)
    call s:throw_if_unsupported(self.driver, 'views')

    let args= get(a:000, 0, {})

    return self.driver.views(args)
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
