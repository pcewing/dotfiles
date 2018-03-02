" Add a visual indicator to the line the cursor is on.
function s:SetCursorLine()
  set cursorline
  hi CursorLine cterm=NONE ctermbg=black
endfunction
autocmd VimEnter * call s:SetCursorLine()

