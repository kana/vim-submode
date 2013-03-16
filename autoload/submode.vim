" submode - Create your own submodes
" Version: 0.1.0
" Copyright (C) 2008-2013 kana <http://whileimautomaton.net/>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" Concept  "{{{1
"
" In the following pseudo code, :MAP means :map or :noremap, and it depends on
" user's specification.
"
" map {key-to-enter}
" \   <Plug>(submode-before-entering:{submode}:with:{key-to-enter})
"    \<Plug>(submode-before-entering:{submode})
"    \<Plug>(submode-enter:{submode})
"
" MAP <Plug>(submode-before-entering:{submode}:with:{key-to-enter})
" \   {anything}
" noremap <Plug>(submode-before-entering:{submode})
" \       {tweaking 'timeout' and others}
" map <Plug>(submode-enter:{submode})
" \   <Plug>(submode-before-action:{submode})
"    \<Plug>(submode-prefix:{submode})
"
" map <Plug>(submode-prefix:{submode})
" \   <Plug>(submode-leave:{submode})
" map <Plug>(submode-prefix:{submode}){the first N keys in {lhs}}
" \   <Plug>(submode-leave:{submode})
" map <Plug>(submode-prefix:{submode}){lhs}
" \   <Plug>(submode-rhs:{submode}:for:{lhs})
"    \<Plug>(submode-enter:{submode})
" MAP <Plug>(submode-rhs:{submode}:for:{lhs})
" \   {rhs}








