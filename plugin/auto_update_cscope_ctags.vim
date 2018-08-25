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
"v3.0.1: 20170808 format opt args
"v3.0.2: 20170822 optimize python API support config
"v4.0.0: 20180128 v4.0 release
"v4.0.1: 20180528 v4.0.1 support MAC OS
"v5.0:   20180728 support gnu-global for cscope backend, ctags and global support Append mode
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
let g:do_not_care_dir = 'ignore'
let g:for_auto_update_cscope_ctag = "null"
let g:cscope_backend = "null"
"end internal use"

"For debug print"
"default value 0"
if !exists('g:Auto_update_cscope_ctags_debug_log')
        let g:Auto_update_cscope_ctags_debug_log = 0
endif

"For lock reflash Time:"
"default value 15"
"g:Auto_update_cscope_ctags_timer_filter"
"                   this time for filter modify frequency"
"                   if you want to see database update immediately"
"                   you can modify to 10s or 1s, which I do not suggest"
"                   ,caused by csocpe or ctags gen database may take a"
"                   big occupy on disk,you can override at .vimrc"
if !exists('g:Auto_update_cscope_ctags_timer_filter')
        let g:Auto_update_cscope_ctags_timer_filter = 15
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

"copyright: line 99- line 245, somecode ref form: autoload_cscope_ctags.vim
"which from Michael Conrad Tadpol Tilsra
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
" Unload_csdb
"  drop cscope connections.
function s:Unload_csdb()
  if exists("g:csdbpath")
    if cscope_connection()
      let save_csvb = &csverb
      set nocsverb
      exe "cs kill " . g:csdbpath
      set csverb
      let &csverb = save_csvb
    endif
  endif
  execute 'set tags ='
endfunc
"
"==
" Cycle_csdb
"  cycle the loaded cscope db.
function s:Cycle_csdb()
    if exists("g:csdbpath")
      if cscope_connection()
        return
        "it is already loaded. don't try to reload it.
      endif
    endif
    "Now we support two type cscope backend: cscope and global
    "about global, please reference https://www.gnu.org/software/global/
    let newcsdbpath = s:Find_in_parent("GTAGS",s:windowdir(),$HOME)
    if newcsdbpath != "Nothing"
      let g:cscope_backend = "global"
    else
      let newcsdbpath = s:Find_in_parent("cscope.out",s:windowdir(),$HOME)
      if newcsdbpath != "Nothing"
        let g:cscope_backend = "cscope"
      else
        let g:cscope_backend = "null"
      endif
    endif

    "if readbuffer is python file && at the new dir can not find
    "databse we will try to load old databse, caused by we need
    "use old database when in python lib file
    if newcsdbpath != "Nothing"
	    let g:for_auto_update_cscope_ctag = newcsdbpath
    else
	    let g:for_auto_update_cscope_ctag = "Nothing"
    endif
    if g:for_auto_update_cscope_ctag != "Nothing"
      let g:csdbpath = g:for_auto_update_cscope_ctag
      if !cscope_connection()
        let save_csvb = &csverb
        set nocsverb
        "FIX global issue: more detail https://www.gnu.org/software/global/
        "so we chdir home dir to g:csdbpath
        if 'null' != g:csdbpath
          exe "chdir " . g:csdbpath
        endif
        if g:cscope_backend == "global"
          set cscopeprg=gtags-cscope
          exe "cs add " . g:csdbpath . "/GTAGS " .g:csdbpath
        elseif g:cscope_backend == "cscope"
          set cscopeprg=cscope
          exe "cs add " . g:csdbpath . "/cscope.out " .g:csdbpath
        endif
        set csverb
        let &csverb = save_csvb
	"echo "Found cscope tag at: " . g:csdbpath
	"echo "Windowdir: " . s:windowdir()
	"we think ctags file should at the same dir
	"so try to update ctags file when proj chang from A to B
	if filereadable(g:csdbpath . "/tags")
		"echo "Found tags at: " . g:csdbpath
		execute 'set tags ='. g:csdbpath . '/tags'
	else
		"echo "No tags"
		execute 'set tags ='
	endif
      endif
    else " No cscope database, undo things. (someone rm-ed it or somesuch)
      call s:Unload_csdb()
    endif
endfunc

