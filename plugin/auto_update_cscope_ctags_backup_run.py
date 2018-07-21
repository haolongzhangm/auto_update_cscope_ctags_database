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

#you may config this dir, if you change the
#python default install dir, eg MAC os may
#need config this str
add_pythonlib = 'ignore'
add_pythonlib_list = ['yes', 'no', 'ignore']
global_pythonlib_dir_str = ['/usr/lib/', '/usr/local/lib/']

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
    global add_pythonlib
    global do_not_care_dir
    global ctags_append_mode

    if 1 >= len(sys.argv):
        Warnin_print("Err: too few args")
        Usage()

    try:
        optlist, args = getopt.getopt(sys.argv[1:], "hms:a:p:d:y:r:")
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
        elif '-y' == c:
            add_pythonlib = value
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
    Warnin_print(' -y: support python API or not')
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

    if add_pythonlib not in add_pythonlib_list:
        Warnin_print('Do not support add_pythonlib_list type: %s' % add_pythonlib)
        Warnin_print('only support add_pythonlib type')
        Warnin_print(add_pythonlib_list)
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
        cmd_str = "notify-send " + '\"' + str + '\"'+ " &"
    elif 1 == check_os_cmd_exist("gnome-osd-client"):
        debug_backrun_python_print("find command: gnome-osd-client")
        cmd_str = "gnome-osd-client -f "  + '\"' + "<message id=" + '\'' + \
            "auto_update_tags" + '\'' + " osd_fake_translucent_bg=" + \
            '\'' + "on" + '\'' + " osd_vposition=" + '\'' + "bottom" + \
            '\'' + " animations=" + '\'' + "off" + '\'' + " hide_timeout=" + \
            '\'' + "4000" + '\'' + " osd_halignment=" + '\'' + "center" + '\'>' \
            + str + "</message>" + '\"&'
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

def gen_cscope_and_ctag_file():
    #if you kernel do not support command: make cscope ARCH=arm
    #or not kernel code

    if not os.path.exists(pwd_dir_str):
        Warnin_print("Err :invalid pwd_dir_str: %s" % pwd_dir_str)
        return 0

    #check needed env
    for env_i in needed_env_list:
        if 0 == check_os_cmd_exist(env_i):
            Warnin_print("ERR: can not find %s pls install it fistly" % env_i)
            return 0

    debug_backrun_python_print(arch_type_str)
    gnome_osd_print('%s project update tags start' % arch_type_str)
    os.chdir(pwd_dir_str)

    if os.path.isfile('./cscope.out') and os.path.isfile('./tags') \
            and os.path.isfile('./.auto_cscope_ctags/.old_cscope.files'):
        ctags_append_mode = True
    else:
        ctags_append_mode = False

    pre_create_lock_cmd = "mkdir .auto_cscope_ctags 1>/dev/null 2>&1; \
            touch .auto_cscope_ctags/lock 1>/dev/null 2>&1; sync ;\
            rm .auto_cscope_ctags/cscope_detect_wait 1>/dev/null 2>&1"
    debug_backrun_python_print("now create lock now")
    os.system(pre_create_lock_cmd)
    debug_backrun_python_print("end create lock now")

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

    start_time = time.time()

    #config soft link
    if 'yes' == support_soft_link_str:
        mark_soft_link_exe = "touch .auto_cscope_ctags/.enable_soft_link_file 1>/dev/null 2>&1"
    elif 'no' == support_soft_link_str:
        mark_soft_link_exe = "rm .auto_cscope_ctags/.enable_soft_link_file 1>/dev/null 2>&1"

    if 'yes' == support_soft_link_str or 'no' == support_soft_link_str:
        debug_backrun_python_print(mark_soft_link_exe)
        os.system(mark_soft_link_exe)

    #config support pythonlib
    if 'yes' == add_pythonlib:
        mark_add_pythonlib_exe = "touch .auto_cscope_ctags/.add_pythonlib_file 1>/dev/null 2>&1"
    elif 'no' == add_pythonlib:
        mark_add_pythonlib_exe = "rm .auto_cscope_ctags/.add_pythonlib_file 1>/dev/null 2>&1"

    if 'yes' == add_pythonlib or 'no' == add_pythonlib:
        debug_backrun_python_print(mark_add_pythonlib_exe)
        os.system(mark_add_pythonlib_exe)

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

    # add thread
    cscope_task = threading.Thread(target = cscope_task_func, args = (show_msg_bool, start_time))
    ctags_task = threading.Thread(target = ctags_task_func, args = (show_msg_bool, start_time, cscope_task, ctags_append_mode))

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
    all_take_time  = time.time() - start_time
    if 1 == show_msg_bool:
        Warnin_print("All finish take %s s" % all_take_time)
    else:
        debug_backrun_python_print("All finish take %s s" % all_take_time)

    gnome_osd_print('%s project update tags end' % arch_type_str)
    update_auto_cscope_ctags_dir_time_cmd = "cp cscope.files .auto_cscope_ctags/.old_cscope.files"
    os.system(update_auto_cscope_ctags_dir_time_cmd)

