" File: plugins/script/github/auto_update_cscope_ctags_database/plugin/autoload_cscope_ctags.vim
" Author: SeaflyDennis <seafly0616@qq.com>
" Date: 2017.08.06
" Last Modified Date: 2017.08.06
" Last Modified By: SeaflyDennis <seafly0616@qq.com>
" 20170426 haolong.zhang@ck-telecom.com export for_auto_update_cscope_ctag
" add this for auto update cscope and ctags tag
let g:for_auto_update_cscope_ctag = "null"

if exists("loaded_autoload_cscope")
	finish
endif
let loaded_autoload_cscope = 1

" requirements, you must have these enabled or this is useless.
if(  !has('cscope') || !has('modify_fname') )
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" If you set this to anything other than 1, the menu and macros will not be
" loaded.  Useful if you have your own that you like.  Or don't want my stuff
" clashing with any macros you've made.
if !exists("g:autocscope_menus")
  let g:autocscope_menus = 1
endif

"==
" windowdir
"  Gets the directory for the file in the current window
"  Or the current working dir if there isn't one for the window.
"  Use tr to allow that other OS paths, too
function s:windowdir()
  if winbufnr(0) == -1
    let unislash = getcwd()
  else 
    let unislash = fnamemodify(bufname(winbufnr(0)), ':p:h')
  endif
    return tr(unislash, '\', '/')
endfunc
"
"==
" Find_in_parent
" find the file argument and returns the path to it.
" Starting with the current working dir, it walks up the parent folders
" until it finds the file, or it hits the stop dir.
" If it doesn't find it, it returns "Nothing"
function s:Find_in_parent(fln,flsrt,flstp)
  let here = a:flsrt
  while ( strlen( here) > 0 )
    if filereadable( here . "/" . a:fln )
      return here
    endif
    let fr = match(here, "/[^/]*$")
    if fr == -1
      break
    endif
    let here = strpart(here, 0, fr)
    if here == a:flstp
      break
    endif
  endwhile
  return "Nothing"
endfunc
"
"==
" Cycle_macros_menus
"  if there are cscope connections, activate that stuff.
"  Else toss it out.
"  TODO Maybe I should move this into a seperate plugin?
let s:menus_loaded = 0
function s:Cycle_macros_menus()
  if g:autocscope_menus != 1
    return
  endif
  if cscope_connection()
    if s:menus_loaded == 1
      return
    endif
    let s:menus_loaded = 1
    set csto=0
    set cst
   " silent! map <unique> <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
   " silent! map <unique> <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
   " silent! map <unique> <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
   " silent! map <unique> <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
   " silent! map <unique> <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
   " silent! map <unique> <C-\>f :cs find f <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>i :cs find i <C-R>=expand("<cword>")<CR><CR>
    silent! map <unique> <C-\>a :cs find a <C-R>=expand("<cword>")<CR><CR>
    if has("menu")
  "    nmenu &Cscope.Find.Symbol<Tab><c-\\>s
  "     \ :cs find s <C-R>=expand("<cword>")<CR><CR>
  "    nmenu &Cscope.Find.Definition<Tab><c-\\>g
  "      \ :cs find g <C-R>=expand("<cword>")<CR><CR>
  "    nmenu &Cscope.Find.Called<Tab><c-\\>d
  "      \ :cs find d <C-R>=expand("<cword>")<CR><CR>
  "    nmenu &Cscope.Find.Calling<Tab><c-\\>c
  "      \ :cs find c <C-R>=expand("<cword>")<CR><CR>
  "    nmenu &Cscope.Find.Assignment<Tab><c-\\>t
  "      \ :cs find t <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Egrep<Tab><c-\\>e
        \ :cs find e <C-R>=expand("<cword>")<CR><CR>
  "    nmenu &Cscope.Find.File<Tab><c-\\>f
  "      \ :cs find f <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.Including<Tab><c-\\>i
        \ :cs find i <C-R>=expand("<cword>")<CR><CR>
      nmenu &Cscope.Find.assigned<Tab><c-\\>a
        \ :cs find a <C-R>=expand("<cword>")<CR><CR>
"      nmenu &Cscope.Add :cs add 
"      nmenu &Cscope.Remove  :cs kill 
      nmenu &Cscope.Reset :cs reset<cr>
      nmenu &Cscope.Show :cs show<cr>
      " Need to figure out how to do the add/remove. May end up writing
      " some container functions.  Or tossing them out, since this is supposed
      " to all be automatic.
    endif
  else
    let s:menus_loaded = 0
    set nocst
 "   silent! unmap <C-\>s
 "   silent! unmap <C-\>g
 "   silent! unmap <C-\>d
 "   silent! unmap <C-\>c
 "   silent! unmap <C-\>t
    silent! unmap <C-\>e
 "   silent! unmap <C-\>f
    silent! unmap <C-\>i
    silent! unmap <C-\>a
    if has("menu")  " would rather see if the menu exists, then remove...
      silent! nunmenu Cscope
    endif
  endif
endfunc
"
"==
" Unload_csdb
"  drop cscope connections.
function s:Unload_csdb()
  if exists("g:csdbpath")
    if cscope_connection(3, "out",g:csdbpath)
      let save_csvb = &csverb
      set nocsverb
      exe "cs kill " . g:csdbpath
      set csverb
      let &csverb = save_csvb
    endif
  endif
endfunc
"
"==
" Cycle_csdb
"  cycle the loaded cscope db.
function s:Cycle_csdb()
    if exists("g:csdbpath")
      if cscope_connection(3, "out", g:csdbpath)
        return
        "it is already loaded. don't try to reload it.
      endif
    endif
    let newcsdbpath = s:Find_in_parent("cscope.out",s:windowdir(),$HOME)
	let g:for_auto_update_cscope_ctag = newcsdbpath
    "echo "Found cscope.out at: " . newcsdbpath
    "echo "Windowdir: " . s:windowdir()
	"we think ctags file should at the same dir
	"so try to update ctags file when proj chang from A to B
	if filereadable(newcsdbpath . "/tags")
		"echo "Found tags at: " . newcsdbpath
		execute 'set tags ='. newcsdbpath . '/tags'
	else
		"echo "No tags"
		execute 'set tags ='
	endif
    if newcsdbpath != "Nothing"
      let g:csdbpath = newcsdbpath
      if !cscope_connection(3, "out", g:csdbpath)
        let save_csvb = &csverb
        set nocsverb
        exe "cs add " . g:csdbpath . "/cscope.out " .g:csdbpath
        set csverb
        let &csverb = save_csvb
      endif
      "
    else " No cscope database, undo things. (someone rm-ed it or somesuch)
      call s:Unload_csdb()
    endif
endfunc

" auto toggle the menu
augroup autoload_cscope
 au!
 au BufEnter *.[chlysS]  call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.cc      call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.cpp      call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.java      call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.xml     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.mk     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *config*     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter Makefile     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter platform     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter Drivers     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.rc     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.dts     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.dtsi     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.scons     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.api     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.tla     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.smh    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.smi     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.smt     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.idl     call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.sh    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.te    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.py    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.mak    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.tpl    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.css    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.js    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.txt   call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.proto    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.md    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.conf    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.json    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter BUILD   call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.bzl    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.BUILD    call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.hpp      call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufEnter *.launch   call <SID>Cycle_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.[chlysS] call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.cc     call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.cpp     call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.java     call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.xml     call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.mk     call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *config*    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload Makefile    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.rc    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload platform    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload Drivers    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.rc    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.dts    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.dtsi    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.scons    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.api    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.tla    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.smh    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.smi    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.smt    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.idl    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.sh    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.te    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 "au BufUnload *.py    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.mak    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.tpl    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.css    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.js    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.txt    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.proto    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.md    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.conf    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.json    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.BUILD    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload BUILD    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.bzl    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.hpp    call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()
 au BufUnload *.launch call <SID>Unload_csdb() | call <SID>Cycle_macros_menus()

 let g:myLookupFileTagExpr = './filenametags'
 let g:LookupFile_TagExpr = 'g:myLookupFileTagExpr'
 let g:LookupFile_MinPatLength = 1               "at least 1 character power find
 let g:LookupFile_PreserveLastPattern = 0        "don't save last pattern
 let g:LookupFile_PreservePatternHistory = 1     "save find history
 let g:LookupFile_AlwaysAcceptFirst = 1          "<Enter> open first match item
 let g:LookupFile_AllowNewFiles = 0              "Don't allow create no-exist file
 let g:LookupFile_RecentFileListSize = 30
 let g:LookupFile_FileFilter = '\.class$\|\.o$\|\.obj$\|\.exe$\|\.jar$\|\.zip$\|\.war$\|\.ear$'

augroup END

let &cpo = s:save_cpo

