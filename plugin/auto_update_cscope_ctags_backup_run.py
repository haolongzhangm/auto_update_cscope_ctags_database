#by haolong.zhang@ck-telecom.com 20170426
import os
import glob
import sys
import time
import getpass
import threading
import getopt
import psutil
import platform

arch_parameter_list = ['not_kernel']

care_file_type = ['*.c', '*.cpp', '*.h', '*.cc', '*.java', '*.sh', 
        '*.mk', '*.prop', '*.xml', 'Makefile', '*.rc', 'platform', 
        'Drivers', '*.scons', '*.api', '*.tla', '*.smh', '*.smi', 
        '*.smt', '*.idl', '*.te', '*.py', '*.S', '*.tpl', '*.css',
        '*.js', '*.txt', '*.proto', '*.md', '*.conf', '*.json',
        '*.BUILD', '*.bzl', 'BUILD', '*.hpp', '*.launch', '*.asm',
        '*.ec', '*.pgc', '*.m', '*.cxx', '*.pcc', '*.H', '*.hh',
        '*.cu', '*.prototxt', '*.opencl', '*.cl', '*.cmake']

needed_env_list = ['python', 'cscope', 'sed', 'ctags']

global_back_run_log_file = '/tmp/.Auto_update_cscope_ctags_debug_back_run.log'

global_debug_enable = -1

cscope_backend = 'global'
cscope_backend_list = ['global', 'cscope']

database_type_list = ['cscope_only', 'cscope_and_ctags']
support_soft_link_list = ['yes', 'no', 'ignore']

arch_type_str = 'not_kernel'
database_type_str = 'cscope_and_ctags'
pwd_dir_str = './'
show_msg_bool = False
support_soft_link_str = 'ignore'
do_not_care_dir = 'ignore'
ctags_append_mode = True

def parse_args():

    global arch_type_str
    global database_type_str
    global pwd_dir_str
    global show_msg_bool
    global support_soft_link_str
    global cscope_backend
    global do_not_care_dir
    global ctags_append_mode

    if 1 >= len(sys.argv):
        Warnin_print("Err: too few args")
        Usage()

    try:
        optlist, args = getopt.getopt(sys.argv[1:], "hms:a:p:d:e:r:")
    except getopt.GetoptError:
        Warnin_print('args err')
        Usage()

    for c, value in optlist:
        if '-h' == c:
            Usage()
        elif '-m' == c:
            show_msg_bool = True
        elif '-s' == c:
            support_soft_link_str = value
        elif '-a' == c:
            arch_type_str = value
        elif '-p' == c:
            pwd_dir_str = value
        elif '-d' == c:
            database_type_str = value
        elif '-e' == c:
            cscope_backend = value
        elif '-r' == c:
            do_not_care_dir = value

    if show_msg_bool:
        Warnin_print('args:')
        Warnin_print(  optlist)


def Usage():
    Warnin_print('v4.0')
    Warnin_print('python %s [hms:a:p:d:y:]' % sys.argv[0])
    Warnin_print(' -h: show help info')
    Warnin_print(' -m: show msg')
    Warnin_print(' -s: support_soft_link or not')
    Warnin_print(' -a: arch type')
    Warnin_print(' -p: project pwd_dir')
    Warnin_print(' -d: databse type')
    Warnin_print(' -e: config cscope backend engine')
    exit()

def check_args():
    if arch_type_str not in arch_parameter_list:
        Warnin_print('Do not support ARCH: %s' % arch_type_str)
        Warnin_print('only support arch:')
        Warnin_print(arch_parameter_list)
        Usage()

    if database_type_str not in database_type_list:
        Warnin_print('Do not support database_type: %s' % database_type_str)
        Warnin_print('only support database type')
        Warnin_print(database_type_list)
        Usage()

    if support_soft_link_str not in support_soft_link_list:
        Warnin_print('Do not support soft link config: %s' % support_soft_link_str)
        Warnin_print('only support soft link config')
        Warnin_print(support_soft_link_list)
        Usage()

    if cscope_backend not in cscope_backend_list:
        Warnin_print('Do not support cscope_backend: %s' % cscope_backend)
        Warnin_print('only support cscope_backend type')
        Warnin_print(cscope_backend_list)
        Usage()

