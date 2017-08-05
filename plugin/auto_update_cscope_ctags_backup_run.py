#!/usr/bin/env python
# -*- coding: utf-8 -*-
# File: auto_update_cscope_ctags_backup_run.py
# Author: SeaflyDennis <seafly0616@qq.com>
# Date: 2017.08.05
# Last Modified Date: 2017.08.05
# Last Modified By: SeaflyDennis <seafly0616@qq.com>
#by haolong.zhang@ck-telecom.com 20170426
import os
import glob
import sys
import time
import getpass
import threading

arch_parameter_list = ['normal', 'alpha', 'arm', 'avr32', \
        'c6x', 'frv', 'hexagon', 'm68k', 'microblaze', 'mn10300', \
        'parisc', 's390', 'sh', 'tile', 'unicore32', 'xtensa', \
        'arc', 'arm64', 'blackfin', 'cris' ,'h8300', 'ia64', \
        'm32r', 'metag', 'mips', 'openrisc', 'powerpc', 'score', \
        'sparc', 'um', 'x86']
care_file_type = ['*.c', '*.cpp', '*.h', '*.cc', '*.java', '*.sh',
        '*.mk', '*.prop', '*.xml', 'Makefile', '*.rc', 'platform',
        'Drivers', '*.scons', '*.api', '*.tla', '*.smh', '*.smi',
        '*.smt', '*.idl', '*.te', '*.py', '*.S', '*.tpl', '*.css',
        '*.js', '*.txt', '*.proto', '*.md', '*.conf', '*.json',
        '*.BUILD', '*.bzl', 'BUILD', '*.hpp', '*.launch']

needed_env_list = ['python', 'cscope', 'sed', 'ctags']

global_back_run_log_file = '/tmp/.Auto_update_cscope_ctags_debug_back_run.log'

global_debug_enable = -1

#you may config this dir, if you change the
#python default install dir, eg MAC os may
#need config this str
#global_add_pythonlib = False
global_add_pythonlib = True
global_pythonlib_dir_str = ['/usr/lib/', '/usr/local/lib/']

second_parameter_list = ['cscope_only', 'cscope_and_ctags']
fifth_parameter_list = ['print_message', 'quiet']
def Usage():
    Warnin_print('v1.0')
    Warnin_print('python auto_update_cscope_ctags_backup_run.py [ARCH] [tags_type] [pwd/default .] [quiet_or_not] [soft_link_conf]')
    exit()

def check_args():
    if len(sys.argv) != 4 and len(sys.argv) != 5 and len(sys.argv) != 6:
        Warnin_print('need 3 or 4argv or 5argv')
        Usage()

    if sys.argv[1] not in arch_parameter_list:
        Warnin_print('arch_parameter only support:')
        Warnin_print(arch_parameter_list)
        Usage()

    if sys.argv[2] not in second_parameter_list:
        Warnin_print('second_parameter_list onlys support:')
        Warnin_print(second_parameter_list)
        Usage()
    if len(sys.argv) == 6:
        if sys.argv[4] not in fifth_parameter_list:
            Warnin_print('fifth_parameter_first_parm_list: only support:')
            Warnin_print(fifth_parameter_list)
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
        f = open(global_back_run_log_file,'a')
        print >> f, '\n'
        print >> f, time.localtime(time.time())
        print >> f, str
        f.close()
    else:
        return 0

def Warnin_print(str):
    debug_backrun_python_print(str)
    print(str)