" auto toggle the menu
augroup autoload_cscope
 au!
 au BufNewFile,BufEnter *  call <SID>Cycle_csdb()
 au BufUnload * call <SID>Unload_csdb()
augroup END

let &cpo = s:save_cpo
if g:in_cmdline_mode_t_load == 0
  let g:in_cmdline_mode_t_load = 1
  autocmd CmdwinEnter * let g:in_cmdline_mode_t = 1
  autocmd CmdwinLeave * let g:in_cmdline_mode_t = 0
endif

command! -nargs=0 -bar Manualstartstopautoupdatedatabas
    \  call <SID>Manual_start_stop_auto_update_database(0)

command! -nargs=0 -bar Manualupdatedatabaseonetime
    \  call <SID>Auto_update_cscope_ctags(3)

command! -nargs=0 -bar Createtag
    \  call <SID>Manual_start_stop_auto_update_database(1)

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
        echo "if input 'not_kernel', means: do not build a especially arch, but we do not suggest at a kernel tree"
        let g:arch_str = input("please input a ARCH: ")
        while ! has_key(g:vim_arch_parameter_d, g:arch_str)
            echo " "
            echo " "
            echo ">>>>>>>>Do not support " . "ARCH = ". g:arch_str
            echo " "
            echo "For example, if you just care ARM64 platform code, just need input arm64"
            let g:arch_str = input("please input a ARCH: ")
        endwhile
    else
        let g:arch_str = "not_kernel"
    endif

    echo " "
    if cscope_connection() > 0
        let g:to_user_suggest_tag_dir_str_vim = g:csdbpath
        echo "Already find database at: " . g:csdbpath
    endif
    if "not_kernel" == g:arch_str
        let b:tmp_dir_i = 'null'
        echo " "
        echo "Customization for tag dir for 'not_kernel' project"
        echo "please input a dir you want ,default dir = " . g:to_user_suggest_tag_dir_str_vim
        echo "Press 'Enter' to use default dir [" . g:to_user_suggest_tag_dir_str_vim . "]"
        \ . " or input dir which you tend to"
        let b:tmp_dir_i = input("Press 'ENTER' or  input a dir string: ")
        if "" == b:tmp_dir_i
            echo " "
            echo "use suggest dir[ " . g:to_user_suggest_tag_dir_str_vim . " ]" 
        else
            echo " "
            let g:to_user_suggest_tag_dir_str_vim = b:tmp_dir_i
            echo "use Customization dir[ " . g:to_user_suggest_tag_dir_str_vim . " ]"
          endif
    endif

"config cscope backend,default default gnu-global
  echo " "
  echo "Config cscope backend engine, Now support [cscope] and [global]"
  echo "[global] detail: https://www.gnu.org/software/global/"
  let b:cscope_engine_d = {'global':'1', 'cscope':'1'}
  let b:engine = input("Press ENTER to use Default 'global'>>> ")
  if b:engine == ''
    let b:engine = 'global'
  endif
  while ! has_key(b:cscope_engine_d, b:engine)
    echo " "
    echo " "
    echo ">>>>>>>>Do not support " . "cscope engine = ". b:engine
    echo " "
    echo "Now support [cscope] and [global]"
    let b:engine = input("Press ENTER to use Default 'global', or input global or cscope>>> ")
    if b:engine == ''
      let b:engine = 'global'
    endif
  endwhile
  echo " "
  let g:cscope_backend = b:engine
  echo "Customization cscope backend engine to " .g:cscope_backend

    if cscope_connection() > 0
      if g:cscope_backend == 'global'
        let b:clear_cscope = 'rm ' . g:csdbpath . '/cscope.*'
        let cmd_output = system(b:clear_cscope)
      elseif g:cscope_backend == 'cscope'
        let b:clear_gtags = 'rm ' . g:csdbpath . '/GTAGS;' . 'rm ' . g:csdbpath . '/GPATH;' . 'rm ' . g:csdbpath . '/GRTAGS'
        let cmd_output = system(b:clear_gtags)
      endif
      if g:to_user_suggest_tag_dir_str_vim != g:csdbpath
        echo " "
        echo "+++++change database dir, so need remove old++++++"
        let b:remove_old_cscope = 'rm ' . g:csdbpath . '/cscope.*'
        let cmd_output = system(b:remove_old_cscope)
        let remove_old_tags = 'rm ' . g:csdbpath . '/tags'
        let cmd_output = system(remove_old_tags)
        let remove_old_dir = 'rm ' . g:csdbpath . '/.auto_cscope_ctags -rf'
        let cmd_output = system(remove_old_dir)
      endif
    endif