def find_python_install_lib():
    valid_python_lib_dir = False
    pythonlib_install_i = []
    for dir_i in global_pythonlib_dir_str:
        if os.path.exists(dir_i):
            i_list = os.listdir(dir_i)
            for i in i_list:
                if 'python' in i:
                    pythonlib_install_i.append(dir_i+i)

    if len(pythonlib_install_i) > 0:
        valid_python_lib_dir = True

    return (valid_python_lib_dir, pythonlib_install_i)

def check_os_cmd_exist(str):
    ret = 0
    popen_str = "which " + str + ' 2>&1'
    debug_backrun_python_print("popen_str = %s" % popen_str)
    if '' == os.popen(popen_str).read():
        ret = 0
    else:
        ret = 1

    return ret

#if find match filetyle, will return true
def check_include_filetyle_or_not(filetyle_str):
    ret = False
    popen_str = "find -name " + filetyle_str + ' 2>&1'
    debug_backrun_python_print("popen_str = %s" % popen_str)
    if '' == os.popen(popen_str).read():
        ret = False
    else:
        ret = True

    return ret

def gnome_osd_print(str):
    if 1 == check_os_cmd_exist("notify-send"):
        debug_backrun_python_print("find command: notify-send")
        #ubuntu default notify-osd will ignore -t parameter(default 10s)
        #if u want to -t 2000 take effect, u can install notify-osd
        #by command:
        #sudo add-apt-repository ppa:leolik/leolik
        #sudo apt update
        #sudo apt install notify-osd
        cmd_str = "notify-send -t 2000 " + '\"' + str + '\"'+ " &"
    elif 1 == check_os_cmd_exist("gnome-osd-client"):
        debug_backrun_python_print("find command: gnome-osd-client")
        cmd_str = "gnome-osd-client -f "  + '\"' + "<message id=" + '\'' + \
            "auto_update_tags" + '\'' + " osd_fake_translucent_bg=" + \
            '\'' + "on" + '\'' + " osd_vposition=" + '\'' + "bottom" + \
            '\'' + " animations=" + '\'' + "off" + '\'' + " hide_timeout=" + \
            '\'' + "4000" + '\'' + " osd_halignment=" + '\'' + "center" + '\'>' \
            + str + "</message>" + '\"&'
    elif 1 == check_os_cmd_exist("osascript"):
        cmd_str = "osascript -e '\''display notification"  + '\"' + str + '\"' + \
                "with title" + '\"' + "vim database updater" + '\"' + '\''
    else :
        debug_backrun_python_print("can not find gnome_osd_print and notify-send, do not show GUI message")
        return 0

    debug_backrun_python_print(cmd_str)
    os.system(cmd_str)

def debug_backrun_python_print(str):

    user_name = getpass.getuser()
    vimrc_file = '/home/%s/.vimrc' % user_name

    global global_debug_enable
    if -1 == global_debug_enable:
        global_debug_enable = 0
        if os.path.exists(vimrc_file):
            try:
                f = open(vimrc_file, 'r')
            except:
                return 0

            for line in f:
                if 0 <= line.find('let g:Auto_update_cscope_ctags_debug_log = 1'):
                    global_debug_enable = 1
                    break

            f.close()

    if 1 == global_debug_enable:
        with open(global_back_run_log_file, 'a') as f:
            f.write('\n')
            f.write('%s: ' % time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())))
            f.write('%s' % str)
            f.write('\n')
    else:
        return 0

def Warnin_print(str):
    debug_backrun_python_print(str)
    print(str)

def global_version_check():
    if 0 == check_os_cmd_exist('gtags'):
        return 0
    else:
        popen_str = "gtags --version" + ' 2>&1'
        debug_backrun_python_print("popen_str = %s" % popen_str)
        t = os.popen(popen_str).read()
        "index 4 is version id,eg gtags (GNU GLOBAL) 6.6.2"
        try:
            v = int(t.split()[3].replace('.', ''))
        except ValueError:
            v = int(t.split()[4].replace('.', ''))

        if v < 662:
            return 0
        else:
            return 1

