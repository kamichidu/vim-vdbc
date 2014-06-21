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

let s:statement= {
\   'id':     -1,
\   'driver': {},
\}

function! s:statement.execute(...)
    let values= get(a:000, 0, [])

    call self.driver.execute({
    \   'statement_id': self.id,
    \   'bind_values':  values,
    \})
endfunction

function! s:statement.select_as_list(...)
    let values= get(a:000, 0, [])

    return self.driver.select_as_list({
    \   'statement_id': self.id,
    \   'bind_values':  values,
    \})
endfunction

function! s:statement.select_as_dict(...)
    let values= get(a:000, 0, [])

    return self.driver.select_as_dict({
    \   'statement_id': self.id,
    \   'bind_values':  values,
    \})
endfunction

function! s:statement.finish()
    call self.driver.deallocate({'statement_id': self.id})

    unlet self.id
endfunction

function! vdbc#statement#new(driver, id)
    let stmt= deepcopy(s:statement)

    let stmt.driver= a:driver
    let stmt.id=     a:id

    return stmt
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