if has('pythonx')
pyx << EOF
import vim
import os
handle_dir = vim.eval("g:to_user_suggest_tag_dir_str_vim")
sub_dir = []
os.chdir(handle_dir)
old_dir = os.getcwd()
try:
	f = os.listdir(handle_dir)
	for i in f:
		if os.path.isdir(i) and i != '.auto_cscope_ctags' and i != '.' and i != '..' and i != '.git':
			sub_dir.append(i)
except OSError:
	print("can not find dir: %s" % handle_dir)
os.chdir(old_dir)

sub_dir_s = "Dir list:[ "
if len(sub_dir):
	vim.command("let g:find_sub_dir = 'yes'")
	for i in sub_dir:
		if i != '.auto_cscope_ctags' and i != '.' and i != '..' and i != '.git':
			sub_dir_s = sub_dir_s + ' ' + i
	vim.command("let g:sub_dir_s = '%s'" % sub_dir_s)
else:
	vim.command("let g:find_sub_dir = 'no'")
EOF
else
	echo "do not support python"
endif

if "not_kernel" == g:arch_str
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

  echo " "
  echo "Config Do not care about dir,Please split with space eg: A B"
  if 'no' == g:find_sub_dir
    echo "no sub dir find at: " . g:to_user_suggest_tag_dir_str_vim
    let g:do_not_care_dir = "no"
  else
    echo "Find dir at " . g:to_user_suggest_tag_dir_str_vim . ":"
    echo g:sub_dir_s . "  ]"
    let g:do_not_care_dir = input("input Enter means do not config>>> ")
    if 0 == strlen(g:do_not_care_dir)
      echo " "
      echo "Do not config do_not_care_dir"
      let g:do_not_care_dir = "no"
    else
      echo " "
      echo "Customization config do_not_care_dir: " . g:do_not_care_dir
    endif
  endif
endif

    let g:run_c = "python " .g:create_tag_run_py_ret_vim . " -a " .g:arch_str . " -d "
      \. "cscope_and_ctags" . " -p " .g:to_user_suggest_tag_dir_str_vim . " -m "
      \. " -s " .g:enable_soft_link_file . " -e " .g:cscope_backend . " -r " . "'" . g:do_not_care_dir ."'"
    echo " "
    echo "Will run command:\n" . g:run_c
    echo " "
    echo " "
    echo "Do you really want to  create tag at dir: [" . g:to_user_suggest_tag_dir_str_vim . "]?"
    echo "Yes: please input yes start, will take a while(depend on code size and I/O performance)"
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
    if g:cscope_backend == "global"
      set cscopeprg=gtags-cscope
      exe "cs add " . g:to_user_suggest_tag_dir_str_vim . "/GTAGS " . g:to_user_suggest_tag_dir_str_vim
    elseif g:cscope_backend == "cscope"
      set cscopeprg=cscope
      exe "cs add " . g:to_user_suggest_tag_dir_str_vim . "/cscope.out " . g:to_user_suggest_tag_dir_str_vim
    endif
    let g:csdbpath = g:to_user_suggest_tag_dir_str_vim
    let g:for_auto_update_cscope_ctag = g:to_user_suggest_tag_dir_str_vim

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
if has('pythonx')
pyx << EOF
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

if has('pythonx')
pyx << EOF
import vim
import os
import time
import platform
import string
import sys
import time
import getpass
import psutil

global_log_file = '/tmp/.Auto_update_cscope_ctags_debug_log.log'
arch_parameter_list = ['not_kernel']