def clear_lock_i():
    end_remove_lock_cmd = "rm .auto_cscope_ctags/lock 1>/dev/null  2>&1"
    debug_backrun_python_print("now for remove_lock_cmd")
    os.system(end_remove_lock_cmd)
    debug_backrun_python_print("end for remove_lock_cmd")

def cscope_task_func(show_message_enable, s_time):

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
        not_kernel_cmd = not_kernel_cmd + "> cscope.files "
        if os.path.exists('./.auto_cscope_ctags/.add_pythonlib_file'):
            if check_include_filetyle_or_not('*.py'):
                debug_backrun_python_print('find python file, try to add pythonlib file...')
                (valid_install_dir, pythonlib_install_i_dir) = find_python_install_lib()
                if valid_install_dir:
                    for dir_i in pythonlib_install_i_dir:
                        if os.path.exists(dir_i):
                            debug_backrun_python_print('now handle pythonlib %s' % dir_i)
                            not_kernel_cmd = not_kernel_cmd + "; find %s -name '*.py' >> cscope.files" % dir_i

        not_kernel_cmd = not_kernel_cmd + ";cscope -bkq -i cscope.files -f cscope.out"
        if 0 == show_message_enable:
            not_kernel_cmd = not_kernel_cmd + " 1>/dev/null  2>&1"
        #else:
        #    Warnin_print(not_kernel_cmd)

        debug_backrun_python_print(not_kernel_cmd)
        debug_backrun_python_print("now for cscope")
        os.system(not_kernel_cmd)
        not_kernel_end_time  = time.time()
        use_time_str = "cscope Use time = %s s" % (not_kernel_end_time - s_time)
        if 1 == show_message_enable:
            Warnin_print(use_time_str)
        else:
            debug_backrun_python_print(use_time_str)

        debug_backrun_python_print("end for cscope")
    else:
        kernel_cmd = "make cscope ARCH=%s" % arch_type_str
        if 0 == show_message_enable:
            kernel_cmd = kernel_cmd + " 1>/dev/null  2>&1"
        else:
            Warnin_print(kernel_cmd)

        debug_backrun_python_print(kernel_cmd)
        debug_backrun_python_print("now for cscope")
        os.system(kernel_cmd)
        not_kernel_end_time  = time.time()
        use_time_str = "cscope Use time = %s s" % (not_kernel_end_time - s_time)
        if 1 == show_message_enable:
            Warnin_print(use_time_str)
        else:
            debug_backrun_python_print(use_time_str)
        debug_backrun_python_print("end for cscope")

