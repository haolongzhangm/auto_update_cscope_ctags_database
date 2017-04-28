"author : haolong.zhang@ck-telecom.com"
"v0.5: 20170426 init func"
"Running status"
"do not modify, internal use"
let g:Auto_update_cscope_ctags_running_status = 0
let g:autocommands_loaded = 0

"For debug print"
"default value 0"
if !exists('g:Auto_update_cscope_ctags_debug_log')
        let g:Auto_update_cscope_ctags_debug_log = 0
endif

"For lock reflash Time:"
"default value 60"
"g:Auto_update_cscope_ctags_lock_floor_min"
"                   this time for filter modify frequency"
"                   if you want to see database update immediately"
"                   you can modify to 10s or 1s, which I do not suggest"
"                   ,caused by csocpe or ctags gen database may take a"
"                   big occupy on disk,you can override at .vimrc"
if !exists('g:Auto_update_cscope_ctags_lock_floor_min')
        let g:Auto_update_cscope_ctags_lock_floor_min = 60
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
        let g:auto_update_cscope_ctags_backup_run_py_name_cache = '~/.vim/plugin/auto_update_cscope_ctags_backup_run.py'
endif

"g:auto_run_function_when_cscope_connect"
"default 1"
"			:when find cscope connect/first load"
"			or buffers swith"
if !exists('g:auto_run_function_when_cscope_connect')
        let g:auto_run_function_when_cscope_connect = 1
endif

command! -nargs=0 -bar Manualstartstopautoupdatedatabas
    \  call <SID>Manual_start_stop_auto_update_database(0)

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
        let g:arch_str = input("please input a ARCH: ")
        while ! has_key(vim_arch_parameter_d, g:arch_str)
            echo " "
            echo " "
            echo ">>>>>>>>Do not support " . g:arch_str . " ARCH"
            echo " "
            let g:arch_str = input("please input a ARCH: ")
        endwhile
    else
        let g:arch_str = "normal"
    endif

    echo " "
    let g:run_c = "python " . " " .g:create_tag_run_py_ret_vim . " " . g:arch_str . " cscope_and_ctags " . g:to_user_suggest_tag_dir_str_vim
    echo "Will run command:\n" . g:run_c
    echo " "
    echo " "
    echo " "
    echo " "
    echo "Do not really want to  create tag at dir: [" . g:to_user_suggest_tag_dir_str_vim . "]?"
    echo "Yes: please input yes start, will take about one minutes"
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
    exe "cs add " . g:to_user_suggest_tag_dir_str_vim . "/cscope.out " . g:to_user_suggest_tag_dir_str_vim
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
if has('python') || has('python3')
python << EOF
import vim
find_tmp_str = vim.eval("l:Findcomand_args")
find_command_str = "let g:curbufferpwd = '%s'" %  (find_tmp_str[:find_tmp_str.rindex("/")])
vim.command(find_command_str)
EOF
else
	echo 'Pls build vim with python'
endif
endfunction

function! <SID>Auto_update_cscope_ctags(create_mode)

        if 1 == a:create_mode
            call <SID>FindBufferReallyPwd()
            let g:Create_Mode = 1
        else
            let g:Create_Mode = 0
        endif

	if g:Auto_update_cscope_ctags_running_status == 0 && 0 == g:Create_Mode
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
'.py', '.S']):

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