def gen_cscope_and_ctag_file():
    #if you kernel do not support command: make cscope ARCH=arm
    #or not kernel code

    misc_start_time = time.time()
    if not os.path.exists(pwd_dir_str):
        Warnin_print("Err :invalid pwd_dir_str: %s" % pwd_dir_str)
        return 0

    #check needed env
    for env_i in needed_env_list:
        if 0 == check_os_cmd_exist(env_i):
            Warnin_print("ERR: can not find %s pls install it fistly" % env_i)
            exit(-1)

    if cscope_backend == 'global':
        if 0 == global_version_check():
            Warnin_print("ERR: can not find gtags or gtags version too low(at least 6.6.2)")
            Warnin_print("please upgrade gtags from: https://www.gnu.org/software/global/download.html")
            exit(-1)

    debug_backrun_python_print(arch_type_str)
    gnome_osd_print('%s project update tags start' % arch_type_str)
    os.chdir(pwd_dir_str)

    if (os.path.isfile('./cscope.out') or os.path.isfile('./GTAGS')) \
            and os.path.isfile('./tags') \
            and os.path.isfile('./.auto_cscope_ctags/.old_tags.files'):
        ctags_append_mode = True
    else:
        ctags_append_mode = False

    pre_create_lock_cmd = "mkdir .auto_cscope_ctags 1>/dev/null 2>&1; \
            touch .auto_cscope_ctags/lock 1>/dev/null 2>&1; sync ;\
            rm .auto_cscope_ctags/cscope_detect_wait 1>/dev/null 2>&1"
    debug_backrun_python_print("now create lock now")
    os.system(pre_create_lock_cmd)
    debug_backrun_python_print("end create lock now")
    #write arch_type_str to .auto_cscope_ctags/.arch_type
    to_arch_type_str_cmd = "echo %s > .auto_cscope_ctags/.arch_type" % arch_type_str
    os.system(to_arch_type_str_cmd)

    if os.path.exists('.auto_cscope_ctags/lock'):
        write_to_lock = 0
        self_name  = ''
        debug_backrun_python_print("now write pid to lock")
        self_pid = os.getpid()
        '''
        self_cmd_str = "/proc/%s/cmdline" % self_pid
        if os.path.exists(self_cmd_str):
            f = open(self_cmd_str, 'r')
            for i_line in f:
                self_name = i_line
                #only read fistl line
                write_to_lock = 1
                break
        else:
            write_to_lock = 0

        if 1 == write_to_lock:
            str_to_lock = "%s\n%s\n" % (self_pid, self_name)
            debug_backrun_python_print("str_to_lock %s" % str_to_lock)
            f = open('.auto_cscope_ctags/lock', 'w+')
            f.write(str_to_lock)
            f.close()
        '''
        process_name = psutil.Process(self_pid).cmdline()
        str_to_lock = "%s\n%s\n" % (self_pid, process_name)
        debug_backrun_python_print("str_to_lock %s" % str_to_lock)
        f = open('.auto_cscope_ctags/lock', 'w+')
        f.write(str_to_lock)
        f.close()

        debug_backrun_python_print("end write pid to lock")
    else:
        Warnin_print("create lock failed, may caused by I/O permmison!")


    #config soft link
    if 'yes' == support_soft_link_str:
        mark_soft_link_exe = "touch .auto_cscope_ctags/.enable_soft_link_file 1>/dev/null 2>&1"
    elif 'no' == support_soft_link_str:
        mark_soft_link_exe = "rm .auto_cscope_ctags/.enable_soft_link_file 1>/dev/null 2>&1"

    if 'yes' == support_soft_link_str or 'no' == support_soft_link_str:
        debug_backrun_python_print(mark_soft_link_exe)
        os.system(mark_soft_link_exe)

    debug_backrun_python_print("do_not_care_dir config = %s" % do_not_care_dir)
    if 'ignore' != do_not_care_dir:
        if 'no' == do_not_care_dir:
            remove_do_not_care_exe = "rm .auto_cscope_ctags/.do_not_care_dir_detail 1>/dev/null 2>&1"
            os.system(remove_do_not_care_exe)
        else:
            remove_do_not_care_exe = "rm .auto_cscope_ctags/.do_not_care_dir_detail 1>/dev/null 2>&1"
            remove_do_not_care_exe = remove_do_not_care_exe + ";touch .auto_cscope_ctags/.do_not_care_dir_detail 1>/dev/null 2>&1"
            os.system(remove_do_not_care_exe)
            debug_backrun_python_print("remove_do_not_care_exe : %s" % remove_do_not_care_exe)
            #now update detail dir to .do_not_care_dir_detail
            valid_dir = []
            for i in do_not_care_dir.split():
                if os.path.isdir(i) and i != '.git' and i != '.auto_cscope_ctags' and i != '.' and i != '..':
                    valid_dir.append(i)
            if len(valid_dir):
                do_not_care_dir_s = ''
                for i in valid_dir:
                    do_not_care_dir_s = do_not_care_dir_s + ' ' + i

                with open('.auto_cscope_ctags/.do_not_care_dir_detail', 'a') as f:
                    f.write('%s' % do_not_care_dir_s)
                debug_backrun_python_print("Do not care about dir: %s" % do_not_care_dir_s)
            else:
                remove_do_not_care_exe = "rm .auto_cscope_ctags/.do_not_care_dir_detail 1>/dev/null 2>&1"
                os.system(remove_do_not_care_exe)

    if show_msg_bool:
        Warnin_print("misc config use time %s s" % (time.time() - misc_start_time))
    #now try to update tag.files
    #if arch in linux kernel, we will use 'from_linux_tags.sh' to gen files
    #if arch is not_kernel, we will use find to gen files
    update_tags_files(show_msg_bool)
    # add thread
    cscope_task = threading.Thread(target = cscope_task_func, args = (show_msg_bool, cscope_backend))
    ctags_task = threading.Thread(target = ctags_task_func, args = (show_msg_bool, ctags_append_mode))

    cscope_task.start()
    ctags_task.start()
    if 1 == show_msg_bool:
        Warnin_print("")
        Warnin_print("cscope_task = %s" % cscope_task)
        Warnin_print("ctags_task = %s" % ctags_task)

    cscope_task.join()
    ctags_task.join()
    #end thread

    clear_lock_i()
    all_take_time  = time.time() - misc_start_time
    if 1 == show_msg_bool:
        Warnin_print("All finish take %s s" % all_take_time)
    else:
        debug_backrun_python_print("All finish take %s s" % all_take_time)

    gnome_osd_print('%s project update tags end' % arch_type_str)
    update_auto_cscope_ctags_dir_time_cmd = "cp tags.files .auto_cscope_ctags/.old_tags.files"
    os.system(update_auto_cscope_ctags_dir_time_cmd)

