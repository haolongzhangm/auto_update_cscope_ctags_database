brief 
===
#auto load cscope database and ctags databse, even diffrect project swicth(base third part)
-----

#auto update database if cscope connect
-----

#you can create new cscope and ctags databse by command: :Createtag
-----
can intelligent identificate kernel dir eg:<br>
even U eidt at subdir like  vim kirkwood-cpufreq.c  at dir kernel/drivers/cpufreq <br>
we can intelligent find it is a kernel tree, then call make cscope [ARCH] for gen <br>

kernel database, suppor ARCH:<br>
alpha', 'arm', 'avr32', 'c6x', 'frv', 'hexagon', 'm68k', 'microblaze', 'mn10300', <br>
parisc', 's390', 'sh', 'tile', 'unicore32', 'xtensa', 'arc', 'arm64', 'blackfin', <br>
cris', 'h8300', 'ia64', 'm32r', 'metag', 'mips', 'openrisc', 'powerpc', 'score', <br>
sparc', 'um', 'x86<br>




Install
===

#ways A
-----
git clone git@github.com:haolongzhangm/auto_update_cscope_ctags_database.git <br>
then put plugn file to ~/.vim/plugn <br>


#ways B
-----
if u use bundle<br>
just add <br>
'Bundle 'haolongzhangm/auto_update_cscope_ctags_database'<br>
in ~/.vimrc <br>
then run :<br>
:PluginInstall<br>


Env check
===
need must install: cscope ctags sed python or vim_with_python( vim --version| grep python) <br>

if you os support command: gnome-osd-client , GUI will show mesage when collect　database <br>



config you vim
===
g:Auto_update_cscope_ctags_debug_log <br>
default value 0<br>


For filter Time:<br>
default value 60<br>
g:Auto_update_cscope_ctags_timer_filter<br>
this time for filter modify frequency"<br>
if you want to see database update immediately<br>
you can modify to 10s or 1s, which I do not suggest<br>
,caused by csocpe or ctags gen database may take a<br>
big occupy on disk,you can override at .vimrc<br>


g:Auto_update_cscope_ctags_lock_floor_max<br>
default value 1800<br>
this time for wait cscope or ctag gen tags finish<br>
or vim closed when gen ctags run last time, <br>
on SSD , gen cscope database(kernel code) may take 20s<br>
on HDD/7200 gen cscope database(kernel code)may take 50s <br>
so, I suggest keep, this vale to 1800(30min), if you PC<br>
I/O is so slow more than 30min, you may chang this value<br>
you can override at .vimrc<br>


g:auto_update_cscope_ctags_backup_run_py_dir_cache<br>
default ~/.vim/plugin<br>
you may set this in you .vimrc<br>
for plugn run quickly, but even<br>
you config err, we can also find it"<br>


g:auto_run_function_when_cscope_connect<br>
default 1<br>
:when find cscope connect/first load<br>
or buffers swith<br>
if you set to 0 in vimrc, <br>
you need use command: <br>
:Manualstartstopautoupdatedatabas<br>
to start or stop auto update database<br>

issue report
==== 
*1:enable  'let g:Auto_update_cscope_ctags_debug_log = 1' in ~/.vimrc <br>
*2:reopen vim , reproducte issue<br>
*3:upload logfile : /tmp/.Auto_update_cscope_ctags_debug_back_run.log /tmp/.Auto_update_cscope_ctags_debug_log.log<br>