def check_lock_status_and_time(lock_str):
    # ret 0: lock release , 1 lock do not release, 
    #2, lock fresh, 3: lock too old, -1, config err
    ret = -1
    if os.path.exists(lock_str):
        debug_python_print("Find lock %s" % lock_str)
        now_time = time.time()
        md_time = os.stat(lock_str).st_mtime
        md_time_pass = now_time - md_time
        debug_python_print("lock md time pass %s" % (md_time_pass))
        lock_reflash_min = int(vim.eval("g:Auto_update_cscope_ctags_lock_floor_min"))
        lock_reflash_max = int(vim.eval("g:Auto_update_cscope_ctags_lock_floor_max"))
        if lock_reflash_min >= lock_reflash_max:
            ret = -1
            Err_print("Err: config g:Auto_update_cscope_ctags_lock_floor_min g:Auto_update_cscope_ctags_lock_floor_max ERR")
            return ret

        if md_time_pass <= lock_reflash_min:
            ret = 2
            debug_python_print("Reflash to quick, ingore this time")
        elif md_time_pass >= lock_reflash_max:
            debug_python_print("Lock to old, need remove it")
            ret = 3
        else:
            debug_python_print("Lock %s locked, wait... " % lock_str)
            ret = 1
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
        #try to read fisrt three line from cscope.files
        f = open(check_file, 'r')
        if 0 == os.path.getsize(check_file):
            Warn_print("ERR: invaild file %s " % check_file)
            return ret

        for line in f:
            i = i+1
            debug_python_print('line %s in csocpe.files = %s' % (i, line))
            head_of_check_file.append(line.replace('/$', '').strip())
            if max_read_line == i:
                break

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

def main_loop():

    may_tags_dir = vim.eval("g:for_auto_update_cscope_ctag")
    Create_Mode_I = int(vim.eval("g:Create_Mode"))
    #set a err status fisrtly
    vim.command("let g:create_tag_run_py_ret_vim = '0'")
    if 1 == Create_Mode_I:
        default_tag_dir = vim.eval("g:curbufferpwd")
        ret_check_lock_status_and_time = check_lock_status_and_time(default_tag_dir + "/.auto_cscope_ctags/lock")
        if 1 == ret_check_lock_status_and_time or 2 == ret_check_lock_status_and_time:
            Warn_print("anthor update proccess go..., pls wait a moment to try ")
            return 0
        print("Now try to Create cscope and ctags database")
        if not os.path.exists(default_tag_dir):
            Warn_print("invaild default_tag_dir = %s" % default_tag_dir)
            return 0

        debug_python_print("creat tag: find default_tag_dir = %s" % default_tag_dir)
        (to_user_suggest_tag_dir, kernel_tree) = check_kernel_code_characteristic(default_tag_dir)
        if not os.path.exists(to_user_suggest_tag_dir):
            Warn_print("Err happned invaild dir = %s" % to_user_suggest_tag_dir)
            return 0

        if 'true' == kernel_tree:
            Warn_print("we find kernel code tree at %s" % to_user_suggest_tag_dir)
            Warn_print("Support ARCH:")
            Warn_print(arch_parameter_list)
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
    if 1 == check_lock_status_and_time_ret or 2 == check_lock_status_and_time_ret:
        return 0

    if 3 == check_lock_status_and_time_ret:
        #checn file exists again for use rm command is so danger
        lock_file = "%s/.auto_cscope_ctags/lock" % may_tags_dir
        if os.path.exists(lock_file):
            rm_lock_cmd = "rm %s  1>/dev/null  2>&1" % lock_file
            debug_python_print("rm lock file %s" % lock_file)
            os.system(rm_lock_cmd)

    if 0 == check_lock_status_and_time_ret or 3 == check_lock_status_and_time_ret:
        file_result = scan_f_new(may_tags_dir)
        if file_result > 0:
            handle_arch = check_cscope_files_type(may_tags_dir)
            if handle_arch not in arch_parameter_list:
                Warn_print("Err: ARCH: %s do not support" % handle_arch)
                return -1

            run_py_ret = get_backup_run_py()
            if 'null' != run_py_ret and os.path.exists(run_py_ret):
                #vim script api do not support blocking time I/O, so we and '&' here
                #why do not use vim timer: long time I/O may cause vim exit err
                back_run_cmd = "python %s %s %s %s &" % (run_py_ret, handle_arch, "cscope_and_ctags", may_tags_dir)
                debug_python_print(back_run_cmd)
                os.system(back_run_cmd)

        elif file_result == 0:
            debug_python_print("no need update")
        else:
            debug_python_print("can not find tags, for later function")
            return 0

main_loop()
EOF
else
    echo "auto update cscope ctags err: Pls build vim with python"
endif

endfunction
