" Author: Pablo Acosta <pmasdev@gmail.com>
" Description: pydocstyle for python files

call ale#Set('python_pydocstyle_executable', 'pydocstyle')
call ale#Set('python_pydocstyle_options', '')
call ale#Set('python_pydocstyle_use_global', get(g:, 'ale_use_global_executables', 0))
call ale#Set('python_pydocstyle_auto_pipenv', 0)

function! ale_linters#python#pydocstyle#GetExecutable(buffer) abort
    if (ale#Var(a:buffer, 'python_auto_pipenv') || ale#Var(a:buffer, 'python_pydocstyle_auto_pipenv'))
    \ && ale#python#PipenvPresent(a:buffer)
        return 'pipenv'
    endif

    return ale#python#FindExecutable(a:buffer, 'python_pydocstyle', ['pydocstyle'])
endfunction

function! ale_linters#python#pydocstyle#GetCommand(buffer) abort
    let l:dir = fnamemodify(bufname(a:buffer), ':p:h')
    let l:executable = ale_linters#python#pydocstyle#GetExecutable(a:buffer)

    let l:exec_args = l:executable =~? 'pipenv$'
    \   ? ' run pydocstyle'
    \   : ''

    return ale#path#CdString(l:dir)
    \   . ale#Escape(l:executable) . l:exec_args
    \   . ' ' . ale#Var(a:buffer, 'python_pydocstyle_options')
    \   . ' ' . ale#Escape(fnamemodify(bufname(a:buffer), ':p:t'))
endfunction

function! ale_linters#python#pydocstyle#Handle(buffer, lines) abort
    " Matches patterns like the following:
    " mydir/myfile.py:33 in public function `myfunction`:
    "         DXXX: Error description
    let l:fname = ale#Escape(fnamemodify(bufname(a:buffer), ':p:t'))
    let l:line1_pattern = '\v^' . l:fname . ':\s*(\d+)\s+.*$'
    let l:line2_pattern = '\v^.*([a-zA-Z]\d+):\s*(.*)$'
    let l:output = []

    let l:num_lines = len(a:lines)
    let l:index = 0

    while l:index < l:num_lines
        let l:lnum = matchlist(a:lines[l:index], l:line1_pattern)

        if !empty(l:lnum) && (l:index + 1 < l:num_lines)
            let l:desc = matchlist(a:lines[l:index + 1], l:line2_pattern)

            if !empty(l:desc)
                call add(l:output, {
                \ 'lnum': l:lnum[1] + 0,
                \ 'col': 1,
                \ 'type': 'W',
                \ 'text': l:desc[2],
                \ 'code': l:desc[1],
                \})
            endif

            let l:index = l:index + 2
        else
            let l:index = l:index + 1
        endif
    endwhile

    return l:output
endfunction

call ale#linter#Define('python', {
\   'name': 'pydocstyle',
\   'executable_callback': 'ale_linters#python#pydocstyle#GetExecutable',
\   'command_callback': 'ale_linters#python#pydocstyle#GetCommand',
\   'callback': 'ale_linters#python#pydocstyle#Handle',
\})
