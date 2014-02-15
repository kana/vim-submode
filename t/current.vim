call submode#enter_with('foo', 'n', '', 'sa')
call submode#enter_with('bar', 'n', '', 'sb')
call submode#enter_with('baz', 'n', '', 'sc')
call submode#map('foo', 'n', 'e', 'm', 'Stash()')
call submode#map('bar', 'n', 'e', 'm', 'Stash()')
call submode#map('baz', 'n', 'e', 'm', 'Stash()')

let g:submode = ''
function! Stash()
  let g:submode = submode#current()
  return ''
endfunction

describe 'submode#current'
  it 'returns an empty string if any submode is not active'
    Expect submode#current() ==# ''
  end

  it 'returns the name of the current submode'
    execute 'normal' "sa\<Esc>"
    Expect g:submode ==# ''

    execute 'normal' "sam\<Esc>"
    Expect g:submode ==# 'foo'

    execute 'normal' "sbm\<Esc>"
    Expect g:submode ==# 'bar'

    execute 'normal' "scm\<Esc>"
    Expect g:submode ==# 'baz'

    Expect submode#current() ==# ''
  end
end