def debug_python_print(str):
    enable_debug_log = int(vim.eval("g:Auto_update_cscope_ctags_debug_log"))

    if 1 == enable_debug_log:
        f = open(global_log_file,'a')
        with open(global_log_file, 'a') as f:
            f.write('\n')
            f.write('%s: ' % time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())))
            f.write('%s' % str)
            f.write('\n')
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
'BUILD', '.bzl', 'BUILD', '.hpp', '.launch', '.asm', '.ec', '.pgc', '.m', \
'.cxx', '.pcc', '.H', '.hh', '.cu', '.prototxt', '.opencl', '.cl', '.cmake', \
'.dtsi', '.dts']):

    ret = 0
    cmp_file = directory + '/tags.files'
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
                debug_python_print("Already Found first update file %s, quick return" % i)
                return ret
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
            '''
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
            '''
            cmd_may_file = int(i_lock_buffer[0].strip())
            try:
              compare_cmd = "%s" % psutil.Process(cmd_may_file).cmdline()
              if i_lock_buffer[1].strip() == compare_cmd:
                debug_python_print("lock_check_pid success: really valid lock")
                ret = 1
              else:
                debug_python_print("diff proccess new = %s %d" % (compare_cmd, len(compare_cmd)))
                debug_python_print("diff proccess old = %s %d" % (i_lock_buffer[1].strip(), len(i_lock_buffer[1].strip())))
                ret = -1
            except psutil._exceptions.NoSuchProcess:
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
        '''
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
        '''
        btime_l_int = int(psutil.boot_time())
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
    max_read_line = 1
    ret = 'null'
    head_of_check_file = []
    check_file = directory + '/.auto_cscope_ctags/.arch_type'
    if os.path.exists(check_file):
        debug_python_print("Check cscope type!")
        #try to read first line from .auto_cscope_ctags/.arch_type
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

        ret = head_of_check_file[0]
        debug_python_print("Arch type: %s" % ret)

        return ret

    else:
        Warn_print("Err: can not find file %s" % check_file)

    return ret

def get_backup_run_py():

    ret = 'null'
    user_name = getpass.getuser()
    may_backup_run_py_file_tmp = vim.eval("g:auto_update_cscope_ctags_backup_run_py_name_cache")
    if 0 <= may_backup_run_py_file_tmp.find('~'):
        debug_python_print('use ~ for user name convert it')
        may_backup_run_py_file = may_backup_run_py_file_tmp.replace('~', '%s') % \
                os.path.expanduser('~')
    else:
        may_backup_run_py_file = may_backup_run_py_file_tmp

    if os.path.exists(may_backup_run_py_file):
        debug_python_print("cache back run python %s success" % may_backup_run_py_file)
        ret = may_backup_run_py_file
    else:
        hard_search_dir = '%s/.vim/' % os.path.expanduser('~')
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
        #if os.path.exists(force_file):
        if True:
            os.chdir(old_dir)
            debug_python_print("sure be kernel_tree, not we update ARCH list")
            arch_dir = cache_dir + "/arch"
            may_arch = os.listdir(arch_dir)
            #debug_python_print(may_arch)
            may_arch_string = "{\'not_kernel\'"+":\'1\'"
            for i in may_arch:
                if os.path.isdir(arch_dir + "/" + i):
                    arch_parameter_list.append(i)
                    may_arch_string = may_arch_string + ", \'" + i + "\'" + ":\'1\'"

            may_arch_string = may_arch_string + "}"
            update_arch_list_to_vim = "let g:vim_arch_parameter_d = " + may_arch_string
            #debug_python_print(update_arch_list_to_vim)
            vim.command(update_arch_list_to_vim)

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
    check_file = directory + '/tags.files'
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

def vim_trap_into_python_interface():

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

    if 1 == Create_Mode_I:
        default_tag_dir = vim.eval("g:curbufferpwd")
        print("Now try to Create cscope and ctags database")
        vim.command("let g:create_tag_run_py_ret_vim = '0'")
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
            Warn_print("A not_kernel project will create")
            vim.command("let g:Createtag_need_input_arch = 0")
            #vim python do not support input, so we will retrun to vim env after print
            #input_str = 'null'
            #input_str = input("Please input cpu ARCH:")
            #while input not in arch_parameter_list:
            #    print("Support ARCH:")
            #    print(arch_parameter_list)
            #    input_str = raw_input("Please input a vaild cpu ARCH:")

        #before return we need return back_run_python_dir and put to_user_suggest_tag_dir to vim
        #set a err status firstly
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
                backend = vim.eval("g:cscope_backend")
                back_run_cmd = "python %s -a %s -d %s -p %s -s ignore -e %s -r ignore &" % (run_py_ret, handle_arch, "cscope_and_ctags", may_tags_dir, backend)
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

vim_trap_into_python_interface()
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
