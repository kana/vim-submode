call submode#enter_with('boost', 'n', '', 'j', 'j')
call submode#enter_with('boost', 'n', '', 'k', 'k')
call submode#map('boost', 'n', '', 'j', 'jjj')
call submode#map('boost', 'n', '', 'k', 'kkk')

describe 'g:submode_keep_leaving_key'
  before
    new
    put =range(1, 30)
    1 delete _
  end

  after
    quit!
  end

  it 'does not keep a leaving key by default'
    Expect line('.') == 1

    normal ggj
    Expect line('.') == 2

    normal ggjj
    Expect line('.') == 5

    normal ggjjj
    Expect line('.') == 8

    normal ggjjjx
    Expect line('.') == 8
    Expect getline('.') ==# '8'
  end

  it 'does not keep a leaving key if g:submode_keep_leaving_key is false'
    let g:submode_keep_leaving_key = 0

    Expect line('.') == 1

    normal ggj
    Expect line('.') == 2

    normal ggjj
    Expect line('.') == 5

    normal ggjjj
    Expect line('.') == 8

    normal ggjjjx
    Expect line('.') == 8
    Expect getline('.') ==# '8'
  end

  it 'keeps a leaving key if g:submode_keep_leaving_key is true'
    let g:submode_keep_leaving_key = 1

    Expect line('.') == 1

    normal ggj
    Expect line('.') == 2

    normal ggjj
    Expect line('.') == 5

    normal ggjjj
    Expect line('.') == 8

    normal ggjjjx
    Expect line('.') == 8
    Expect getline('.') ==# ''
  end
end
