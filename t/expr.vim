function! Flip()
  let g:flipped = !g:flipped
  return g:flipped
endfunction
let g:flipped = 0

call submode#enter_with('expr', 'n', 'e', 'j', 'Flip() ? "k" : "j"')

describe '<expr> mapping in a submode'
  before
    new
    put =range(1, 30)
    1 delete _
  end

  after
    quit!
  end

  it 'works'
    normal! 10G
    Expect line('.') == 10

    normal j
    Expect line('.') == 9

    normal j
    Expect line('.') == 10

    normal j
    Expect line('.') == 9

    normal j
    Expect line('.') == 10
  end

  it 'is not applied to the default key mapping to leave a submode'
    normal! 10G

    let v:errmsg = ''
    execute 'normal' "j\<Esc>"
    Expect v:errmsg ==# ''
  end
end