def clear_lock_i():
    end_remove_lock_cmd = "rm .auto_cscope_ctags/lock 1>/dev/null  2>&1"
    debug_backrun_python_print("now for remove_lock_cmd")
    os.system(end_remove_lock_cmd)
    debug_backrun_python_print("end for remove_lock_cmd")

def update_tags_files(show_message_enable):

    update_tags_files_start_time  = time.time()
    if 'not_kernel' == arch_type_str:
        not_kernel_cmd = "find"
        if os.path.exists('./.auto_cscope_ctags/.enable_soft_link_file'):
            not_kernel_cmd = not_kernel_cmd + " -L "

        not_kernel_cmd = not_kernel_cmd + " . "
        do_not_care_dir = []
        if os.path.exists('./.auto_cscope_ctags/.do_not_care_dir_detail'):
            with open('.auto_cscope_ctags/.do_not_care_dir_detail', 'r') as f:
                t = f.readline()
                for i in t.split():
                    if os.path.isdir(i) and i != '.git' and i != '.auto_cscope_ctags' and i != '.' and i != '..':
                        do_not_care_dir.append(i)

        if len(do_not_care_dir):
            s = ' '
            for i in do_not_care_dir:
                s = s + '-o -path ./%s -prune ' % i + ' '
            #remove
            ss = s[3:]
            debug_backrun_python_print("do_not_care_dir prune config: %s" % ss)
            not_kernel_cmd = not_kernel_cmd + ss
        else:
            not_kernel_cmd = not_kernel_cmd + " -type f -name '*.c' -print"
        for i_care_type in care_file_type:
            not_kernel_cmd = not_kernel_cmd + " -o  -type f -name " + '\'' + i_care_type + '\'' + " -print"

        not_kernel_cmd = not_kernel_cmd + " -o -type f -name '*config' -print"
        not_kernel_cmd = not_kernel_cmd + "> tags.files "

        #Warnin_print(not_kernel_cmd)

        debug_backrun_python_print(not_kernel_cmd)
        os.system(not_kernel_cmd)
        use_time_str = "update tags.files use time: %s s" % (time.time() - update_tags_files_start_time)
        if 1 == show_message_enable:
            Warnin_print(use_time_str)
        else:
            debug_backrun_python_print(use_time_str)

    else:
        kernel_gen_tags_files_file = sys.argv[0][:-38] + "from_linux_tags.sh"
        if not os.path.isfile(kernel_gen_tags_files_file):
           Warnin_print("Err can not find file %s" % kernel_gen_tags_files_file)
           exit(-1)
        kernel_cmd = kernel_gen_tags_files_file + " gtags %s %s ." % (arch_type_str, arch_type_str)
        if 0 == show_message_enable:
            kernel_cmd = kernel_cmd + " 1>/dev/null  2>&1"
        #else:
        #    Warnin_print(kernel_cmd)

        debug_backrun_python_print(kernel_cmd)
        os.system(kernel_cmd)
        use_time_str = "update tags.files use time: %s s" % (time.time() - update_tags_files_start_time)
        if 1 == show_message_enable:
            Warnin_print(use_time_str)
        else:
            debug_backrun_python_print(use_time_str)

