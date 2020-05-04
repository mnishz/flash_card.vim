" TODO
" * skip ŽÀ‘•
" * ³‰ð—¦‚ª’á‚¢‡‚Åo‘è‚·‚é

" s:idx_file
" s:idx
" s:cards

let s:idx_file = expand('%:p') .. '_flash_card'

if filereadable(s:idx_file)
  let s:file_contents = readfile(s:idx_file)
  let s:idx = s:file_contents[0]
  let s:cards = json_decode(s:file_contents[1])
  unlet s:file_contents
else
  let s:idx = 0
  let s:cards = []
  let s:contents = getline(1, '$')
  for idx in range(s:contents->len())
    if s:contents[idx][0] =~? '[a-z]' && idx+1 < s:contents->len()
      let s:cards += [#{en: s:contents[idx], jp: s:contents[idx+1], submit_count: 0, wrong_count: 0}]
    endif
  endfor
  unlet s:contents
endif

new flash_card
setlocal buftype=acwrite
" setlocal bufhidden=hide
setlocal noswapfile
setlocal spell spelllang=en_us
nnoremap <buffer> <space>c i<c-x>s

imap     <buffer> <silent> <cr> <esc><cr>
nnoremap <buffer> <silent> <cr> :call <SID>submit_answer()<cr>
command-buffer Accept call <SID>accept_answer()
command-buffer Check call <SID>check_answer()
command-buffer NextQ call <SID>move_to_next()
command-buffer PrevQ call <SID>move_to_prev()
command-buffer Show call <SID>show_answer()

augroup flash_card_save
  autocmd!
  autocmd BufWriteCmd <buffer> call writefile([s:idx, json_encode(s:cards)], s:idx_file)
  autocmd BufWriteCmd <buffer> setlocal nomodified
augroup END

function s:set_question() abort
  if !empty(getline(1)) | call deletebufline('%', 1, '$') | endif
  call setline(1, s:idx+1 .. '. ' .. s:cards[s:idx].jp)
  " call feedkeys('o')
endfunction

call s:set_question()

function s:submit_answer() abort
  let l:is_good = s:check_answer()
  let l:is_submitted = s:is_submitted()

  if !l:is_submitted
    call s:show_answer()
    " update counts
    let s:cards[s:idx].submit_count += 1
    if !l:is_good | let s:cards[s:idx].wrong_count += 1 | endif
  endif

  if l:is_good
    redraw
    if l:is_submitted
      " just wait a little
      sleep 500m
    else
      " wait for user feedback
      echo 'type enter'
      call getchar()
    endif
    call s:move_to_next()
  endif
endfunction

function s:check_answer() abort
  if substitute(s:cards[s:idx].en, '\W', '', 'g') ==? substitute(getline(2), '\W', '', 'g')
    call s:show_message('good')
    return v:true
  else
    call s:show_message('bad', 0, v:true)
    return v:false
  endif
endfunction

function s:is_submitted() abort
  return getbufinfo('%')[0].linecount > 2 && getline('$') ==# s:cards[s:idx].en
endfunction

function s:show_answer() abort
  if empty(getline(2)) | call setline(2, ['']) | endif
  call setline(3, ['', s:cards[s:idx].en])
endfunction

function s:move_to_next() abort
  let s:idx += 1
  if s:idx >= s:cards->len()
    let s:idx = 0
    call s:show_message('end of cards', 3)
  endif
  call s:set_question()
endfunction

function s:move_to_prev() abort
  let s:idx = (s:idx <= 0) ? s:cards->len()-1 : s:idx-1
  call s:set_question()
endfunction

function s:accept_answer() abort
  if s:is_submitted()
    let s:cards[s:idx].wrong_count -= 1
    call setline(2, s:cards[s:idx].en)
    call s:submit_answer()
  else
    echo 'not submitted'
  endif
endfunction

function s:show_message(msg, pos_off = 0, warning = v:false) abort
  call popup_create(a:msg, #{
        \ line: win_screenpos(win_getid())[0] + 5 + a:pos_off,
        \ col: 10,
        \ time: 1000,
        \ highlight: (a:warning ? 'WarningMsg' : 'Normal'),
        \ border: [],
        \ paddins: [0, 1, 0, 1],
        \ })
endfunction
