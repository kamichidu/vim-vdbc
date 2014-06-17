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

let s:J= vdbc#Web_JSON()

let s:driver= vdbc#driver#pg#get()

let s:driver.name= 'pg_libpq'

function! vdbc#driver#pg_libpq#connect(config)
    let driver= deepcopy(s:driver)

    let driver.attrs= extend(driver.attrs, deepcopy(a:config))

    let conninfo= {}

    if has_key(driver.attrs, 'host')
        let conninfo.host= driver.attrs.host
    endif
    if has_key(driver.attrs, 'port')
        let conninfo.port= driver.attrs.port
    endif
    if has_key(driver.attrs, 'username')
        let conninfo.user= driver.attrs.username
    endif
    if has_key(driver.attrs, 'password')
        let conninfo.password= driver.attrs.password
    endif
    if has_key(driver.attrs, 'dbname')
        let conninfo.dbname= driver.attrs.dbname
    endif

    let ret= s:libcall('vdbc_pg_libpq_connect', conninfo)

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
    let ret= s:libcall('vdbc_pg_libpq_select_as_list', {
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
    let ret= s:libcall('vdbc_pg_libpq_disconnect', {
    \   'id': self.attrs.id,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif
endfunction

function! s:libcall(func, dict)
    if !exists('s:libname')
        if has('win32') || has('win64')
            let s:libname= globpath(&runtimepath, 'autoload/vdbc/driver/pg_libpq.dll')
        else
            let s:libname= globpath(&runtimepath, 'autoload/vdbc/driver/pg_libpq.so')
        endif

        let ret= s:J.decode(libcall(s:libname, 'vdbc_pg_libpq_initialize', s:libname))

        if float2nr(ret.success)
            let s:handle= ret.handle
        else
            throw 'vdbc: ' . get(ret, 'message', 'unknown error')
        endif

        augroup vdbc_driver_pg_libpq
            autocmd!
            autocmd VimLeavePre * if exists('s:handle') && !empty(s:handle)
            autocmd VimLeavePre *     let ret= s:J.decode(libcall(s:libname, 'vdbc_pg_libpq_terminate', s:handle))
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