def ctags_task_func(show_message_enable, s_time, cscope_task_id, ctags_append_mode_i):

    #wait cscope_task_func touch cscope.files
    i = 0
    while ( (not os.path.exists('cscope.files')) or 1 >= os.path.getsize('cscope.files')):
        if not cscope_task_id.isAlive():
            Warnin_print("ERR happened, may try to gen tags at a null dir" )
            clear_lock_i()
            return -1

        time.sleep(0.2)
        i = i + 1
        debug_backrun_python_print("wait cscope_task_func touch cscope.files")
        if i > 200:
            Warnin_print("we think issue may happened caused by cscope.files touched err after 40s")
            clear_lock_i()
            return -1

    #wait cscope.files update end
    i = 0
    while True:
        i = i + 1
        debug_backrun_python_print("cscope.files update...")
        os.system("sync")
        before_time = os.stat('cscope.files').st_mtime
        time.sleep(1)
        os.system("sync")
        check_time = os.stat('cscope.files').st_mtime
        if before_time == check_time:
            debug_backrun_python_print("cscope.files already update finish")
            break
        if i > 100:
            Warnin_print("we think issue may happened caused by cscope.files \
                    update so long time err after 60s:for example try to create tag at \
                    so big dir eg : Android src root dir, which we do not suggest")
            clear_lock_i()
            return -1

    if 'cscope_and_ctags' == database_type_str:
        debug_backrun_python_print("now for ctag")
        debug_backrun_python_print("firtly handle cscope.files")
        handle_tags_files_cmd = "cp cscope.files tags.files; "
        diff_size = 0
        if not 'not_kernel' == arch_type_str:
            #fix issue on MACOS sed issue: 'undefined label'
            if platform.system() == 'Darwin':
                handle_tags_files_cmd = handle_tags_files_cmd + "sed -i '' '1,2d' tags.files"
            else:
                handle_tags_files_cmd = handle_tags_files_cmd + "sed -i '1,2d' tags.files"
            #-k -q line size = 8
            diff_size = 8

        debug_backrun_python_print(handle_tags_files_cmd)
        os.system(handle_tags_files_cmd)

        if ctags_append_mode_i:
            old_file_size = os.path.getsize("./.auto_cscope_ctags/.old_cscope.files")
            new_file_size = os.path.getsize("./cscope.files")
            debug_backrun_python_print("old_file_size = %d new_file_size = %d" % (old_file_size, new_file_size))
            if old_file_size != new_file_size:
                ctags_append_mode_i = False
        if ctags_append_mode_i:
            #find -newer file than ./.auto_cscope_ctags/.old_cscope.files
            newer_cmd = "find . -name *.c -newer ./.auto_cscope_ctags/.old_cscope.files"
            for i_care_type in care_file_type:
                newer_cmd = newer_cmd + " -o -name " + '\'' + i_care_type \
                        + '\'' + " -newer ./.auto_cscope_ctags/.old_cscope.files "
            newer_cmd = newer_cmd + " > ./.auto_cscope_ctags/.tmp_update_file"
            #print(newer_cmd)
            os.system(newer_cmd)
            #new check ./.auto_cscope_ctags/.tmp_update_file file real in cscope.files
            #set ctags_append_mode_i to False fistly
            os.system("touch ./tags_append.files")
            with open("./.auto_cscope_ctags/.tmp_update_file", 'r') as f:
                lines = f.readlines()
                if len(lines) > 0:
                    with open("./cscope.files", 'r') as fc:
                        with open("./tags_append.files", 'w') as ft:
                            fc_lines = fc.readlines()
                            for line in lines:
                                #May need check performance
                                check_line = line[2:]
                                if 'not_kernel' == arch_type_str:
                                    check_line = line

                                if check_line in fc_lines:
                                    ft.write(line)



        if ctags_append_mode_i:
            ctags_cmd = "ctags -Ra --fields=+lafikmnsztS --extra=+fq -L tags_append.files"
        else:
            ctags_cmd = "ctags -R --fields=+lafikmnsztS --extra=+fq -L tags.files"
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

        #double check uniformity between cscope.files and ctags.files
        if not ctags_append_mode_i:
            while diff_size < (os.path.getsize('./cscope.files') - os.path.getsize('./tags.files')):
                if 1 == show_message_enable:
                    Warnin_print("max than diff_size, we need update ctags again")
                else:
                    debug_backrun_python_print("max than diff_size, we need update ctags again")
                os.system(handle_tags_files_cmd)
                os.system(ctags_cmd)

        os.system("rm tags.files")
        os.system("rm ./.auto_cscope_ctags/.tmp_update_file 1>/dev/null  2>&1")
        os.system("rm ./tags_append.files 1>/dev/null  2>&1")
        ctags_end_time  = time.time()
        ctags_use_time_str = "Ctags Use time = %s s" % (ctags_end_time - s_time)
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
