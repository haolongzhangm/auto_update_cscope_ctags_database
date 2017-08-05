" File: b/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags.vim
" Author: SeaflyDennis <seafly0616@qq.com>
" Date: 2017.08.05
" Last Modified Date: 2017.08.05
" Last Modified By: SeaflyDennis <seafly0616@qq.com>
"author : haolong.zhang@ck-telecom.com"
"v0.5: 20170426 init func"
"v1.0: 20170503 finish for multithreading for gen cscope and ctag database"
"v1.0.1: 20170512 fix v1.0 issue"
"v2.0  : 20170519 add command Manualupdatedatabaseonetime
"v2.0.1: 20170519 fix v2.0 issue
"v2.0.2: 20170524 fix v2.0 issue and optimize ctags args
"v2.0.3: 20170719 add more file type
"v2.0.4: 20170720 support python lib
"v2.0.5: 20170721 find issue fix, python file leave database logic
"v2.0.6: 20170724 type file issue fix, care_file_type * include
"v3.0:   20170727 support user config soft link file


" File: b/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags.vim
" Author: SeaflyDennis <seafly0616@qq.com>
" Date: 2017.08.05
" Last Modified Date: 2017.08.05
" Last Modified By: SeaflyDennis <seafly0616@qq.com>
" lookupfile.vim: See plugin/lookupfile.vim

" Make sure line-continuations won't cause any problem. This will be restored
"   at the end
let s:save_cpo = &cpo
set cpo&vim

" Some onetime initialization of variables
if !exists('s:myBufNum')
  let s:windowName = '[Lookup File]'
  let s:myBufNum = -1
  let s:popupIsHidden = 0
endif
let g:lookupfile#lastPattern = ""
let g:lookupfile#lastResults = []
let g:lookupfile#lastStatsMsg = []
let g:lookupfile#recentFiles = []