def gen_cscope_and_ctag_file():
    #if you kernel do not support command: make cscope ARCH=arm
    #or not kernel code
    gen_tag_dir = './'
    support_soft_link = 'no'
    if len(sys.argv) == 4 or len(sys.argv) == 5 or len(sys.argv) == 6:
        gen_tag_dir = sys.argv[3]

    if not os.path.exists(gen_tag_dir):
        Warnin_print("Err :invalid gen_tag_dir : %s" % gen_tag_dir)
        return 0

    #check needed env
    for env_i in needed_env_list:
        if 0 == check_os_cmd_exist(env_i):
            Warnin_print("ERR: can not find %s pls install it fistly" % env_i)
            return 0

    debug_backrun_python_print(sys.argv[1])
    gnome_osd_print('%s project update tags start' % sys.argv[1])
    os.chdir(gen_tag_dir)
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

        debug_backrun_python_print("end write pid to lock")
    else:
        Warnin_print("create lock failed, may caused by I/O permmison!")

    start_time = time.time()
    print_cscope_and_ctags_info = 0
    if len(sys.argv) == 6:
        support_soft_link = sys.argv[5]
        if 'quiet' == sys.argv[4]:
            debug_backrun_python_print("no message print")
            print_cscope_and_ctags_info = 0
        elif 'print_message' == sys.argv[4]:
            debug_backrun_python_print("show print_message")
            print_cscope_and_ctags_info = 1
    else:
        debug_backrun_python_print("show print_message")
        print_cscope_and_ctags_info = 1

    if 'yes' == support_soft_link:
        mark_soft_link_exe = "touch .auto_cscope_ctags/.enable_soft_link_file 1>/dev/null 2>&1"
    elif 'no' == support_soft_link:
        mark_soft_link_exe = "rm .auto_cscope_ctags/.enable_soft_link_file 1>/dev/null 2>&1"

    if 'yes' == support_soft_link or 'no' == support_soft_link:
        debug_backrun_python_print(mark_soft_link_exe)
        os.system(mark_soft_link_exe)

    # add thread
    cscope_task = threading.Thread(target = cscope_task_func, args = (print_cscope_and_ctags_info, start_time))
    ctags_task = threading.Thread(target = ctags_task_func, args = (print_cscope_and_ctags_info, start_time, cscope_task))

    cscope_task.start()
    ctags_task.start()
    if 1 == print_cscope_and_ctags_info:
        Warnin_print("")
        Warnin_print("cscope_task = %s" % cscope_task)
        Warnin_print("ctags_task = %s" % ctags_task)

    cscope_task.join()
    ctags_task.join()
    #end thread

    clear_lock_i()
    all_take_time  = time.time() - start_time
    if 1 == print_cscope_and_ctags_info:
        Warnin_print("All finish take %s s" % all_take_time)
    else:
        debug_backrun_python_print("All finish take %s s" % all_take_time)

    gnome_osd_print('%s project update tags end' % sys.argv[1])

def clear_lock_i():
    end_remove_lock_cmd = "rm .auto_cscope_ctags/lock 1>/dev/null  2>&1"
    debug_backrun_python_print("now for remove_lock_cmd")
    os.system(end_remove_lock_cmd)
    debug_backrun_python_print("end for remove_lock_cmd")

def cscope_task_func(show_message_enable, s_time):

    if 'normal' == sys.argv[1]:
        normal_cmd = "find"
        if os.path.exists('./.auto_cscope_ctags/.enable_soft_link_file'):
            normal_cmd = normal_cmd + " -L "
        normal_cmd = normal_cmd + " . -name '*.c' "
        for i_care_type in care_file_type:
            normal_cmd = normal_cmd + " -o -name " + '\'' + i_care_type + '\''

        normal_cmd = normal_cmd + " -o -type f -name '*config'"
        normal_cmd = normal_cmd + "> cscope.files ; "
        normal_cmd = normal_cmd + 'echo -e "!_TAG_FILE_SORTED\t2\t/2=foldcase">./filenametags ; '
        normal_cmd = normal_cmd + 'find ./ -name "*.c" -o -name "*.h" -o -name "Makefile" -o -name "*.lds" -o -name "*config*" -o -name "*build*" -o -name "*.sh" -o -name "*conf*" -o -name "*.s" -o -name "*.S" -o -name *.asm '
        normal_cmd = normal_cmd + ' -printf "%f\t%p\t1\n" | sort -f >>./filenametags ; '
        if global_add_pythonlib:
            if check_include_filetyle_or_not('*.py'):
                debug_backrun_python_print('find python file, try to add pythonlib file...')
                (valid_install_dir, pythonlib_install_i_dir) = find_python_install_lib()
                if valid_install_dir:
                    for dir_i in pythonlib_install_i_dir:
                        if os.path.exists(dir_i):
                            debug_backrun_python_print('now handle pythonlib %s' % dir_i)
                            normal_cmd = normal_cmd + "; find %s -name '*.py' >> cscope.files" % dir_i

        normal_cmd = normal_cmd + ";cscope -bkq -i cscope.files -f cscope.out"
        if 0 == show_message_enable:
            normal_cmd = normal_cmd + " 1>/dev/null  2>&1"
        else:
            Warnin_print(normal_cmd)

        debug_backrun_python_print(normal_cmd)
        debug_backrun_python_print("now for cscope")
        os.system(normal_cmd)
        normal_end_time  = time.time()
        use_time_str = "cscope Use time = %s s" % (normal_end_time - s_time)
        if 1 == show_message_enable:
            Warnin_print(use_time_str)
        else:
            debug_backrun_python_print(use_time_str)

        debug_backrun_python_print("end for cscope")
    else:
        kernel_cmd = "make cscope ARCH=%s" % sys.argv[1]
        if 0 == show_message_enable:
            kernel_cmd = kernel_cmd + " 1>/dev/null  2>&1"
        else:
            Warnin_print(kernel_cmd)

        debug_backrun_python_print(kernel_cmd)
        debug_backrun_python_print("now for cscope")
        os.system(kernel_cmd)
        normal_end_time  = time.time()
        use_time_str = "cscope Use time = %s s" % (normal_end_time - s_time)
        if 1 == show_message_enable:
            Warnin_print(use_time_str)
        else:
            debug_backrun_python_print(use_time_str)
        debug_backrun_python_print("end for cscope")

