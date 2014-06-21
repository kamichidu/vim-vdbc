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
let s:S= vdbc#Data_String()

let s:driver= vdbc#driver#pg#define()

let s:driver.name= 'pg_libpq'

function! s:driver.connect(config)
    let self.attrs= extend(self.attrs, deepcopy(a:config))

    let conninfo= {}

    if has_key(self.attrs, 'host')
        let conninfo.host= self.attrs.host
    endif
    if has_key(self.attrs, 'port')
        let conninfo.port= self.attrs.port
    endif
    if has_key(self.attrs, 'username')
        let conninfo.user= self.attrs.username
    endif
    if has_key(self.attrs, 'password')
        let conninfo.password= self.attrs.password
    endif
    if has_key(self.attrs, 'dbname')
        let conninfo.dbname= self.attrs.dbname
    endif

    let ret= s:libcall('vdbc_pg_libpq_connect', conninfo)

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    let self.attrs.id= ret.id
endfunction

function! s:driver.prepare(args)
    let query= a:args.query
    let cnt= 0
    while query =~# '?'
        let cnt+= 1
        let query= s:S.replace_first(query, '?', '$' . cnt)
    endwhile

    let ret= s:libcall('vdbc_pg_libpq_prepare', {
    \   'id': self.attrs.id,
    \   'query': query,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    return ret.statement_id
endfunction

function! s:driver.deallocate(args)
    let ret= s:libcall('vdbc_pg_libpq_deallocate', {
    \   'id': self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif
endfunction

function! s:driver.execute(args)
    let ret= s:libcall('vdbc_pg_libpq_execute', {
    \   'id': self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \   'bind_values': a:args.bind_values,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif
endfunction

function! s:driver.select_as_list(args)
    let ret= s:libcall('vdbc_pg_libpq_select_as_list', {
    \   'id': self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \   'bind_values': a:args.bind_values,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    return ret.result
endfunction

function! s:driver.select_as_dict(args)
    let ret= s:libcall('vdbc_pg_libpq_select_as_dict', {
    \   'id': self.attrs.id,
    \   'statement_id': a:args.statement_id,
    \   'bind_values': a:args.bind_values,
    \})

    if !float2nr(ret.success)
        throw 'vdbc: ' . get(ret, 'message', 'unknown error')
    endif

    return ret.result
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

function! vdbc#driver#pg_libpq#define()
    return deepcopy(s:driver)
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
