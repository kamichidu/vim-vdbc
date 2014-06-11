let s:save_cpo= &cpo
set cpo&vim

let s:process= {
\   'attrs': {
\       'pipe': {},
\       'term_encoding':  &termencoding,
\   },
\}

function! s:process.write(...)
    call self.attrs.pipe.stdin.write(get(a:000, 0, ''))
endfunction

function! s:process.writeln(...)
    call self.attrs.pipe.stdin.write(get(a:000, 0, '') . "\n")
endfunction

function! s:process.read(terminator)
    let terminate_pattern= '\%(^\|\r\n\|\r\|\n\)' . a:terminator . '\%(\r\n\|\r\|\n\)'
    let [out, err]= ['', '']
    while !self.attrs.pipe.stdout.eof
        let out.= self.attrs.pipe.stdout.read()
        let err.= self.attrs.pipe.stderr.read()

        if out =~# terminate_pattern
            break
        endif
    endwhile

    " convert terminal encoding
    let out= iconv(out, self.attrs.term_encoding, &encoding)
    let err= iconv(err, self.attrs.term_encoding, &encoding)
    " convert {lf, cr, crlf}
    let out= substitute(out, '\%(\r\n\|\r\|\n\)', "\n", 'g')
    let err= substitute(err, '\%(\r\n\|\r\|\n\)', "\n", 'g')

    return [out, err]
endfunction

function! s:process.read_lines(terminator)
    let [out, err]= self.read(a:terminator)

    return [split(out, "\n"), split(err, "\n")]
endfunction

function! s:process.waitpid()
    return self.attrs.pipe.waitpid()
endfunction

function! vdbc#process#open(command, ...)
    let process= deepcopy(s:process)

    let process.attrs= extend(process.attrs, get(a:000, 0, {}))
    let process.attrs.pipe= vimproc#popen3(a:command)

    return process
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