" Variables  "{{{1

if !exists('g:submode_keep_leaving_key')
  let g:submode_keep_leaving_key = 0
endif

if !exists('g:submode_keyseqs_to_leave')
  let g:submode_keyseqs_to_leave = ['<Esc>']
endif

if !exists('g:submode_timeout')
  let g:submode_timeout = &timeout
endif

if !exists('g:submode_timeoutlen')
  let g:submode_timeoutlen = &timeoutlen
endif




"" See s:set_up_options() and s:restore_options().
"
" let s:original_showmode = &showmode
" let s:original_timeout = &timeout
" let s:original_timeoutlen = &timeoutlen
" let s:original_ttimeout = &ttimeout
" let s:original_ttimeoutlen = &ttimeoutlen

if !exists('s:options_overridden_p')
  let s:options_overridden_p = 0
endif








" Interface  "{{{1
" :SubmodeRestoreOptions  "{{{2

command! -bar -nargs=0 SubmodeRestoreOptions  call submode#restore_options()




function! submode#enter_with(submode, modes, options, lhs, ...)  "{{{2
  let rhs = 0 < a:0 ? a:1 : '<Nop>'
  for mode in s:each_char(a:modes)
    call s:define_entering_mapping(a:submode, mode, a:options, a:lhs, rhs)
  endfor
  return
endfunction




function! submode#leave_with(submode, modes, options, lhs)  "{{{2
  return submode#map(a:submode, a:modes, a:options . 'x', a:lhs, '<Nop>')
endfunction




function! submode#map(submode, modes, options, lhs, rhs)  "{{{2
  for mode in s:each_char(a:modes)
    call s:define_submode_mapping(a:submode, mode, a:options, a:lhs, a:rhs)
  endfor
  return
endfunction




function! submode#restore_options()  "{{{2
  call s:restore_options()
  return
endfunction




function! submode#unmap(submode, modes, options, lhs)  "{{{2
  for mode in s:each_char(a:modes)
    call s:undefine_submode_mapping(a:submode, mode, a:options, a:lhs)
  endfor
  return
endfunction








" Core  "{{{1
function! s:define_entering_mapping(submode, mode, options, lhs, rhs)  "{{{2
  execute s:map_command(a:mode, 'r')
  \       s:map_options(s:filter_flags(a:options, 'bu'))
  \       (a:lhs)
  \       (s:named_key_before_entering_with(a:submode, a:lhs)
  \        . s:named_key_before_entering(a:submode)
  \        . s:named_key_enter(a:submode))

  if !s:mapping_exists_p(s:named_key_enter(a:submode), a:mode)
    " When the given submode is not defined yet - define the default key
    " mappings to leave the submode.
    for keyseq in g:submode_keyseqs_to_leave
      call submode#leave_with(a:submode, a:mode, a:options, keyseq)
    endfor
  endif

  execute s:map_command(a:mode, s:filter_flags(a:options, 'r'))
  \       s:map_options(s:filter_flags(a:options, 'besu'))
  \       s:named_key_before_entering_with(a:submode, a:lhs)
  \       a:rhs
  execute s:map_command(a:mode, '')
  \       s:map_options('e')
  \       s:named_key_before_entering(a:submode)
  \       printf('<SID>on_entering_submode(%s)', string(a:submode))
  execute s:map_command(a:mode, 'r')
  \       s:map_options('')
  \       s:named_key_enter(a:submode)
  \       (s:named_key_before_action(a:submode)
  \        . s:named_key_prefix(a:submode))

  execute s:map_command(a:mode, '')
  \       s:map_options('e')
  \       s:named_key_before_action(a:submode)
  \       printf('<SID>on_executing_action(%s)', string(a:submode))
  execute s:map_command(a:mode, 'r')
  \       s:map_options('')
  \       s:named_key_prefix(a:submode)
  \       s:named_key_leave(a:submode)
  execute s:map_command(a:mode, '')
  \       s:map_options('')
  \       s:named_key_leave(a:submode)
  \       printf('%s<SID>on_leaving_submode(%s)<Return>',
  \              a:mode =~# '[ic]' ? '<C-r>=' : '@=',
  \              string(a:submode))

  return
endfunction




function! s:define_submode_mapping(submode, mode, options, lhs, rhs)  "{{{2
  execute s:map_command(a:mode, 'r')
  \       s:map_options(s:filter_flags(a:options, 'bu'))
  \       (s:named_key_prefix(a:submode) . a:lhs)
  \       (s:named_key_rhs(a:submode, a:lhs)
  \        . (s:has_flag_p(a:options, 'x')
  \           ? s:named_key_leave(a:submode)
  \           : s:named_key_enter(a:submode)))
  execute s:map_command(a:mode, s:filter_flags(a:options, 'r'))
  \       s:map_options(s:filter_flags(a:options, 'besu'))
  \       s:named_key_rhs(a:submode, a:lhs)
  \       a:rhs

  let keys = s:split_keys(a:lhs)
  for n in range(1, len(keys) - 1)
    let first_n_keys = join(keys[:-(n+1)], '')
    silent! execute s:map_command(a:mode, 'r')
    \               s:map_options(s:filter_flags(a:options, 'bu'))
    \               (s:named_key_prefix(a:submode) . first_n_keys)
    \               s:named_key_leave(a:submode)
  endfor

  return
endfunction




function! s:undefine_submode_mapping(submode, mode, options, lhs)  "{{{2
  execute s:map_command(a:mode, 'u')
  \       s:map_options(s:filter_flags(a:options, 'b'))
  \       s:named_key_rhs(a:submode, a:lhs)

  let keys = s:split_keys(a:lhs)
  for n in range(len(keys), 1, -1)
    let first_n_keys = join(keys[:n-1], '')
    execute s:map_command(a:mode, 'u')
    \       s:map_options(s:filter_flags(a:options, 'b'))
    \       s:named_key_prefix(a:submode) . first_n_keys
    if s:longer_mapping_exists_p(s:named_key_prefix(a:submode), first_n_keys)
      execute s:map_command(a:mode, 'r')
      \       s:map_options(s:filter_flags(a:options, 'b'))
      \       s:named_key_prefix(a:submode) . first_n_keys
      \       s:named_key_leave(a:submode)
      break
    endif
  endfor

  return
endfunction








" Misc.  "{{{1
function! s:each_char(s)  "{{{2
  return split(a:s, '.\zs')
endfunction




function! s:filter_flags(s, cs)  "{{{2
  return join(map(s:each_char(a:cs), 's:has_flag_p(a:s, v:val) ? v:val : ""'),
  \           '')
endfunction




function! s:has_flag_p(s, c)  "{{{2
  return 0 <= stridx(a:s, a:c)
endfunction




function! s:insert_mode_p(mode)  "{{{2
  return a:mode =~# '^[iR]'
endfunction




function! s:longer_mapping_exists_p(submode, lhs)  "{{{2
  " FIXME: Implement the proper calculation.
  "        Note that mapcheck() can't be used for this purpose because it may
  "        act as s:shorter_mapping_exists_p() if there is such a mapping.
  return !0
endfunction




function! s:map_command(mode, flags)  "{{{2
  if s:has_flag_p(a:flags, 'u')
    return a:mode . 'unmap'
  else
    return a:mode . (s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')
  endif
endfunction




function! s:map_options(options)  "{{{2
  let _ = {
  \   'b': '<buffer>',
  \   'e': '<expr>',
  \   's': '<silent>',
  \   'u': '<unique>',
  \ }
  return join(map(s:each_char(a:options), 'get(_, v:val, "")'))
endfunction




function! s:mapping_exists_p(keyseq, mode)  "{{{2
  return maparg(a:keyseq, a:mode) != ''
endfunction




function! s:may_override_showmode_p(mode)  "{{{2
  " Normal mode / Visual mode (& its variants) / Insert mode (& its variants)
  return a:mode =~# "^[nvV\<C-v>sS\<C-s>]" || s:insert_mode_p(a:mode)
endfunction




function! s:named_key_before_action(submode)  "{{{2
  return printf('<Plug>(submode-before-action:%s)', a:submode)
endfunction




function! s:named_key_before_entering(submode)  "{{{2
  return printf('<Plug>(submode-before-entering:%s)', a:submode)
endfunction




function! s:named_key_before_entering_with(submode, lhs)  "{{{2
  return printf('<Plug>(submode-before-entering:%s:with:%s)', a:submode, a:lhs)
endfunction




function! s:named_key_enter(submode)  "{{{2
  return printf('<Plug>(submode-enter:%s)', a:submode)
endfunction




function! s:named_key_leave(submode)  "{{{2
  return printf('<Plug>(submode-leave:%s)', a:submode)
endfunction




function! s:named_key_prefix(submode)  "{{{2
  return printf('<Plug>(submode-prefix:%s)', a:submode)
endfunction




function! s:named_key_rhs(submode, lhs)  "{{{2
  return printf('<Plug>(submode-rhs:%s:for:%s)', a:submode, a:lhs)
endfunction




function! s:on_entering_submode(submode)  "{{{2
  call s:set_up_options()
  return ''
endfunction




function! s:on_executing_action(submode)  "{{{2
  if s:original_showmode && s:may_override_showmode_p(mode())
    echohl ModeMsg
    echo '-- Submode:' a:submode '--'
    echohl None
  endif
  return ''
endfunction




function! s:on_leaving_submode(submode)  "{{{2
  if s:original_showmode && s:may_override_showmode_p(mode())
    if s:insert_mode_p(mode())
      let cussor_position = getpos('.')
    endif

      " BUGS: :redraw! doesn't redraw 'showmode'.
    execute "normal! \<C-l>"

    if s:insert_mode_p(mode())
      call setpos('.', cussor_position)
    endif
  endif
  if !g:submode_keep_leaving_key && getchar(1) isnot 0
    " To completely ignore unbound key sequences in a submode,
    " here we have to fetch and drop the last key in the key sequence.
    call getchar()
  endif
  call s:restore_options()
  return ''
endfunction




function! s:remove_flag(s, c)  "{{{2
  " Assumption: a:c is not a meta character.
  return substitute(a:s, a:c, '', 'g')
endfunction




function! s:restore_options()  "{{{2
  if !s:options_overridden_p
    return
  endif
  let s:options_overridden_p = 0

  let &showmode = s:original_showmode
  let &timeout = s:original_timeout
  let &timeoutlen = s:original_timeoutlen
  let &ttimeout = s:original_ttimeout
  let &ttimeoutlen = s:original_ttimeoutlen

  return
endfunction




function! s:set_up_options()  "{{{2
  if s:options_overridden_p
    return
  endif
  let s:options_overridden_p = !0

  let s:original_showmode = &showmode
  let s:original_timeout = &timeout
  let s:original_timeoutlen = &timeoutlen
  let s:original_ttimeout = &ttimeout
  let s:original_ttimeoutlen = &ttimeoutlen

  set noshowmode
  let &timeout = g:submode_timeout
  let &ttimeout = s:original_timeout ? !0 : s:original_ttimeout
  let &timeoutlen = g:submode_timeoutlen
  let &ttimeoutlen = s:original_ttimeoutlen < 0
  \                  ? s:original_timeoutlen
  \                  : s:original_ttimeoutlen

  return
endfunction




function! s:split_keys(keyseq)  "{{{2
  " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
  "             a:keyseq doesn't directly contain any escape sequences.
  return split(a:keyseq, '\(<[^<>]\+>\|.\)\zs')
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