def ctags_task_func(show_message_enable, s_time, cscope_task_id):

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

    if 'cscope_and_ctags' == sys.argv[2]:
        debug_backrun_python_print("now for ctag")
        debug_backrun_python_print("firtly handle cscope.files")
        handle_tags_files_cmd = "cp cscope.files tags.files; "
        diff_size = 0
        if not 'normal' == sys.argv[1]:
            handle_tags_files_cmd = handle_tags_files_cmd + "sed -i '1,2d' tags.files"
            #-k -q line size = 8
            diff_size = 8

        debug_backrun_python_print(handle_tags_files_cmd)
        os.system(handle_tags_files_cmd)

        ctags_cmd = 'echo "!_TAG_FILE_SORTED\t2\t/2=foldcase">./filenametags'
        ctags_cmd = ctags_cmd + ' ; find . -regex ".*\.\(cpp\|h\|c\sh\|txt\|lds\|s\|S\|cfg\|conf\|md\)" -printf "%f\t%p\t1\n" | sort -f >> ./filenametags'
        ctags_cmd = ctags_cmd + ' ; find . -name "Makefile*" -printf "%f\t%p\t1\n" | sort -f >> ./filenametags'
        ctags_cmd = ctags_cmd + ' ; find . -name "Kconfig*" -printf "%f\t%p\t1\n" | sort -f >> ./filenametags'
        ctags_cmd = ctags_cmd + ' ; find . -name "Kbuild*" -printf "%f\t%p\t1\n" | sort -f >> ./filenametags'
        ctags_cmd = ctags_cmd + ' ; find . -name "README*" -printf "%f\t%p\t1\n" | sort -f >> ./filenametags'
        ctags_cmd = ctags_cmd + ' ; find . -name "*readme*" -printf "%f\t%p\t1\n" | sort -f >> ./filenametags'

        ctags_cmd = ctags_cmd + " ; tags -R --fields=+lafikmnsztS --extra=+fq -L tags.files"
        #kernel mode
        if 'normal' != sys.argv[1]:
            ctags_cmd = ctags_cmd + " -I EXPORT_SYMBOL+,EXPORT_SYMBOL_GPL+,__acquires+,__releases+,module_init+,module_exit"
            ctags_cmd = ctags_cmd + " -I fs_initcall+,subsys_initcall+,device_initcall+,core_initcall+,arch_initcall"
            ctags_cmd = ctags_cmd + " -I late_initcall+,postcore_initcall+,console_initcall+,early_initcall"
            ctags_cmd = ctags_cmd + " -I __initcall+,core_initcall_sync+,subsys_initcall_sync+,fs_initcall_sync"
            ctags_cmd = ctags_cmd + " -I late_initcall_sync+,arch_initcall_sync+,rootfs_initcall+,pure_initcall+,__exitcall"
            ctags_cmd = ctags_cmd + " -I DEFINE_SRCU+,security_initcall+,postcore_initcall_sync+,device_initcall_sync"
            ctags_cmd = ctags_cmd + " --langmap=c:+.h"
        #slient mode
        if 0 == show_message_enable:
            ctags_cmd = ctags_cmd + " -f .auto_cscope_ctags/tags"
            ctags_cmd = ctags_cmd + " 1>/dev/null  2>&1"
            ctags_cmd = ctags_cmd + "; mv .auto_cscope_ctags/tags ./"
        else:
            ctags_cmd = ctags_cmd + " -f tags"
            Warnin_print(ctags_cmd)

        debug_backrun_python_print("show print_message :cmd %s" % ctags_cmd)
        os.system(ctags_cmd)

        #double check uniformity between cscope.files and ctags.files
        while diff_size < (os.path.getsize('./cscope.files') - os.path.getsize('./tags.files')):
            if 1 == show_message_enable:
                Warnin_print("max than diff_size, we need update ctags again")
            else:
                debug_backrun_python_print("max than diff_size, we need update ctags again")
            os.system(handle_tags_files_cmd)
            os.system(ctags_cmd)

        os.system("rm tags.files")
        ctags_end_time  = time.time()
        ctags_use_time_str = "Ctags Use time = %s s" % (ctags_end_time - s_time)
        if 1 == show_message_enable:
            Warnin_print(ctags_use_time_str)
        else:
            debug_backrun_python_print(ctags_use_time_str)
        debug_backrun_python_print("end for ctag")

#############################################start here
check_args()
gen_cscope_and_ctag_file()
