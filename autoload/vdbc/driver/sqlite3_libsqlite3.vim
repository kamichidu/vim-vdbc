let s:save_cpo= &cpo
set cpo&vim

let s:J= vdbc#Web_JSON()

let s:driver= vdbc#driver#sqlite3#define()

let s:driver.name= 'sqlite3_libsqlite3'
let s:driver.priority= 50

function! s:driver.connect(config)
    let self.attrs= extend(self.attrs, deepcopy(a:config))

    let conninfo= {}

    if has_key(self.attrs, 'dbname')
        let conninfo.dbname= self.attrs.dbname
    endif

    let ret= s:libcall('vdbc_sqlite3_libsqlite3_connect', conninfo)

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    let self.attrs.id= ret.id
endfunction

function! s:driver.prepare(args)
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_prepare', {
    \   'id': self.attrs.id,
    \   'query': a:args.query,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    return ret.statement_id
endfunction

function! s:driver.deallocate(args)
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_deallocate', {
    \   'id': self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif
endfunction

function! s:driver.execute(args)
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_execute', {
    \   'id':           self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \   'bind_values':  a:args.bind_values,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif
endfunction

function! s:driver.select_as_list(args)
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_select_as_list', {
    \   'id': self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \   'bind_values':  a:args.bind_values,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    return ret.result
endfunction

function! s:driver.select_as_dict(args)
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_select_as_dict', {
    \   'id': self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \   'bind_values':  a:args.bind_values,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    return ret.result
endfunction

function! s:driver.disconnect()
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_disconnect', {
    \   'id': self.attrs.id,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif
endfunction

function! s:driver.connection_status()
    " XXX: maybe... always active
    return 'active'
endfunction

function! s:libcall(func, dict)
    if !exists('s:libname')
        if has('win32') || has('win64')
            let s:libname= globpath(&runtimepath, 'lib/sqlite3_libsqlite3.dll')
        else
            let s:libname= globpath(&runtimepath, 'lib/sqlite3_libsqlite3.so')
        endif

        let ret= s:J.decode(libcall(s:libname, 'vdbc_sqlite3_libsqlite3_initialize', s:libname))

        if float2nr(ret.success)
            let s:handle= ret.handle
        else
            throw 'vdbc: ' . get(ret, 'message', 'unknown error')
        endif

        augroup vdbc_driver_sqlite3_libsqlite3
            autocmd!
            autocmd VimLeavePre * if exists('s:handle') && !empty(s:handle)
            autocmd VimLeavePre *     let ret= s:J.decode(libcall(s:libname, 'vdbc_sqlite3_libsqlite3_terminate', s:handle))
            autocmd VimLeavePre *     if !float2nr(ret.success)
            autocmd VimLeavePre *         throw 'vdbc: ' . get(ret, 'message', 'unknown error')
            autocmd VimLeavePre *     endif
            autocmd VimLeavePre * endif
        augroup END
    endif

    return s:J.decode(libcall(s:libname, a:func, s:J.encode(a:dict)))
endfunction

function! vdbc#driver#sqlite3_libsqlite3#define()
    return deepcopy(s:driver)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
