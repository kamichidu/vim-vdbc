let s:save_cpo= &cpo
set cpo&vim

let s:J= vdbc#Web_JSON()

let s:driver= vdbc#driver#sqlite3#get()

let s:driver.name= 'sqlite3_libsqlite3'

function! vdbc#driver#sqlite3_libsqlite3#connect(config)
    let driver= deepcopy(s:driver)

    let driver.attrs= extend(driver.attrs, deepcopy(a:config))

    let conninfo= {}

    if has_key(driver.attrs, 'dbname')
        let conninfo.dbname= driver.attrs.dbname
    endif

    let ret= s:libcall('vdbc_sqlite3_libsqlite3_connect', conninfo)

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    let driver.attrs.id= ret.id

    return driver
endfunction

function! s:driver.execute(args)
    throw 'vdbc: sorry, unimplemented yet'
endfunction

function! s:driver.select_as_list(args)
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_select_as_list', {
    \   'id': self.attrs.id,
    \   'query': a:args.query,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    return ret.result
endfunction

function! s:driver.select_as_dict(args)
    throw 'vdbc: sorry, unimplemented yet'
endfunction

function! s:driver.disconnect()
    let ret= s:libcall('vdbc_sqlite3_libsqlite3_disconnect', {
    \   'id': self.attrs.id,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif
endfunction

function! s:libcall(func, dict)
    if !exists('s:libname')
        if has('win32') || has('win64')
            let s:libname= globpath(&runtimepath, 'autoload/vdbc/driver/sqlite3_libsqlite3.dll')
        else
            let s:libname= globpath(&runtimepath, 'autoload/vdbc/driver/sqlite3_libsqlite3.so')
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

let &cpo= s:save_cpo
unlet s:save_cpo
