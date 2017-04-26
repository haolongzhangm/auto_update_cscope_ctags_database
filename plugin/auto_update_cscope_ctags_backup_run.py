#!/usr/bin/env python
#by haolong.zhang@ck-telecom.com 20170426
import os
import glob
import sys
import time
import getpass

arch_parameter_list = ['normal', 'alpha', 'arm', 'arm64', 'avr32', \
        'c6x', 'frv', 'hexagon', 'm68k', 'microblaze', 'mn10300', \
        'parisc', 's390', 'sh', 'tile', 'unicore32', 'xtensa', \
        'arc', 'arm64', 'blackfin', 'cris' ,'h8300', 'ia64', \
        'm32r', 'metag', 'mips', 'openrisc', 'powerpc', 'score', \
        'sparc', 'um', 'x86']
care_file_type = ['*.c', '*.cpp', '*.h', '*.cc', '*.java', '*.sh', 
        '*.mk', '*.prop', '*.xml', 'Makefile', '*.rc', 'platform', 
        'Drivers', '*.scons', '*.api', '*.tla', '*.smh', '*.smi', 
        '*.smt', '*.idl', '*.te', '*.py', '*.S']

global_back_run_log_file = '/tmp/.Auto_update_cscope_ctags_debug_back_run.log'

second_parameter_list = ['cscope_only', 'cscope_and_ctags']
def Usage():
    print('v1.0')
    print('withqcn')
    print('python auto_update_cscope_ctags_backup_run.py [ARCH] [tags_type] [pwd/default .]')
    exit()

def check_args():
    if len(sys.argv) != 3 and len(sys.argv) != 4:
        print('need 2 or 3argv')
        Usage()

    if sys.argv[1] not in arch_parameter_list:
        print('arch_parameter only support:')
        print(arch_parameter_list)
        Usage()

    if sys.argv[2] not in second_parameter_list:
        print('second_parameter_list onlys support:')
        print(second_parameter_list)
        Usage()

def gnome_osd_print(str):
        cmd_str = "gnome-osd-client -f "  + '\"' + "<message id=" + '\'' + \
                "auto_update_tags" + '\'' + " osd_fake_translucent_bg=" + \
                '\'' + "on" + '\'' + " osd_vposition=" + '\'' + "center" + \
                '\'' + " animations=" + '\'' + "off" + '\'' + " hide_timeout=" + \
                '\'' + "2000" + '\'' + " osd_halignment=" + '\'' + "center" + '\'>' \
                + str + "</message>" + '\"&'
        os.system(cmd_str)

def debug_backrun_python_print(str):

    user_name = getpass.getuser()
    vimrc_file = '/home/%s/.vimrc' % user_name

    if os.path.exists(vimrc_file):
        if vimrc_file.find('let g:Auto_update_cscope_ctags_debug_log = 1'):
            f = open(global_back_run_log_file,'a')
            print >> f, '\n'
            print >> f, time.localtime(time.time())
            print >> f, str
            f.close()
    else:
        return 0

def gen_cscope_and_ctag_file():
    #if you kernel do not support command: make cscope ARCH=arm
    #or not kernel code 
    gen_tag_dir = './'
    if len(sys.argv) == 4:
        gen_tag_dir = sys.argv[3]

    debug_backrun_python_print(sys.argv[1])
    gnome_osd_print('%s project update tags start' % sys.argv[1])
    os.chdir(gen_tag_dir)
    if 'normal' == sys.argv[1]:
        normal_cmd = "find . -name '*.c' "
        for i_care_type in care_file_type:
            normal_cmd = normal_cmd + " -o -name " + '\'' + i_care_type + '\''

        normal_cmd = normal_cmd + " -o -type f -name '*config'"
        normal_cmd = normal_cmd + "> cscope.files "
        normal_cmd = normal_cmd + ";cscope -bkq -i cscope.files "
        if len(sys.argv) == 4:
            debug_backrun_python_print("Called from vim")
            normal_cmd = normal_cmd + " 1>/dev/null  2>&1"

        debug_backrun_python_print(normal_cmd)
        debug_backrun_python_print("now for cscope")
        os.system(normal_cmd)
        debug_backrun_python_print("end for cscope")
    else:
        kernel_cmd = "make cscope ARCH=%s" % sys.argv[1]
        if len(sys.argv) == 4:
            debug_backrun_python_print("Called from vim")
            kernel_cmd = kernel_cmd + " 1>/dev/null  2>&1"

        debug_backrun_python_print(kernel_cmd)
        debug_backrun_python_print("now for cscope")
        os.system(kernel_cmd)
        debug_backrun_python_print("end for cscope")

    if 'cscope_and_ctags' == sys.argv[2]:
        debug_backrun_python_print("now for ctag")
        debug_backrun_python_print("firtly handle cscope.files")
        handle_tags_files_cmd = "cp cscope.files tags.files; "
        if not 'normal' == sys.argv[1]:
            handle_tags_files_cmd = handle_tags_files_cmd + "sed -i '1,2d' tags.files"

        debug_backrun_python_print(handle_tags_files_cmd)
        os.system(handle_tags_files_cmd)

        if len(sys.argv) == 4:
            debug_backrun_python_print("Called from vim")
            ctags_cmd = "ctags -R --fields=+lS -L tags.files -f .auto_cscope_ctags/tags; rm tags.files"
            ctags_cmd = ctags_cmd + " 1>/dev/null  2>&1"
            ctags_cmd = ctags_cmd + "; mv .auto_cscope_ctags/tags ../"
        else:
            ctags_cmd = "ctags -R --fields=+lS -L tags.files -f tags; rm tags.files"
            print(ctags_cmd)

        debug_backrun_python_print(ctags_cmd)
        os.system(ctags_cmd)
        debug_backrun_python_print("end for ctag")

    if len(sys.argv) == 4:
        end_remove_lock_cmd = "cd %s; \
                rm .auto_cscope_ctags/lock 1>/dev/null  2>&1" % gen_tag_dir
        debug_backrun_python_print("now for remove_lock_cmd")
        os.system(end_remove_lock_cmd)
        debug_backrun_python_print("end for remove_lock_cmd")

    gnome_osd_print('%s project update tags end' % sys.argv[1])

#############################################start here
check_args()
gen_cscope_and_ctag_file()