function! lookupfile#OpenWindow(bang, initPat)
  let origWinnr = winnr()
  let _isf = &isfname
  let _splitbelow = &splitbelow
  set nosplitbelow
  try
    if s:myBufNum == -1
      " Temporarily modify isfname to avoid treating the name as a pattern.
      set isfname-=\
      set isfname-=[
      if exists('+shellslash')
        call genutils#OpenWinNoEa("1sp \\\\". escape(s:windowName, ' '))
      else
        call genutils#OpenWinNoEa("1sp \\". escape(s:windowName, ' '))
      endif
      let s:myBufNum = bufnr('%')
    else
      let winnr = bufwinnr(s:myBufNum)
      if winnr == -1
        call genutils#OpenWinNoEa('1sb '. s:myBufNum)
      else
        let wasVisible = 1
        exec winnr 'wincmd w'
      endif
    endif
  finally
    let &isfname = _isf
    let &splitbelow = _splitbelow
  endtry

  call s:SetupBuf()
  let initPat = ''
  if a:bang != ''
    let initPat = ''
  elseif a:initPat != ''
    let initPat = a:initPat
  elseif g:lookupfile#lastPattern != '' && g:LookupFile_PreserveLastPattern
    let initPat = g:lookupfile#lastPattern
  endif
  $
  if getline('.') !=# initPat
    silent! put=''
    call setline('.', initPat)
  endif
  startinsert!
  if !g:LookupFile_OnCursorMovedI
    " This is a hack to bring up the popup immediately, while reopening the
    " window, just for a better response.
    aug LookupFileCursorHoldImm
      au!
      au CursorMovedI <buffer> nested exec 'doautocmd LookupFile CursorHoldI' |
            \ au! LookupFileCursorHoldImm
    aug END
  endif
  call s:LookupFileSet()
  aug LookupFileReset
    au!
    au CursorMovedI <buffer> call <SID>LookupFileSet()
    au CursorMoved <buffer> call <SID>LookupFileSet()
    au WinEnter <buffer> call <SID>LookupFileSet()
    au TabEnter <buffer> call <SID>LookupFileSet()
    au WinEnter * call <SID>LookupFileReset(0)
    au TabEnter * call <SID>LookupFileReset(0)
    au CursorMoved * call <SID>LookupFileReset(0)
    " Better be safe than sorry.
    au BufHidden <buffer> call <SID>LookupFileReset(1)
  aug END
endfunction

function! lookupfile#CloseWindow()
  if bufnr('%') != s:myBufNum
    return
  endif

  call s:LookupFileReset(1)
  close
endfunction

function! lookupfile#ClearCache()
  let g:lookupfile#lastPattern = ""
  let g:lookupfile#lastResults = []
endfunction

function! s:LookupFileSet()
  if bufnr('%') != s:myBufNum || exists('s:_backspace')
    return
  endif
  let s:_backspace = &backspace
  set backspace=start
  let s:_completeopt = &completeopt
  set completeopt+=menuone
  let s:_updatetime = &updatetime
  let &updatetime = g:LookupFile_UpdateTime
endfunction

function! s:LookupFileReset(force)
  if a:force
    aug LookupFileReset
      au!
    aug END
  endif
  " Ignore the event while in the same buffer.
  if exists('s:_backspace') && (a:force || (bufnr('%') != s:myBufNum))
    let &backspace = s:_backspace
    let &completeopt = s:_completeopt
    let &updatetime = s:_updatetime
    unlet s:_backspace s:_completeopt s:_updatetime
  endif
endfunction

function! s:HidePopup()
  let s:popupIsHidden = 1
  return "\<C-E>"
endfunction

function! lookupfile#IsPopupHidden()
  return s:popupIsHidden
endfunction

function! s:SetupBuf()
  call genutils#SetupScratchBuffer()
  resize 1
  setlocal wrap
  setlocal bufhidden=hide
  setlocal winfixheight
  setlocal wrapmargin=0
  setlocal textwidth=0
  setlocal completefunc=lookupfile#Complete
  syn clear
  set ft=lookupfile
  " Setup maps to open the file.
  inoremap <silent> <buffer> <expr> <C-E> <SID>HidePopup()
  inoremap <silent> <buffer> <expr> <CR> <SID>AcceptFile(0, "\<CR>")
  inoremap <silent> <buffer> <expr> <C-O> <SID>AcceptFile(1, "\<C-O>")
  " This prevents the "Whole line completion" from getting triggered with <BS>,
  " however this might make the dropdown kind of flash.
  inoremap <buffer> <expr> <BS>       pumvisible()?"\<C-E>\<BS>":"\<BS>"
  inoremap <buffer> <expr> <S-BS>       pumvisible()?"\<C-E>\<BS>":"\<BS>"
  " Make <C-Y> behave just like <CR>
  imap     <buffer> <C-Y>      <CR>
  if g:LookupFile_EscCancelsPopup
    inoremap <buffer> <expr> <Esc>      pumvisible()?"\<C-E>\<C-C>":"\<Esc>"
  endif
  inoremap <buffer> <expr> <silent> <Down> <SID>GetCommand(1, 1, "\<C-N>",
        \ "\"\\<Lt>C-N>\"")
  inoremap <buffer> <expr> <silent> <Up> <SID>GetCommand(1, 1, "\<C-P>",
        \ "\"\\<Lt>C-P>\"")
  inoremap <buffer> <expr> <silent> <PageDown> <SID>GetCommand(1, 0,
        \ "\<PageDown>", '')
  inoremap <buffer> <expr> <silent> <PageUp> <SID>GetCommand(1, 0,
        \ "\<PageUp>", '')
  nnoremap <silent> <buffer> o :OpenFile<CR>
  nnoremap <silent> <buffer> O :OpenFile!<CR>
  command! -buffer -nargs=0 -bang OpenFile
        \ :call <SID>OpenCurFile('<bang>' != '')
  command! -buffer -nargs=0 -bang AddPattern :call <SID>AddPattern()
  nnoremap <buffer> <silent> <Plug>LookupFile :call lookupfile#CloseWindow()<CR>
  inoremap <buffer> <silent> <Plug>LookupFile <C-E><C-C>:call lookupfile#CloseWindow()<CR>

  aug LookupFile
    au!
    if g:LookupFile_ShowFiller
      exec 'au' (g:LookupFile_OnCursorMovedI ? 'CursorMovedI' : 'CursorHoldI')
            \ '<buffer> call <SID>ShowFiller()'
    endif
    exec 'au' (g:LookupFile_OnCursorMovedI ? 'CursorMovedI' : 'CursorHoldI')
          \ '<buffer> call lookupfile#LookupFile(0)'
  aug END
endfunction

function! s:GetCommand(withPopupTrigger, withSkipPat, actCmd, innerCmd)
  let cmd = ''
  if a:withPopupTrigger && !pumvisible()
    let cmd .= "\<C-X>\<C-U>"
  endif
  let cmd .= a:actCmd. "\<C-R>=(getline('.') == lookupfile#lastPattern) ? ".
        \ a:innerCmd." : ''\<CR>"
  return cmd
endfunction

function! s:AddPattern()
  if g:LookupFile_PreservePatternHistory
    silent! put! =g:lookupfile#lastPattern
    $
  endif
endfunction

function! s:AcceptFile(splitWin, key)
  if s:popupIsHidden
    return a:key
  endif
  if !pumvisible()
    call lookupfile#LookupFile(0, 1)
  endif
  let acceptCmd = ''
  if type(g:LookupFile_LookupAcceptFunc) == 2 ||
        \ (type(g:LookupFile_LookupAcceptFunc) == 1 &&
        \  substitute(g:LookupFile_LookupAcceptFunc, '\s', '', 'g') != '')
    let acceptCmd = call(g:LookupFile_LookupAcceptFunc, [a:splitWin, a:key])
  else
    let acceptCmd = lookupfile#AcceptFile(a:splitWin, a:key)
  endif

  return (!pumvisible() ? "\<C-X>\<C-U>" : '').acceptCmd
endfunction

function! s:IsValid(fileName)
  if bufnr('%') != s:myBufNum || a:fileName == ''
    return 0
  endif
  if !filereadable(a:fileName) && !isdirectory(a:fileName)
    if g:LookupFile_AllowNewFiles
      " Check if the parent directory exists, then we can create a new buffer
      " (Ido feature)
      let parent = fnamemodify(a:fileName, ':h')
      if parent == '' || (parent != '' && !isdirectory(parent))
        return 1
      endif
    endif
    return 0
  endif
  return 1
endfunction

function! lookupfile#AcceptFile(splitWin, key)
  if len(g:lookupfile#lastResults) == 0 && !s:IsValid(getline('.'))
    return "\<C-O>:echohl ErrorMsg | echo 'No such file or directory' | echohl NONE\<CR>"
  endif

  " Skip the first match, which is essentially the same as pattern.
  let nextCmd = "\<C-N>\<C-R>=(getline('.') == lookupfile#lastPattern)?\"\\<C-N>\":''\<CR>"
  let acceptCmd = "\<C-Y>\<Esc>:AddPattern\<CR>:OpenFile".(a:splitWin?'!':'').
        \ "\<CR>"
  if getline('.') ==# g:lookupfile#lastPattern
    if len(g:lookupfile#lastResults) == 0
      " FIXME: shouldn't this be an error?
      let acceptCmd = acceptCmd
    elseif len(g:lookupfile#lastResults) == 1 || g:LookupFile_AlwaysAcceptFirst
      " If there is only one file, we will also select it (if not already
      " selected)
      let acceptCmd = nextCmd.acceptCmd
    else
      let acceptCmd = nextCmd
    endif
  endif

  return acceptCmd
endfunction

function! s:OpenCurFile(splitWin)
  let fileName = getline('.')
  if fileName =~ '^\s*$'
    return
  endif
  if !s:IsValid(fileName)
    echohl ErrorMsg | echo 'No such file or directory' | echohl NONE
  endif

  if type(g:LookupFile_LookupNotifyFunc) == 2 ||
        \ (type(g:LookupFile_LookupNotifyFunc) == 1 &&
        \  substitute(g:LookupFile_LookupNotifyFunc, '\s', '', 'g') != '')
    call call(g:LookupFile_LookupNotifyFunc, [])
  endif
  call lookupfile#CloseWindow()

  " Update the recent files list.
  if g:LookupFile_RecentFileListSize > 0
    let curPos = index(g:lookupfile#recentFiles, fileName)
    call add(g:lookupfile#recentFiles, fileName)
    if curPos != -1
      call remove(g:lookupfile#recentFiles, curPos)
    elseif len(g:lookupfile#recentFiles) > g:LookupFile_RecentFileListSize
      let g:lookupfile#recentFiles = g:lookupfile#recentFiles[
            \ -g:LookupFile_RecentFileListSize :]
    endif
  endif

  let bufnr = genutils#FindBufferForName(fileName)
  let winnr = bufwinnr(bufnr)
  if winnr == -1 && g:LookupFile_SearchForBufsInTabs
      for i in range(tabpagenr('$'))
        if index(tabpagebuflist(i+1), bufnr) != -1
          " Switch to the tab and set winnr.
          exec 'tabnext' (i+1)
          let winnr = bufwinnr(bufnr)
        endif
    endfor
  endif
  if winnr != -1
    exec winnr.'wincmd w'
  else
    let splitOpen = 0
    if &switchbuf ==# 'split' || a:splitWin
      let splitOpen = 1
    endif
    " First try opening as a buffer, if it fails, we will open as a file.
    try
      if bufnr == -1
        throw ''
      endif
      exec (splitOpen?'s':'').'buffer' bufnr
    catch /^Vim\%((\a\+)\)\=:E325/
      " Ignore, this anyway means the file was found.
    catch
      try
        exec (splitOpen?'split':'edit') fileName
      catch /^Vim\%((\a\+)\)\=:E325/
        " Ignore, this anyway means the file was found.
      endtry
    endtry
  endif
endfunction

function! s:ShowFiller()
  return lookupfile#LookupFile(1)
endfunction

function! lookupfile#Complete(findstart, base)
  if a:findstart
    return 0
  else
    call lookupfile#LookupFile(0, 1, a:base)
    return g:lookupfile#lastStatsMsg+g:lookupfile#lastResults
  endif
endfunction

function! lookupfile#LookupFile(showingFiller, ...)
  let generateMode = (a:0 == 0 ? 0 : a:1)
  if generateMode
    let pattern = (a:0 > 1) ? a:2 : getline('.')
  else
    let pattern = getline('.')
    " The normal completion behavior is to stop completion when cursor is moved.
    if col('.') == 1 || (col('.') != col('$'))
      return ''
    endif
  endif
  if pattern == '' || (pattern ==# g:lookupfile#lastPattern && pumvisible())
    return ''
  endif

  if s:popupIsHidden && g:lookupfile#lastPattern ==# pattern
    return ''
  endif
  let s:popupIsHidden = 0

  let statusMsg = ''
  if pattern == ' '
    if len(g:lookupfile#recentFiles) == 0
      let statusMsg = '<<< No recent files >>>'
      let files = []
    else
      let statusMsg = '<<< Showing '.len(g:lookupfile#recentFiles).' recent files >>>'
      let files = reverse(copy(g:lookupfile#recentFiles))
    endif
  elseif strlen(pattern) < g:LookupFile_MinPatLength
    let statusMsg = '<<< Type at least '.g:LookupFile_MinPatLength.
          \ ' characters >>>'
    let files = []
  " We ignore filler when we have the result in hand.
  elseif g:lookupfile#lastPattern ==# pattern
    " This helps at every startup as we start with the previous pattern.
    let files = g:lookupfile#lastResults
  elseif a:showingFiller
    " Just show a filler and return. We could return this as the only match, but
    " unless 'completeopt' has "menuone", menu doesn't get shown.
    let statusMsg = '<<< Looking up files... hit ^C to break >>>'
    let files = []
  else
    if type(g:LookupFile_LookupFunc) == 2 ||
          \ (type(g:LookupFile_LookupFunc) == 1 &&
          \  substitute(g:LookupFile_LookupFunc, '\s', '', 'g') != '')
      let files = call(g:LookupFile_LookupFunc, [pattern])
    else
      let _tags = &tags
      try
        let &tags = eval(g:LookupFile_TagExpr)
        let taglist = taglist(g:LookupFile_TagsExpandCamelCase ?
              \ lookupfile#ExpandCamelCase(pattern) : pattern)
      catch
        echohl ErrorMsg | echo "Exception: " . v:exception | echohl NONE
        return ''
      finally
        let &tags = _tags
      endtry

      " Show the matches for what is typed so far.
      if g:LookupFile_UsingSpecializedTags
        let files = map(taglist, '{'.
              \ '"word": fnamemodify(v:val["filename"], ":p"), '.
              \ '"abbr": v:val["name"], '.
              \ '"menu": fnamemodify(v:val["filename"], ":h"), '.
              \ '"dup": 1, '.
              \ '}')
      else
        let files = map(taglist, 'fnamemodify(v:val["filename"], ":p")')
      endif
    endif

    let pat = g:LookupFile_FileFilter
    if pat != ''
      call filter(files, '(type(v:val) == 4) ? v:val["word"] !~ pat : v:val !~ pat')
    endif

    if g:LookupFile_SortMethod ==# 'alpha'
      " When UsingSpecializedTags, sort by the actual name (Timothy, Guo
      " (firemeteor dot guo at gmail dot com)).
      if type(get(files, 0)) == 4
        call sort(files, "s:CmpByName")
      else
        call sort(files)
      endif
    endif
    let g:lookupfile#lastPattern = pattern
    let g:lookupfile#lastResults = files
  endif
  if statusMsg == ''
    if len(files) > 0
      let statusMsg = '<<< '.len(files).' Matching >>>'
    else
      let statusMsg = '<<< None Matching >>>'
    endif
  endif
  let msgLine = [{'word': pattern, 'abbr': statusMsg, 'menu': pattern}]
  let g:lookupfile#lastStatsMsg = msgLine
  if !generateMode
    call complete(1, msgLine+files)
  endif
  return ''
endfunction

function! lookupfile#ExpandCamelCase(str)
  let pat = a:str
  " Check if there are at least two consecutive uppercase letters to turn on
  " the CamelCase expansion.
  if match(a:str, '\u\u') != -1
    let pat = '\C'.substitute(a:str, '\u\+',
          \ '\=substitute(submatch(0), ".", '."'".'&\\U*'."'".', "g")', 'g')
    let @*=pat
  endif
  return pat
endfunction

function! s:CmpByName(i1, i2)
  let ileft = a:i1["abbr"]
  let iright = a:i2["abbr"]
  return ileft == iright ? 0 : ileft > iright ? 1 : -1
endfunc

" Restore cpo.
let &cpo = s:save_cpo
unlet s:save_cpo

" vim6:fdm=marker et sw=2

" File: b/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags.vim
" Author: abc <123>
" Date: 2017.08.05
" Last Modified Date: 2017.08.05
" Last Modified By: SeaflyDennis <seafly0616@qq.com>
" lookupfile.vim: Lookup filenames by pattern
" Author: Hari Krishna Dara (hari.vim at gmail dot com)
" Last Change: 14-Jun-2007 @ 18:30
" Created:     11-May-2006
" Requires:    Vim-7.1, genutils.vim(2.3)
" Version:     1.8.0
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt 
" Download From:
"     http://www.vim.org//script.php?script_id=1581
" Usage:
"     See :help lookupfile.txt

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"LookupFile: b/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags.vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

" Shortcuts using <leader>
map <leader>sn ]s
map <leader>sp [s
map <leader>sa zg
map <leader>s? z=

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"LookupFile: b/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags.vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! CmdLine(str)
    exe "menu Foo.Bar :" . a:str
    emenu Foo.Bar
    unmenu Foo
endfunction

function! VisualSelection(direction) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", '\\/.*$^~[]')
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'b'
        execute "normal ?" . l:pattern . "^M"
    elseif a:direction == 'gv'
        call CmdLine("vimgrep " . '/'. l:pattern . '/' . ' **/*.')
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    elseif a:direction == 'f'
        execute "normal /" . l:pattern . "^M"
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction


" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    en
    return ''
endfunction

" Don't close window, when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
   let l:currentBufNum = bufnr("%")
   let l:alternateBufNum = bufnr("#")

   if buflisted(l:alternateBufNum)
     buffer #
   else
     bnext
   endif

   if bufnr("%") == l:currentBufNum
     new
   endif

   if buflisted(l:currentBufNum)
     execute("bdelete! ".l:currentBufNum)
   endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"LookupFile: b/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:myLookupFileTagExpr = './filenametags'
let g:LookupFile_TagExpr = 'g:myLookupFileTagExpr'
let g:LookupFile_MinPatLength = 1               "at least 1 character power find
let g:LookupFile_PreserveLastPattern = 0        "don't save last pattern
let g:LookupFile_PreservePatternHistory = 1     "save find history
let g:LookupFile_AlwaysAcceptFirst = 1          "<Enter> open first match item
let g:LookupFile_AllowNewFiles = 0              "Don't allow create no-exist file
let g:LookupFile_RecentFileListSize = 30
let g:LookupFile_FileFilter = '\.class$\|\.o$\|\.obj$\|\.exe$\|\.jar$\|\.zip$\|\.war$\|\.ear$'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"LookupFile: b/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! LookupFile_IgnoreCaseFunc(pattern)
    let _tags = &tags
    try
        let &tags = eval(g:LookupFile_TagExpr)
        let newpattern = '\c' . a:pattern
        let tags = taglist(newpattern)
    catch
        echohl ErrorMsg | echo "Exception: " . v:exception | echohl NONE
        return ""
    finally
        let &tags = _tags
    endtry

    "show the matches for what is typed so far.
    let files = map(tags, 'v:val["filename"]')
    return files
endfunction
let g:LookupFile_LookupFunc = 'LookupFile_IgnoreCaseFunc'


if exists('loaded_lookupfile')
  finish
endif
if v:version < 701
  echomsg 'lookupfile: You need at least Vim 7.1'
  finish
endif
if !exists('loaded_genutils')
  runtime plugin/genutils.vim
endif
if !exists('loaded_genutils') || loaded_genutils < 203
  echomsg 'lookupfile: You need a newer version of genutils.vim plugin'
  finish
endif

let g:loaded_lookupfile = 108

" Make sure line-continuations won't cause any problem. This will be restored
"   at the end
let s:save_cpo = &cpo
set cpo&vim

if !exists('g:LookupFile_TagExpr')
  let g:LookupFile_TagExpr = '&tags'
endif

if !exists('g:LookupFile_LookupFunc')
  let g:LookupFile_LookupFunc = ''
endif

if !exists('g:LookupFile_LookupNotifyFunc')
  let g:LookupFile_LookupNotifyFunc = ''
endif

if !exists('g:LookupFile_LookupAcceptFunc')
  let g:LookupFile_LookupAcceptFunc = ''
endif

if !exists('g:LookupFile_MinPatLength')
  let g:LookupFile_MinPatLength = 4
endif

if !exists('g:LookupFile_PreservePatternHistory')
  let g:LookupFile_PreservePatternHistory = 1
endif

if !exists('g:LookupFile_PreserveLastPattern')
  let g:LookupFile_PreserveLastPattern = 1
endif

if !exists('g:LookupFile_ShowFiller')
  let g:LookupFile_ShowFiller = 1
endif

if !exists('g:LookupFile_AlwaysAcceptFirst')
  let g:LookupFile_AlwaysAcceptFirst = 0
endif

if !exists('g:LookupFile_FileFilter')
  let g:LookupFile_FileFilter = ''
endif

if !exists('g:LookupFile_AllowNewFiles')
  let g:LookupFile_AllowNewFiles = 1
endif

if !exists('g:LookupFile_SortMethod')
  let g:LookupFile_SortMethod = 'alpha'
endif

if !exists('g:LookupFile_Bufs_BufListExpr')
  let g:LookupFile_Bufs_BufListExpr = ''
endif

if !exists('g:LookupFile_Bufs_SkipUnlisted')
  let g:LookupFile_Bufs_SkipUnlisted = 1
endif

if !exists('g:LookupFile_Bufs_LikeBufCmd')
  let g:LookupFile_Bufs_LikeBufCmd = 1
endif

if !exists('g:LookupFile_UsingSpecializedTags')
  let g:LookupFile_UsingSpecializedTags = 0
endif

if !exists('g:LookupFile_DefaultCmd')
  let g:LookupFile_DefaultCmd = ':LUTags'
endif

if !exists('g:LookupFile_EnableRemapCmd')
  let g:LookupFile_EnableRemapCmd = 1
endif

if !exists('g:LookupFile_DisableDefaultMap')
  let g:LookupFile_DisableDefaultMap = 0
endif

if !exists('g:LookupFile_UpdateTime')
  let g:LookupFile_UpdateTime = 300
endif

if !exists('g:LookupFile_OnCursorMovedI')
  let g:LookupFile_OnCursorMovedI = 0
endif

if !exists('g:LookupFile_EscCancelsPopup')
  let g:LookupFile_EscCancelsPopup = 1
endif

if !exists('g:LookupFile_SearchForBufsInTabs')
  let g:LookupFile_SearchForBufsInTabs = 1
endif

if !exists('g:LookupFile_TagsExpandCamelCase')
  let g:LookupFile_TagsExpandCamelCase = 1
endif

if !exists('g:LookupFile_RecentFileListSize')
  let g:LookupFile_RecentFileListSize = 20
endif

if (! exists("no_plugin_maps") || ! no_plugin_maps) &&
      \ (! exists("no_lookupfile_maps") || ! no_lookupfile_maps)
  noremap <script> <silent> <Plug>LookupFile :LookupFile<CR>

  if ! g:LookupFile_DisableDefaultMap
    if !hasmapto('<Plug>LookupFile', 'n')
      nmap <unique> <silent> <F5> <Plug>LookupFile
    endif
    if !hasmapto('<Plug>LookupFile', 'i')
      inoremap <Plug>LookupFileCE <C-E>
      imap <unique> <expr> <silent> <F5> (pumvisible() ? "\<Plug>LookupFileCE" :
            \ "")."\<Esc>\<Plug>LookupFile"
    endif
  endif
endif

command! -nargs=? -bang -complete=file LookupFile :call
      \ <SID>LookupUsing('lookupfile', "<bang>", <q-args>, 0)

command! -nargs=? -bang -complete=tag LUTags :call
      \ <SID>LookupUsing('Tags', "<bang>", <q-args>, 0)
command! -nargs=? -bang -complete=file LUPath :call
      \ <SID>LookupUsing('Path', "<bang>", <q-args>, g:LookupFile_MinPatLength)
command! -nargs=? -bang -complete=file LUArgs :call
      \ <SID>LookupUsing('Args', "<bang>", <q-args>, 0)
command! -nargs=? -bang -complete=file LUBufs :call
      \ <SID>LookupUsing('Bufs', "<bang>", <q-args>, 0)
command! -nargs=? -bang -complete=dir LUWalk :call
      \ <SID>LookupUsing('Walk', "<bang>", <q-args>, 0)

function! s:RemapLookupFile(cmd)
  let cmd = (a:cmd != '') ? a:cmd : ':LUTags'
  " It is not straight-forward to determine the right completion method.
  exec 'command! -nargs=? -bang -complete=file LookupFile' cmd
endfunction
call s:RemapLookupFile(g:LookupFile_DefaultCmd)

let s:mySNR = ''
function! s:SNR()
  if s:mySNR == ''
    let s:mySNR = matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
  endif
  return s:mySNR
endfun

let s:baseBufNr = 0
function! s:LookupUsing(ftr, bang, initPat, minPatLen)
  let cmd = ':LUTags'
  if a:ftr != 'Tags'
    call s:SaveSett('LookupFunc')
    call s:SaveSett('LookupNotifyFunc')
    call s:SaveSett('MinPatLength')
    unlet! g:LookupFile_LookupFunc g:LookupFile_LookupNotifyFunc
    let g:LookupFile_LookupFunc = function(s:SNR().'Lookup'.a:ftr)
    let g:LookupFile_LookupNotifyFunc = function(s:SNR().'LookupReset')
    let g:LookupFile_MinPatLength = a:minPatLen
    let s:baseBufNr = bufnr('%')
    let cmd = ':LU'.a:ftr
  endif
  if g:LookupFile_EnableRemapCmd
    call s:RemapLookupFile(cmd)
  endif
  call lookupfile#OpenWindow(a:bang, a:initPat)

  if exists('*s:Config'.a:ftr)
    call s:Config{a:ftr}()
  endif

  aug LookupReset
    au!
    au BufHidden <buffer> call <SID>LookupReset()
  aug END
endfunction

function! s:LookupReset()
  if exists('s:saved')
    for sett in keys(s:saved)
      unlet! g:LookupFile_{sett}
      let g:LookupFile_{sett} = s:saved[sett]
    endfor
    unlet s:saved
  endif
  if exists('s:cleanup')
    for cmd in s:cleanup
      try
        exec cmd
      catch
        echoerr v:exception . ', while executing cleanup command: ' . cmd
      endtry
    endfor
    unlet s:cleanup
  endif
  aug ConfigIdo
    au!
  aug END
endfunction

function! s:SaveSett(sett)
  if !exists('s:saved')
    let s:saved = {}
  endif
  " Avoid overwriting the original value.
  if !has_key(s:saved, a:sett)
    let s:saved[a:sett] = g:LookupFile_{a:sett}
  endif
endfunction

function! s:AddCleanup(cmd)
  if !exists('s:cleanup')
    let s:cleanup = []
  endif
  if index(s:cleanup, a:cmd) == -1
    call add(s:cleanup, a:cmd)
  endif
endfunction

function! s:LookupPath(pattern)
  let filePat = a:pattern
  let matchingExactCase = s:MatchingExactCase(filePat)
  " Remove leading or trailing '*'s as we add a star anyway. This also removes
  " '**' unless it is followed by a slash.
  let filePat = substitute(filePat, '^\*\+\|\*\+$', '', 'g')
  " On windows, the case is anyway ignored.
  if !genutils#OnMS() && !matchingExactCase
    let filePat = s:FilePatIgnoreCase(filePat)
  endif
  let fl = split(globpath(&path, (filePat != '') ? '*'.filePat.'*' : '*'),
        \ "\n")
  let regexPat = s:TranslateFileRegex(filePat)
  " This is a psuedo case-sensitive match for windows, when 'smartcase' is
  " set.
  if genutils#OnMS() && matchingExactCase
    set verbose=15
    call filter(fl, 'v:val =~# regexPat')
    set verbose=0
  endif
  return map(fl,
        \ '{'.
        \ ' "word": v:val,'.
        \ ' "abbr": fnamemodify(v:val, ":t"), '.
        \ ' "menu": fnamemodify(v:val, ":h"), '.
        \ ' "dup": 1'.
        \ '}')
endfunction

function! s:LookupArgs(pattern)
  return map(filter(argv(), 'v:val =~ a:pattern'),
        \ '{'.
        \ ' "word":fnamemodify(v:val, ":p"), '.
        \ ' "abbr": v:val, '.
        \ ' "menu": substitute(v:val, a:pattern, "[&]", ""), '.
        \ ' "dup": 1'.
        \ '}')
endfunction

let s:bufList = [1]
function! s:LookupBufs(pattern)
  let results = []

  if g:LookupFile_Bufs_BufListExpr != ''
    let buflist = eval(g:LookupFile_Bufs_BufListExpr)
  else
    " Since we need to generate the same range again and again, it is better to
    " cache the list.
    if s:bufList[-1] != bufnr('$')
      call extend(s:bufList, range(s:bufList[-1], bufnr('$')))
    endif
    let buflist = s:bufList
  endif
  let lastBufNr = bufnr('$')
  let i = 1
  if g:LookupFile_Bufs_LikeBufCmd
    let pattern = s:TranslateFileRegex(a:pattern)
  else
    let pattern = a:pattern
  endif
  for bufNr in buflist
    if ! bufexists(bufNr)
      call remove(buflist, i)
      continue
    endif
    try
      if g:LookupFile_Bufs_SkipUnlisted && ! buflisted(bufNr)
        continue
      endif
      let fname = expand('#'.bufNr.':p')
      if g:LookupFile_Bufs_LikeBufCmd
        let bname = bufname(bufNr)
        let dir = ''
      else
        let bname = fnamemodify(bufname(bufNr), ':t')
        let dir = fnamemodify(bufname(bufNr), ':h').'/'
      endif
      if bname =~ pattern
        call add(results, {
              \ 'word': fname,
              \ 'abbr': bname,
              \ 'menu': dir.substitute(bname, pattern, '[&]', ''),
              \ 'dup': 1,
              \ })
      endif
    finally
      let i = i + 1
    endtry
  endfor
  return results
endfunction

function! s:LookupWalk(pattern)
  " We will wait till '/' is typed
  if a:pattern =~ '\*\*$'
    return []
  endif
  let showOnlyDirs = 0
  " Determine the parent dir.
  if a:pattern =~ '//$'
    let parent = strpart(a:pattern, 0, strlen(a:pattern)-1)
    let filePat = ''
    if parent ==# g:lookupfile#lastPattern
      return filter(g:lookupfile#lastResults, 'v:val["kind"] == "/"')
    endif
    let showOnlyDirs = 1
  else
    let parent = matchstr(a:pattern, '^.*/')
    let filePat = strpart(a:pattern, len(parent))
  endif

  let matchingExactCase = s:MatchingExactCase(filePat)

  " Remove leading or trailing '*'s as we add a star anyway. This also makes
  " '**' as '', but we rule this case out already.
  let filePat = substitute(filePat, '^\*\+\|\*\+$', '', 'g')
  " On windows, the case is anyway ignored.
  if !genutils#OnMS() && !matchingExactCase
    let filePat = s:FilePatIgnoreCase(filePat)
  endif
  "exec BPBreak(1)
  let _shellslash = &shellslash
  set shellslash
  try
    let files = glob(parent.((filePat != '') ? '*'.filePat.'*' : '*'))
  catch
    " Ignore errors in patterns.
    let files = ''
  finally
    let &shellslash = _shellslash
  endtry
  let fl = split(files, "\<NL>")
  let regexPat = s:TranslateFileRegex(filePat)
  " This is a psuedo case-sensitive match for windows, when 'smartcase' is
  " set.
  if genutils#OnMS() && matchingExactCase
    call filter(fl, 'fnamemodify(v:val, ":t") =~# regexPat')
  endif
  " Find the start of path component that uses any of the *, [], ? or {
  " wildcard. Path until this is unambiguously common to all, so we can strip
  " it off, for brevity.
  let firstWildIdx = match(a:pattern, '[^/]*\%(\*\|\[\|?\|{\)')
  return s:FormatFileResults(fl, firstWildIdx!=-1 ? firstWildIdx :
        \ strlen(parent), regexPat, matchingExactCase, showOnlyDirs)
endfunction

function! s:FormatFileResults(fl, parentLen, matchPat, matchingCase, dirsOnly)
  let entries = []
  for f in a:fl
    if isdirectory(f)
      let suffx = '/'
    else
      if a:dirsOnly
        continue
      endif
      let suffx = ''
    endif
    let word = f.suffx
    let fname = matchstr(f, '[^/]*$')
    let dir = fnamemodify(f, ':h').'/'
    if dir != '/' && a:parentLen != -1
      let dir = strpart(dir, a:parentLen)
    else
      let dir = ''
    endif
    "let dir = (dir == '/'?'':dir)
    call add(entries, {
          \ 'word': word,
          \ 'abbr': fname.suffx,
          \ 'menu': (a:matchPat!='') ? dir.substitute(fname,
          \   (a:matchingCase?'\C':'\c').a:matchPat, '[&]', '') :
          \    dir.fname,
          \ 'kind': suffx,
          \ 'dup': 1
          \ })
  endfor
  return entries
endfunction

function! s:ConfigBufs()
  " Allow switching to file mode.
  inoremap <expr> <buffer> <C-F> <SID>IdoSwitchTo('file')
  call s:AddCleanup('iunmap <buffer> <C-F>')
  if g:LookupFile_Bufs_BufListExpr != ''
    call s:SaveSett('SortMethod')
    let g:LookupFile_SortMethod = ''
  endif
endfunction

function! s:ConfigWalk()
  call s:SaveSett('LookupAcceptFunc')
  unlet! g:LookupFile_LookupAcceptFunc
  let g:LookupFile_LookupAcceptFunc = function(s:SNR().'IdoAccept')
  " Make sure we have the right slashes, in case user passed in init path
  " with wrong slashes.
  call setline('.', substitute(getline('.'), '\\', '/', 'g'))

  inoremap <buffer> <expr> <BS> <SID>IdoBS()
  inoremap <buffer> <expr> <S-BS> <SID>IdoBS()
  call s:AddCleanup('iunmap <buffer> <BS>')
  imap <buffer> <expr> <Tab> <SID>IdoTab()
  call s:AddCleanup('iunmap <buffer> <Tab>')
  inoremap <expr> <buffer> <C-B> <SID>IdoSwitchTo('buffer')
  call s:AddCleanup('iunmap <buffer> <C-B>')
endfunction

function! s:IdoSwitchTo(mode)
  call s:LookupReset()
  if a:mode == 'buffer'
    let tok = matchstr(getline('.'), '[^/]*$')
    let cmd = 'LUBufs'.(tok == "" ? '!' : ' '.tok)
  else
    let cmd = 'LUWalk '.s:GetDefDir().getline('.')
  endif
  return (pumvisible()?"\<C-E>":'')."\<Esc>:".cmd."\<CR>"
endfunction

function! s:IdoAccept(splitWin, key)
  let refreshCmd = "\<C-O>:call lookupfile#LookupFile(0)\<CR>\<C-O>:\<BS>"
  if getline('.') !=# g:lookupfile#lastPattern && getline('.')[strlen(getline('.'))-1] == '/'
    return refreshCmd
  elseif getline('.') ==# g:lookupfile#lastPattern
        \ && len(g:lookupfile#lastResults) > 0
        \ && g:lookupfile#lastResults[0]['kind'] == '/'
    " When the first entry is a directory, accept it, and trigger a fresh
    " completion on that.
    return "\<C-N>\<C-R>=(getline('.') == lookupfile#lastPattern)?\"\\<C-N>\":''\<CR>".refreshCmd
  endif
  return lookupfile#AcceptFile(a:splitWin, a:key)
endfunction

function! s:IdoBS()
  if lookupfile#IsPopupHidden() == 1
    return "\<BS>"
  endif
  if getline('.') !~ '/$'
    return (pumvisible() ? "\<C-E>" : '')."\<BS>"
  else
    " Determine the number of <BS>'s required to remove the patch component.
    let lastComp = matchstr(getline('.'), '[^/]*/$')
    return (pumvisible() ? (getline('.') ==# g:lookupfile#lastPattern ?
          \ "\<C-E>" : "\<C-Y>") : '') . repeat("\<BS>", strlen(lastComp))
  endif
endfunction

function! s:IdoTab()
  " When no pattern yet, fill up with current directory.
  if !pumvisible() && getline('.') == ''
    return s:GetDefDir()
  else
    return "\<Tab>"
  endif
endfunction

function! s:GetDefDir()
  return substitute(expand('#'.s:baseBufNr.':p:h'), '\\', '/', 'g').'/'
endfunction

" Convert file wildcards ("*", "?" etc. |file-pattern|) to a Vim string
"   regex metachars (see |pattern.txt|). Returns metachars that work in "very
"   nomagic" mode.
let s:fileWild = {}
function! s:TranslateFileWild(fileWild)
  let strRegex = ''
  if a:fileWild ==# '*'
    let strRegex = '\[^/]\*'
  elseif a:fileWild ==# '**'
    let strRegex = '\.\*'
  elseif a:fileWild ==# '?'
    let strRegex = '\.'
  elseif a:fileWild ==# '['
    let strRegex = '\['
  endif
  return strRegex
endfunction

" Convert a |file-pattern| to a Vim string regex (see |pattern.txt|).
"   No error checks for now, for simplicity.
function! s:TranslateFileRegex(filePat)
  let pat = substitute(a:filePat, '\(\*\*\|\*\|\[\)',
        \ '\=s:TranslateFileWild(submatch(1))', 'g')
  let unprotectedMeta = genutils#CrUnProtectedCharsPattern('?,', 1)
  let pat = substitute(pat, unprotectedMeta,
        \ '\=s:TranslateFileWild(submatch(1))', 'g')
  return (pat == '') ? pat : '\V'.pat
endfunction
 
" Translates the file pattern to ignore case on non-case-insensitive systems.
function! s:FilePatIgnoreCase(filePat)
  return substitute(a:filePat, '\(\[.\{-}]\)\|\(\a\)',
        \ '\=s:TranslateAlpha(submatch(0))', 'g')
endfunction

function! s:TranslateAlpha(pat)
  if a:pat =~"^["
    return substitute(substitute(a:pat, '-\@<!\a-\@!', '&\u&', 'g'),
          \ '\(\a\)-\(\a\)', '\1-\2\u\1-\u\2', 'g')
  else
    return substitute(a:pat, '\a', '[\l&\u&]', 'g')
  endif
endfunction

function! s:MatchingExactCase(filePat)
  if &ignorecase
    if &smartcase && a:filePat =~# '\u'
      let matchingExactCase = 1
    else
      let matchingExactCase = 0
    endif
  else
    if genutils#OnMS()
      let matchingExactCase = 0
    else
      let matchingExactCase = 1
    endif
  endif
  return matchingExactCase
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim6:fdm=marker et sw=2

"Running status"
"do not modify, internal use"
let g:Auto_update_cscope_ctags_running_status = 0
let g:autocommands_loaded = 0
let g:Auto_detect_cscope_need_reset = 0
let g:cscope_reset_detect_mode = 0
let g:vim_has_timers = 0
let g:in_cmdline_mode_t = 0
let g:in_cmdline_mode_t_load = 0
let g:enable_soft_link_file = 'ignore'
"end internal use"

"For debug print"
"default value 0"
if !exists('g:Auto_update_cscope_ctags_debug_log')
        let g:Auto_update_cscope_ctags_debug_log = 0
endif

"For lock reflash Time:"
"default value 60"
"g:Auto_update_cscope_ctags_timer_filter"
"                   this time for filter modify frequency"
"                   if you want to see database update immediately"
"                   you can modify to 10s or 1s, which I do not suggest"
"                   ,caused by csocpe or ctags gen database may take a"
"                   big occupy on disk,you can override at .vimrc"
if !exists('g:Auto_update_cscope_ctags_timer_filter')
        let g:Auto_update_cscope_ctags_timer_filter = 60
endif

"g:Auto_update_cscope_ctags_lock_floor_max"
"default value 1800"
"                   this time for wait cscope or ctag gen tags finish"
"                   or vim closed when gen ctags run last time, "
"                   on SSD , gen cscope database(kernel code) may take 20s"
"                   on HDD/7200 gen cscope database(kernel code)may take 50s "
"                   so, I suggest keep, this vale to 1800(30min), if you PC"
"                   I/O is so slow more than 30min, you may chang this value"
"                   you can override at .vimrc"
if !exists('g:Auto_update_cscope_ctags_lock_floor_max')
        let g:Auto_update_cscope_ctags_lock_floor_max = 1800
endif

"g:auto_update_cscope_ctags_backup_run_py_dir_cache"
"default ~/.vim/plugin"
"                   you may set this in you .vimrc"
"                   for plugn run quickly, but even"
"                   you config err, we can also find it"
if !exists('g:auto_update_cscope_ctags_backup_run_py_name_cache')
        let g:auto_update_cscope_ctags_backup_run_py_name_cache = '~/.vim/bundle/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags_backup_run.py'
endif

"g:auto_run_function_when_cscope_connect"
"default 1"
"			:when find cscope connect/first load"
"			or buffers swith"
if !exists('g:auto_run_function_when_cscope_connect')
        let g:auto_run_function_when_cscope_connect = 1
endif

"g:check_update_when_first_load_vim"
"default 1"
"           when 1, we will try to check database need update or not"
"           eg: you add some file in project or edit src by git pull or "
"           other editer like gedit or notepad, we can detect the update"
"           you can disable this Feature in .vimrc"
if !exists('g:check_update_when_first_load_vim')
        let g:check_update_when_first_load_vim = 1
endif

if !has('timers')
    echo "Warning: you vim do not support timer"
    echo "Feature ('auto reset cscope' and 'check_update_when_first_load_vim') will disabled"
    echo "just support base function update cscope and ctags"
    echo "try to update you vim from github: https://github.com/vim/vim to remove this warning"
    echo "more detail, pls check README"
endif

if g:in_cmdline_mode_t_load == 0
  let g:in_cmdline_mode_t_load = 1
  autocmd CmdwinEnter * let g:in_cmdline_mode_t = 1
  autocmd CmdwinLeave * let g:in_cmdline_mode_t = 0
endif

command! -nargs=0 -bar Manualstartstopautoupdatedatabas call <SID>Manual_start_stop_auto_update_database(0)
command! -nargs=0 -bar Manualupdatedatabaseonetime call <SID>Auto_update_cscope_ctags(3)
command! -nargs=0 -bar Createtag call <SID>Manual_start_stop_auto_update_database(1)

if g:auto_run_function_when_cscope_connect == 1
	if g:Auto_update_cscope_ctags_running_status == 0
		"echo "auto enable tags upload""
		if g:autocommands_loaded == 0
		  let g:autocommands_loaded = 1
		  autocmd BufWritePost * call <SID>Auto_update_cscope_ctags(0)
		endif
		let g:Auto_update_cscope_ctags_running_status = 1
	endif
endif


function! <SID>Manual_start_stop_auto_update_database(mode)
if 1 == a:mode
let vim_arch_parameter_d = {'normal':'1', 'alpha':'1', 'arm':'1', 'avr32':'1',
        \ 'c6x':'1', 'frv':'1', 'hexagon':'1', 'm68k':'1', 'microblaze':'1', 'mn10300':'1',
        \ 'parisc':'1', 's390':'1', 'sh':'1', 'tile':'1', 'unicore32':'1', 'xtensa':'1',
        \ 'arc':'1', 'arm64':'1', 'blackfin':'1', 'cris':'1' ,'h8300':'1', 'ia64':'1',
        \ 'm32r':'1', 'metag':'1', 'mips':'1', 'openrisc':'1', 'powerpc':'1', 'score':'1',
        \ 'sparc':'1', 'um':'1', 'x86':'1'
        \ }
    call <SID>Auto_update_cscope_ctags(a:mode)
    if '0' == g:create_tag_run_py_ret_vim
        echo ' '
        echo ' '
        echo ' '
        echo "Will do not gen tags: More detail check output log"
        echo ' '
        echo ' '
        return 0
    endif

    if 1 == g:Createtag_need_input_arch
        echo "For example, if you just care ARM64 platform code, just need input arm64"
        echo "if input 'normal', means: do not build a especially arch, but we do not suggest at a kernel tree"
        let g:arch_str = input("please input a ARCH: ")
        while ! has_key(vim_arch_parameter_d, g:arch_str)
            echo " "
            echo " "
            echo ">>>>>>>>Do not support " . "ARCH = ". g:arch_str
            echo " "
            echo "For example, if you just care ARM64 platform code, just need input arm64"
            let g:arch_str = input("please input a ARCH: ")
        endwhile
    else
        let g:arch_str = "normal"
    endif

    echo " "
    if cscope_connection() > 0
        let g:to_user_suggest_tag_dir_str_vim = g:csdbpath
    elseif "normal" == g:arch_str
        let b:tmp_dir_i = 'null'
        echo " "
        echo "Customization for tag dir for 'normal' project"
        echo "please input a dir you want ,suggest dir = " . g:to_user_suggest_tag_dir_str_vim
        echo "Press 'Enter' to use suggest dir [" . g:to_user_suggest_tag_dir_str_vim . "]" 
        \ . " or input dir which you tend to"
        let b:tmp_dir_i = input("Press 'ENTER' or  input a dir string: ")
        if "" == b:tmp_dir_i
            echo " "
            echo "use suggest dir[ " . g:to_user_suggest_tag_dir_str_vim . " ]" 
        else
            echo " "
            echo "use Customization dir[ " . g:to_user_suggest_tag_dir_str_vim . " ]"
            let g:to_user_suggest_tag_dir_str_vim = b:tmp_dir_i
        endif
    endif

    if "normal" == g:arch_str
	echo " "
	echo "Support soft link file or not? (while add -L to find commmand)"
	let b:support_soft_link = input("Yes: please input 'yes' to support soft link file, default 'NO'>>> ")
	echo " "
	if "yes" == b:support_soft_link || "YES" == b:support_soft_link
	    echo "Customization support soft link file"
	    let g:enable_soft_link_file = "yes"
        else
	    echo "Customization disable soft link file"
	    let g:enable_soft_link_file = "no"
	endif
    endif

    let g:run_c = "python " . " " .g:create_tag_run_py_ret_vim . " " . g:arch_str . " cscope_and_ctags " . g:to_user_suggest_tag_dir_str_vim . " print_message " . g:enable_soft_link_file
    echo " "
    echo "Will run command:\n" . g:run_c
    echo " "
    echo " "
    echo "Do you really want to  create tag at dir: [" . g:to_user_suggest_tag_dir_str_vim . "]?"
    echo "Yes: please input yes start, will take about one minutes(depend on code size and I/O performance)"
    echo "NO : please input any other char to stop"
    let b:tmps = input(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    echo " "
    if "yes" == b:tmps || "YES" == b:tmps
        echo b:tmps
    else
        echo "stop to create tags"
        return 0
    endif

    exe '!' . g:run_c
    execute 'set tags ='. g:to_user_suggest_tag_dir_str_vim . '/tags'
    exe "cs kill -1"
    exe "cs add " . g:to_user_suggest_tag_dir_str_vim . "/cscope.out " . g:to_user_suggest_tag_dir_str_vim
    let g:csdbpath = g:to_user_suggest_tag_dir_str_vim
    let g:for_auto_update_cscope_ctag = g:to_user_suggest_tag_dir_str_vim
    let g:myLookupFileTagExpr = './filenametags'
    let g:LookupFile_TagExpr = 'g:myLookupFileTagExpr'
    let g:LookupFile_MinPatLength = 1               "at least 1 character power find
    let g:LookupFile_PreserveLastPattern = 0        "don't save last pattern
    let g:LookupFile_PreservePatternHistory = 1     "save find history
    let g:LookupFile_AlwaysAcceptFirst = 1          "<Enter> open first match item
    let g:LookupFile_AllowNewFiles = 0              "Don't allow create no-exist file
    let g:LookupFile_RecentFileListSize = 30
    let g:LookupFile_FileFilter = '\.class$\|\.o$\|\.obj$\|\.exe$\|\.jar$\|\.zip$\|\.war$\|\.ear$'

    return 0
endif

if g:Auto_update_cscope_ctags_running_status == 0
    echo "Manual start auto update tag database"
	if g:autocommands_loaded == 0
	  let g:autocommands_loaded = 1
	  autocmd BufWritePost * call <SID>Auto_update_cscope_ctags(0)
	endif
    let g:Auto_update_cscope_ctags_running_status = 1
else
    echo "Manual stop auto update tag database"
    let g:Auto_update_cscope_ctags_running_status = 0
    return 0
endif

endfunction

function! <SID>FindBufferReallyPwd()
	let l:Findcomand_args = './'
	let l:Findcommand_args_buffer_name = bufname('%')
	let l:Findcommand_args_pwd = getcwd()
	if char2nr(l:Findcommand_args_buffer_name) == 47
		"echo "Absolute path""
		let l:Findcomand_args = l:Findcommand_args_buffer_name
	elseif char2nr(l:Findcommand_args_buffer_name) == 0
		echo "No buffers"
		let l:Findcomand_args = l:Findcommand_args_pwd
                let g:curbufferpwd = l:Findcomand_args
                return 0
	else
		"echo "relative path""
		let l:Findcomand_args = l:Findcommand_args_pwd . '/' . l:Findcommand_args_buffer_name
	endif
	echo 'BUF: ' . l:Findcomand_args
	echo 'CUR: ' . l:Findcommand_args_pwd
if has('python') || has('python3')
python << EOF
import vim
find_tmp_str = vim.eval("l:Findcomand_args")
find_command_str = "let g:curbufferpwd = '%s'" %  (find_tmp_str[:find_tmp_str.rindex("/")])
vim.command(find_command_str)
EOF
else
	echo 'Pls build vim with python'
        echo "more detail, pls check README"
endif
endfunction

function! <SID>Auto_update_cscope_ctags(create_mode)

        if 1 == a:create_mode
            call <SID>FindBufferReallyPwd()
            let g:Create_Mode = 1
        else
            let g:Create_Mode = 0
        endif

        if 2 == a:create_mode
            let g:cscope_reset_detect_mode = 1
        else
            let g:cscope_reset_detect_mode = 0
        endif

""when args = 3, we try to update database once, for some user just want to update
""database onetime, by command : :Manualupdatedatabaseonetime
        if g:Auto_update_cscope_ctags_running_status == 0 && 0 == g:Create_Mode && 3 != a:create_mode && 2 != a:create_mode
		"echo "Already stop, just return""
		return 0
	endif

	if cscope_connection() <= 0 && 0 == g:Create_Mode
		"echo "Do not find tags, return""
		return 0
	endif

if has('python') || has('python3')
python << EOF
import vim
import os
import time
import platform
import string
import sys
import time
import getpass

global_log_file = '/tmp/.Auto_update_cscope_ctags_debug_log.log'
arch_parameter_list = ['normal', 'alpha', 'arm', 'avr32', \
        'c6x', 'frv', 'hexagon', 'm68k', 'microblaze', 'mn10300', \
        'parisc', 's390', 'sh', 'tile', 'unicore32', 'xtensa', \
        'arc', 'arm64', 'blackfin', 'cris' ,'h8300', 'ia64', \
        'm32r', 'metag', 'mips', 'openrisc', 'powerpc', 'score', \
        'sparc', 'um', 'x86']

def debug_python_print(str):
    enable_debug_log = int(vim.eval("g:Auto_update_cscope_ctags_debug_log"))

    if 1 == enable_debug_log:
        f = open(global_log_file,'a')
        print >> f, '\n'
        print >> f, time.localtime(time.time())
        print >> f, str
        f.close()
    else:
        return 0

def Err_print(str_t):
    debug_python_print(str_t)
    print(str_t)
    print("ERR Happend: stop auto update tag database")
    stop_run_cmd = "let g:Auto_update_cscope_ctags_running_status = 0"
    vim.command(stop_run_cmd)

def Warn_print(str_t):
    debug_python_print(str_t)
    print(str_t)

def scan_f_new(directory, check_type=['.c', '.cpp', '.h', '.cc', \
'.java', '.sh', '.mk', '.prop', '.xml', 'Makefile', '.rc', 'platform', \
'Drivers', '.scons', '.api', '.tla', '.smh', '.smi', '.smt', '.idl', '.te', \
'.py', '.S', '.tpl', '.css', '.js', '.txt', 'proto', '.md' '.conf', '.json', \
'BUILD', '.bzl', 'BUILD', '.hpp', '.launch']):

    ret = 0
    cmp_file = directory + '/cscope.files'
    debug_python_print("cmp_file = %s" % cmp_file)
    newer_then_cscope_files=[]
    if not os.path.exists(cmp_file):
        ret = -2
        return ret

    if (platform.system()) != 'Windows':
        debug_python_print('Unix env, use find command')
        find_command='find %s -newer %s  2>&1' % (directory, cmp_file)
        for i in os.popen(find_command):
            newer_then_cscope_files.append(i.replace("\n", ""))
    else:
        debug_python_print("Warning: use gengic logic, may take cpu")
        Err_print("Err: do not support Windows env")
        return -1
        #just backup
        for root, sub_dirs, files in os.walk(directory):
            for special_file in files:
                if os.path.exists(os.path.join(root, special_file)):
                    if os.stat(os.path.join(root, special_file)).st_mtime > os.stat(cmp_file).st_mtime:
                        newer_then_cscope_files.append(os.path.join(root, special_file))
            
    for i in newer_then_cscope_files:
        for need_type in check_type:
            if i.endswith(need_type):
                ret=ret+1
                debug_python_print("Found update file %s" % i)
    return ret

def lock_check_pid(i_lock):
    # ret:
    # -1 check pid failed , invaild lock need remove
    #1 check pid success, valid lock
    ret = 1
    i_lock_buffer = []
    if os.path.exists(i_lock):
        i_lock_buffer_len = 0
        f = open(i_lock, 'r')
        for line in f:
            i_lock_buffer_len = i_lock_buffer_len + 1
            i_lock_buffer.append(line)
        f.close()

        debug_python_print("i_lock_buffer len %s" % i_lock_buffer_len)
        if 2 == i_lock_buffer_len:
            cmd_may_file = "/proc/%s/cmdline" % i_lock_buffer[0].strip()
            debug_python_print("cmd_may_file = %s" % cmd_may_file)
            if os.path.exists(cmd_may_file):
                compare_cmd = 'null'
                cmd_f = open(cmd_may_file, 'r')
                for i_line in cmd_f:
                    compare_cmd = i_line
                    #read only one line
                    break
                cmd_f.close()
                if i_lock_buffer[1].strip() == compare_cmd:
                    debug_python_print("lock_check_pid success: really valid lock")
                    ret = 1
                else:
                    debug_python_print("diff proccess = %s" % compare_cmd)
                    ret = -1
            else:
                ret = -1
                debug_python_print("pid = %s already exit" % i_lock_buffer[0].strip())
        else:
            ret = -1
            debug_python_print("invaild lock")

    else :
        debug_python_print("can not find lock")
        ret = -1

    return ret

def check_lock_status_and_time(lock_str):
    # ret :
    #-1, config err
    #0: lock release , 
    #1: lock hold 
    #2, lock create before systemup, may cause by system shotdown when gen tag
    #3: lock too old, or invaild
    ret = -1
    if os.path.exists(lock_str):
        ret = 1
        btime_l= ['0', '0']
        if os.path.exists('/proc/stat'):
            f = open('/proc/stat', 'r')
            for line in f:
                #debug_python_print("/proc/stat line: %s" % line)
                if 0 <= line.find('btime'):
                    btime_f = line.split()
                    break
            f.close()

        btime_l_int = int(btime_f[1])
        debug_python_print("btime: %s" % btime_l_int)
        debug_python_print("Find lock %s" % lock_str)
        now_time = time.time()
        md_time = os.stat(lock_str).st_mtime
        if md_time < btime_l_int:
            debug_python_print("lock need remove caused by md_time < btime_l_int")
            debug_python_print("md_time = %s" % md_time)
            debug_python_print("btime = %s" % btime_l_int)
            ret = 2
            return ret

        md_time_pass = now_time - md_time
        debug_python_print("lock md time pass %s" % (md_time_pass))
        filter_time = int(vim.eval("g:Auto_update_cscope_ctags_timer_filter"))
        lock_reflash_max = int(vim.eval("g:Auto_update_cscope_ctags_lock_floor_max"))
        if filter_time >= lock_reflash_max:
            ret = -1
            Err_print("Err: config g:Auto_update_cscope_ctags_lock_floor_min g:Auto_update_cscope_ctags_lock_floor_max ERR")
            return ret

        if md_time_pass >= lock_reflash_max:
            debug_python_print("Lock to old, need remove it")
            ret = 3
        else:
            debug_python_print("need check lock pid")
            lock_check_pid_ret =  lock_check_pid(lock_str)
            if 1 == lock_check_pid_ret:
                debug_python_print("Lock %s locked, wait... " % lock_str)
                ret = 1
            elif -1 == lock_check_pid_ret:
                debug_python_print("find a invaild lock, remove it")
                ret = 3
    else:
        debug_python_print("Lock %s already unlock" % lock_str)
        ret = 0

    return ret

def check_cscope_files_type(directory):
    i = 0
    max_read_line = 3
    ret = 'null'
    head_of_check_file = []
    check_file = directory + '/cscope.files'
    if os.path.exists(check_file):
        debug_python_print("Check cscope type!")
        #try to read first three line from cscope.files
        f = open(check_file, 'r')
        for line in f:
            i = i+1
            debug_python_print('line %s in csocpe.files = %s' % (i, line))
            head_of_check_file.append(line.replace('/$', '').strip())
            if max_read_line == i:
                break
        f.close()

        if '' == head_of_check_file[0]:
            Warn_print("ERR: invaild file %s " % check_file)
            return ret

        if '-k' == head_of_check_file[0]:
            debug_python_print('this is a linux kernel project')
            list_arch = head_of_check_file[2].replace('/', ' ').split()
            for i in list_arch:
                debug_python_print(i)
            ret = list_arch[1]
        else:
            debug_python_print('this is a generic project')
            ret = 'normal'

    else:
        Warn_print("Err: can not find file %s" % check_file)

    return ret

def get_backup_run_py():

    ret = 'null'
    user_name = getpass.getuser()
    may_backup_run_py_file_tmp = vim.eval("g:auto_update_cscope_ctags_backup_run_py_name_cache")
    if 0 <= may_backup_run_py_file_tmp.find('~'):
        debug_python_print('use ~ for user name convert it')
        may_backup_run_py_file = may_backup_run_py_file_tmp.replace('~', '/home/%s') % user_name
    else:
        may_backup_run_py_file = may_backup_run_py_file_tmp

    if os.path.exists(may_backup_run_py_file):
        debug_python_print("cache back run python %s success" % may_backup_run_py_file)
        ret = may_backup_run_py_file
    else:
        hard_search_dir = '/home/%s/.vim/' % user_name 
        for root, sub_dirs, files in os.walk(hard_search_dir):
            for i_file in files:
                if 'auto_update_cscope_ctags_backup_run.py' == i_file:
                    ret = os.path.join(root, i_file)
                    debug_python_print("hard find back run python %s ,put it cache" % ret)
                    put_back_p_cache_cmd = "let g:auto_update_cscope_ctags_backup_run_py_name_cache = " \
                            + "\'" + ret  + "\'"
                    vim.command(put_back_p_cache_cmd)
                    #quickly out
                    return ret

    return ret

def check_kernel_code_characteristic(check_tree):

    #list some dir of kernel code here
    kernel_code_tree_characteristic_set = ['arch', 'block', 'Documentation', 'drivers', \
            'firmware', 'fs', 'include', 'init', 'ipc', 'kernel', 'lib', 'mm', \
            'net']
    #if we check the code is kernel tree, we will use ./scripts/tags.sh to gen tag, so
    #we need double check file exists(realize function : make cscope ARCH=[ARCH])
    kernel_tree_force_check_file = '/scripts/tags.sh'
    #to now, kernel code sub_dirs do not more then 12
    check_dir_level = 12
    i = 0
    kernel_tree_or_not = 'false'
    cache_dir = check_tree
    old_dir = os.getcwd()
    debug_python_print("old dir :%s" % old_dir)

    while (i < check_dir_level):
        i = i + 1
        if not os.path.exists(cache_dir):
            Warn_print("Err happned when match kernel tree %s" % cache_dir)
            os.chdir(old_dir)
            return (check_tree, kernel_tree_or_not)

        os.chdir(cache_dir)
        debug_python_print("check_kernel_code_characteristic i = %s" % i)
        tmp_list_file = os.listdir(cache_dir)
        if set(kernel_code_tree_characteristic_set).issubset(set(tmp_list_file)):
            debug_python_print("check_kernel_code_characteristic: find kernel_tree %s" % cache_dir)
            kernel_tree_or_not = 'true'
            break
        else:
            cache_dir=cache_dir[:cache_dir.rindex("/")]
            if cache_dir == '':
                debug_python_print("already to home dir")
                cache_dir = '/'
                break
            debug_python_print("now try dir %s" % cache_dir)

    if 'true' == kernel_tree_or_not:
        force_file = cache_dir + kernel_tree_force_check_file
        if os.path.exists(force_file):
            os.chdir(old_dir)
            return (cache_dir, kernel_tree_or_not)
        else:
            kernel_tree_or_not = 'false'
            debug_python_print("check force file check %s failed" % force_file)
            os.chdir(old_dir)
            return (check_tree, kernel_tree_or_not)
    else:
        os.chdir(old_dir)
        return (check_tree, kernel_tree_or_not)

def reflash_too_quick(directory):
    ret = 1
    check_file = directory + '/cscope.files'
    if os.path.exists(check_file):
        now_time = time.time()
        md_time = os.stat(check_file).st_mtime
        f_time = now_time - md_time
        filter_time = int(vim.eval("g:Auto_update_cscope_ctags_timer_filter"))
        if f_time < filter_time:
            debug_python_print("reflash_too_quick only pass %s" % f_time)
            ret = 1
        else:
            ret = 0

    return ret

def main_loop():

    may_tags_dir = vim.eval("g:for_auto_update_cscope_ctag")
    Create_Mode_I = int(vim.eval("g:Create_Mode"))
    cscope_reset_detect_mode_I = int(vim.eval("g:cscope_reset_detect_mode"))
    #Fistly detect cscope reset mode
    if 1 == cscope_reset_detect_mode_I:
        need_stop_cscope_reset_detect_time = 0
        debug_python_print("handle cscope reset detect timer")
        Auto_detect_cscope_need_reset_I = int(vim.eval("g:Auto_detect_cscope_need_reset"))

        in_cmdline_mode = int(vim.eval("g:in_cmdline_mode_t"))
        if 1 == in_cmdline_mode:
            debug_python_print("in cmdline mode, wait...")
            return 0

        cscope_wait_lock = may_tags_dir + "/.auto_cscope_ctags/cscope_detect_wait"
        if 0 == Auto_detect_cscope_need_reset_I:
            debug_python_print("stop cscope reset detect timer")
            need_stop_cscope_reset_detect_time = 1
        elif os.path.exists(cscope_wait_lock):
            debug_python_print("cscope reset detect logic wait...")
        elif 1 == check_lock_status_and_time(may_tags_dir + "/.auto_cscope_ctags/lock"):
            debug_python_print("check time for reset cscope reset, wait....")
        else:
            need_stop_cscope_reset_detect_time = 1

        if 1 == need_stop_cscope_reset_detect_time and 1 == int(vim.eval("g:vim_has_timers")):
            timer_unmask_str_cmd = "let g:Auto_detect_cscope_need_reset = 0"
            vim.command(timer_unmask_str_cmd)
            cscope_reset_timer_id = int(vim.eval("g:cscope_reset_detect_timer"))
            pause_cscope_reset_timer_str = "call timer_pause(%s, 1)" % cscope_reset_timer_id
            debug_python_print("pause cscope reset detect timer cmd %s" % pause_cscope_reset_timer_str)
            vim.command(pause_cscope_reset_timer_str)
            cscope_reset_str = "cscope reset"
            vim.command(cscope_reset_str)
        return 0
    #end detect cscope reset mode

    #set a err status firstly
    vim.command("let g:create_tag_run_py_ret_vim = '0'")
    if 1 == Create_Mode_I:
        default_tag_dir = vim.eval("g:curbufferpwd")
        print("Now try to Create cscope and ctags database")
        if not os.path.exists(default_tag_dir):
            Warn_print("invaild default_tag_dir = %s" % default_tag_dir)
            return 0

        (to_user_suggest_tag_dir, kernel_tree) = check_kernel_code_characteristic(default_tag_dir)
        debug_python_print("creat tag: find default_tag_dir = %s" % to_user_suggest_tag_dir)
        ret_check_lock_status_and_time = check_lock_status_and_time(to_user_suggest_tag_dir \
                + "/.auto_cscope_ctags/lock")
        if 1 == ret_check_lock_status_and_time:
            Warn_print("anthor update proccess go..., pls wait a moment to try ")
            return 0

        if not os.path.exists(to_user_suggest_tag_dir):
            Warn_print("Err happned invaild dir = %s" % to_user_suggest_tag_dir)
            return 0

        if 'true' == kernel_tree:
            Warn_print("we find kernel code tree at %s" % to_user_suggest_tag_dir)
            Warn_print("Support ARCH:")
            Warn_print(" ")
            Warn_print(arch_parameter_list)
            Warn_print(" ")
            vim.command("let g:Createtag_need_input_arch = 1")
        else:
            Warn_print("A normal project will create")
            vim.command("let g:Createtag_need_input_arch = 0")
            #vim python do not support input, so we will retrun to vim env after print
            #input_str = 'null'
            #input_str = input("Please input cpu ARCH:")
            #while input not in arch_parameter_list:
            #    print("Support ARCH:")
            #    print(arch_parameter_list)
            #    input_str = raw_input("Please input a vaild cpu ARCH:")

        #before return we need return back_run_python_dir and put to_user_suggest_tag_dir to vim
        create_tag_run_py_ret = get_backup_run_py()
        if 'null' != create_tag_run_py_ret and os.path.exists(create_tag_run_py_ret):
            tmp_put_create_tag_run_py_ret_vim = "let g:create_tag_run_py_ret_vim = '%s'" % create_tag_run_py_ret
            debug_python_print("create_tag_run_py_ret success %s" % tmp_put_create_tag_run_py_ret_vim)
            vim.command(tmp_put_create_tag_run_py_ret_vim)
            to_user_suggest_tag_dir_str = "let g:to_user_suggest_tag_dir_str_vim = '%s'" % to_user_suggest_tag_dir
            vim.command(to_user_suggest_tag_dir_str)
        else:
            Err_print("create_tag_run_py_ret err: get_backup_run_py = %s" % create_tag_run_py_ret)

        return 0

    #####end create mode ####

    #for debug
    #debug_python_print("may_tags_dir = %s" % may_tags_dir)
    #return 0
    #end debug

    if 'null' == may_tags_dir:
        return 0

    check_lock_status_and_time_ret = check_lock_status_and_time(may_tags_dir + "/.auto_cscope_ctags/lock")
    if 1 == check_lock_status_and_time_ret or -1 == check_lock_status_and_time_ret:
        return 0

    if 3 == check_lock_status_and_time_ret or 2 == check_lock_status_and_time_ret:
        #check file exists again for use rm command is so danger
        lock_file = "%s/.auto_cscope_ctags/lock" % may_tags_dir
        if os.path.exists(lock_file):
            rm_lock_cmd = "rm %s  1>/dev/null  2>&1" % lock_file
            debug_python_print("rm lock file %s" % lock_file)
            os.system(rm_lock_cmd)

    if 0 == check_lock_status_and_time_ret or 2 == check_lock_status_and_time_ret or 3 == check_lock_status_and_time_ret:
        if 1 == reflash_too_quick(may_tags_dir):
            return 0

        file_result = scan_f_new(may_tags_dir)
        if file_result > 0:
            handle_arch = check_cscope_files_type(may_tags_dir)
            if handle_arch not in arch_parameter_list:
                Warn_print("Err: ARCH: %s do not support or err happned" % handle_arch)
                return -1

            run_py_ret = get_backup_run_py()
            if 'null' != run_py_ret and os.path.exists(run_py_ret):
                #when cscope detect timer may run before create lock, which will
                #lead cscope logic wrong,so we create creat a cscope_detect_wait
                pre_create_cscope_wait_cmd = "cd %s 1>/dev/null 2>&1; mkdir .auto_cscope_ctags 1>/dev/null 2>&1; touch .auto_cscope_ctags/cscope_detect_wait 1>/dev/null 2>&1" % may_tags_dir
                debug_python_print("firstly ,create a cscope_detect_wait %s" % pre_create_cscope_wait_cmd)
                os.system(pre_create_cscope_wait_cmd)
                #vim script api do not support blocking time I/O, so we and '&' here
                #why do not use vim timer: long time I/O may cause vim exit err,also 
                #vim block for input(vim timer base in input thread?)
                back_run_cmd = "python %s %s %s %s quiet ignore &" % (run_py_ret, handle_arch, "cscope_and_ctags", may_tags_dir)
                debug_python_print(back_run_cmd)
                os.system(back_run_cmd)

                if 1 == int(vim.eval("g:vim_has_timers")):
                    #after put back cmd we need sync to cscope_reset_timer
                    timer_mask_str_cmd = "let g:Auto_detect_cscope_need_reset = 1"
                    vim.command(timer_mask_str_cmd)
                    cscope_reset_timer_id = int(vim.eval("g:cscope_reset_detect_timer"))
                    unpause_cscope_reset_timer_str = "call timer_pause(%s, 0)" % cscope_reset_timer_id
                    debug_python_print("restart cscope reset detect timer cmd %s" % unpause_cscope_reset_timer_str)
                    vim.command(unpause_cscope_reset_timer_str)

        elif file_result == 0:
            debug_python_print("no need update")
        else:
            debug_python_print("can not find cscope.flies, for later function")
            return 0

main_loop()
EOF
else
    echo "auto update cscope ctags err: Pls build vim with python"
    echo "more detail, pls check README"
endif

endfunction

"why need timer: vim may Fistly load diff script, so we need"
"add a timer later for 1.5s wait vim hava a chance to load cscope database"
function! Fistly_check_needed_update_when_vim_load(Fistly_load_vim_timer)
    "echo "Fistly check database update when load vim""
    call <SID>Auto_update_cscope_ctags(3)
endfunction

if 1 == g:check_update_when_first_load_vim && has('timers')
    let Fistly_load_vim_timer = timer_start(1500, 'Fistly_check_needed_update_when_vim_load',{'repeat': 1})
endif

"add a timer for auto detect cscope reset after database update"
function! Cscope_reset_detect_timer_func(cscope_reset_detect_timer_vim)
    "echo "call cscope reset timer""
    call <SID>Auto_update_cscope_ctags(2)
endfunction

if has('timers')
    let cscope_reset_detect_timer_vim = timer_start(4000, 'Cscope_reset_detect_timer_func', {'repeat': -1})
    let g:cscope_reset_detect_timer = cscope_reset_detect_timer_vim
    let g:vim_has_timers = 1
endif