def cscope_task_func(show_message_enable, backend):

    cscope_start_time = time.time()
    cscope_cmd = ''
    if backend == 'global':
        cscope_cmd = "gtags -i -f tags.files"
    elif backend == 'cscope':
        cscope_cmd = "cscope -bkq -i tags.files -f cscope.out"
    else:
        Warnin_print("Do not support cscope backend: %s" % backend)
        exit(-1)

    if not show_message_enable:
        cscope_cmd = cscope_cmd + " 1>/dev/null  2>&1"

    debug_backrun_python_print(cscope_cmd)
    debug_backrun_python_print("now for cscope")
    os.system(cscope_cmd)
    use_time_str = "cscope Use time = %s s with backend %s" % ((time.time() - cscope_start_time), backend)
    if 1 == show_message_enable:
        Warnin_print(use_time_str)
    else:
        debug_backrun_python_print(use_time_str)
    debug_backrun_python_print("end for cscope")

def ctags_task_func(show_message_enable, ctags_append_mode_i):

    ctags_task_start_time = time.time()
    if 'cscope_and_ctags' == database_type_str:
        debug_backrun_python_print("now for ctag")
        if ctags_append_mode_i:
            old_file_size = os.path.getsize("./.auto_cscope_ctags/.old_tags.files")
            new_file_size = os.path.getsize("./tags.files")
            debug_backrun_python_print("old_file_size = %d new_file_size = %d" % (old_file_size, new_file_size))
            if old_file_size != new_file_size:
                ctags_append_mode_i = False
        if ctags_append_mode_i:
            #find -newer file than ./.auto_cscope_ctags/.old_tags.files
            newer_cmd = "find . -name " + '\'' + "*.c" + '\'' + " -newer ./.auto_cscope_ctags/.old_tags.files"
            for i_care_type in care_file_type:
                newer_cmd = newer_cmd + " -o -name " + '\'' + i_care_type \
                        + '\'' + " -newer ./.auto_cscope_ctags/.old_tags.files "
            newer_cmd = newer_cmd + " > ./.auto_cscope_ctags/.tmp_update_file"
            debug_backrun_python_print("newer_cmd = %s" % newer_cmd)
            os.system(newer_cmd)
            #new check ./.auto_cscope_ctags/.tmp_update_file file real in tags.files
            #set ctags_append_mode_i to False fistly
            os.system("touch ./tags_append.files")
            with open("./.auto_cscope_ctags/.tmp_update_file", 'r') as f:
                lines = f.readlines()
                if len(lines) > 0:
                    with open("./tags.files", 'r') as fc:
                        with open("./tags_append.files", 'w') as ft:
                            fc_lines = fc.readlines()
                            for line in lines:
                                #May need check performance
                                check_line = line[2:]
                                if 'not_kernel' == arch_type_str:
                                    check_line = line

                                if check_line in fc_lines:
                                    ft.write(check_line)



        #ctags issue: append mode with -n fields will lead repeated symbols
        if ctags_append_mode_i:
            ctags_cmd = "ctags -Ra --fields=+lafikmsztS --extra=+fq -L tags_append.files"
        else:
            ctags_cmd = "ctags -R --fields=+lafikmsztS --extra=+fq -L tags.files"
        #kernel mode
        if 'not_kernel' != arch_type_str:
            ctags_cmd = ctags_cmd + " -I EXPORT_SYMBOL+,EXPORT_SYMBOL_GPL+,__acquires+,__releases+,module_init+,module_exit"
            ctags_cmd = ctags_cmd + " -I fs_initcall+,subsys_initcall+,device_initcall+,core_initcall+,arch_initcall"
            ctags_cmd = ctags_cmd + " -I late_initcall+,postcore_initcall+,console_initcall+,early_initcall"
            ctags_cmd = ctags_cmd + " -I __initcall+,core_initcall_sync+,subsys_initcall_sync+,fs_initcall_sync"
            ctags_cmd = ctags_cmd + " -I late_initcall_sync+,arch_initcall_sync+,rootfs_initcall+,pure_initcall+,__exitcall"
            ctags_cmd = ctags_cmd + " -I DEFINE_SRCU+,security_initcall+,postcore_initcall_sync+,device_initcall_sync"
            ctags_cmd = ctags_cmd + " --langmap=c:+.h"
        else:
            ctags_cmd = ctags_cmd + " --langmap=c++:+.cu --langmap=c++:+.opencl --langmap=c++:+.cl"

        if ctags_append_mode_i:
            ctags_cmd = ctags_cmd + " -f  tags"
        else:
            ctags_cmd = ctags_cmd + " -f .auto_cscope_ctags/tags"

        #slient mode
        if 0 == show_message_enable:
            ctags_cmd = ctags_cmd + " 1>/dev/null  2>&1"

        if not ctags_append_mode_i:
            ctags_cmd = ctags_cmd + "; mv .auto_cscope_ctags/tags ./"

        debug_backrun_python_print("ctags_cmd: %s" % ctags_cmd)
        os.system(ctags_cmd)

        os.system("rm ./.auto_cscope_ctags/.tmp_update_file 1>/dev/null  2>&1")
        os.system("rm ./tags_append.files 1>/dev/null  2>&1")
        ctags_use_time_str = "Ctags Use time = %s s" % (time.time() - ctags_task_start_time)
        if ctags_append_mode_i:
            ctags_use_time_str = ctags_use_time_str + " with append mode"
        if 1 == show_message_enable:
            Warnin_print(ctags_use_time_str)
        else:
            debug_backrun_python_print(ctags_use_time_str)
        debug_backrun_python_print("end for ctag")

def update_arch_param():
    if 'not_kernel' != arch_type_str:
        debug_backrun_python_print("may kernel project, now update arch param")
        arch_dir = pwd_dir_str + "/arch"
        try:
            may_arch = os.listdir(arch_dir)
        except OSError:
            Warnin_print("wrong pwd args: %s" % pwd_dir_str)
            return

        for i in may_arch:
            if os.path.isdir(arch_dir + "/" + i):
                arch_parameter_list.append(i)

#############################################start here
parse_args()
update_arch_param()
check_args()
gen_cscope_and_ctag_file()
