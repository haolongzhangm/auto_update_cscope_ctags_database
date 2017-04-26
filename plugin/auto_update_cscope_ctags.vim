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

command! -nargs=0 -bar Manualstartstopautoupdatedatabase
    \  call <SID>Manual_start_stop_auto_update_database()

if g:auto_run_function_when_cscope_connect == 1
	if g:Auto_update_cscope_ctags_running_status == 0
		"echo "auto enable tags upload""
		if g:autocommands_loaded == 0
		  let g:autocommands_loaded = 1
		  autocmd BufWritePost * call <SID>Auto_update_cscope_ctags()
		endif
		let g:Auto_update_cscope_ctags_running_status = 1
	endif
endif


function! <SID>Manual_start_stop_auto_update_database()
if g:Auto_update_cscope_ctags_running_status == 0
    echo "Manual start auto update tag database"
	if g:autocommands_loaded == 0
	  let g:autocommands_loaded = 1
	  autocmd BufWritePost * call <SID>Auto_update_cscope_ctags()
	endif
    let g:Auto_update_cscope_ctags_running_status = 1
else
    echo "Manual stop auto update tag database"
    let g:Auto_update_cscope_ctags_running_status = 0
    return 0
endif

endfunction

function! <SID>Auto_update_cscope_ctags()

	if g:Auto_update_cscope_ctags_running_status == 0
		"echo "Already stop, just return""
		return 0
	endif

	if cscope_connection() <= 0
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
arch_parameter_list = ['normal', 'alpha', 'arm', 'arm64', 'avr32', \
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
            Err_print("ERR: invaild file %s " % check_file)
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
        Err_print("Err: can not find file %s" % check_file)

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

def main_loop():

    may_tags_dir = vim.eval("g:for_auto_update_cscope_ctag")

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
                Err_print("Err: ARCH: %s do not support" % handle_arch)
                return -1

            run_py_ret = get_backup_run_py()
            if 'null' != run_py_ret and os.path.exists(run_py_ret):
                #vim script api do not support blocking time I/O, so we and '&' here
                pre_create_lock_cmd = "cd %s 1>/dev/null 2>&1; mkdir .auto_cscope_ctags 1>/dev/null 2>&1; \
                        touch .auto_cscope_ctags/lock 1>/dev/null 2>&1" % may_tags_dir
                os.system(pre_create_lock_cmd)
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
