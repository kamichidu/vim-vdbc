let s:save_cpo= &cpo
set cpo&vim

function! vdbc#connect(config)
    let l:obj= {
    \   '_config': a:config,
    \   '_driver': vdbc#driver#{a:config.driver}#connect(a:config),
    \}

    function! l:obj.execute(query, ...)
        call self._driver.execute(a:query, a:000)
    endfunction

    function! l:obj.select_as_list(query, ...)
        return self._driver.select_as_list(a:query, a:000)
    endfunction

    function! l:obj.select_as_dict(query, ...)
        return self._driver.select_as_dict(a:query, a:000)
    endfunction

    function! l:obj.databases(...)
        let l:args= get(a:000, 0, {})

        return self._driver.databases(l:args)
    endfunction

    function! l:obj.catalogs(...)
        let l:args= get(a:000, 0, {})

        return self._driver.catalogs(l:args)
    endfunction

    function! l:obj.schemas(...)
        let l:args= get(a:000, 0, {})

        return self._driver.schemas(l:args)
    endfunction

    function! l:obj.tables(...)
        let l:args= get(a:000, 0, {})

        return self._driver.tables(l:args)
    endfunction

    function! l:obj.columns(...)
        let l:args= get(a:000, 0, {})

        return self._driver.columns(l:args)
    endfunction

    function! l:obj.foreign_keys(...)
        let l:args= get(a:000, 0, {})

        return self._driver.foreign_keys(l:args)
    endfunction

    function! l:obj.indices(...)
        let l:args= get(a:000, 0, {})

        return self._driver.indices(l:args)
    endfunction

    function! l:obj.sequences(...)
        let l:args= get(a:000, 0, {})

        return self._driver.sequences(l:args)
    endfunction

    function! l:obj.views(...)
        let l:args= get(a:000, 0, {})

        return self._driver.views(l:args)
    endfunction

    function! l:obj.disconnect()
        call self._driver.disconnect()
    endfunction

    return l:obj
endfunction

let &cpo= s:save_cpo
unlet s:save_cpo
