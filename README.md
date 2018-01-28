Brief (V4.0.0)
===
#auto load cscope database and ctags databse, even diffrect project swicth(base third part)
-----

#auto update database if cscope connect
-----
After run buffer write command eg, w, we will try update database if already connect a cscope database,<br>
also we can check file update(may casued by git pull , add new file or edit by notepad) <br>
when fistly load vim <br>
if U do not want vim check database update when firstly load vim  <br>
add below in ~/.vimrc <br>
let g:check_update_when_first_load_vim = 0 <br>

if U do not want to auto update database during edit you file <br>
add below in ~/.vimrc <br>
let g:auto_run_function_when_cscope_connect = 0 <br>
then you can run command : <br>
:Manualstartstopautoupdatedatabas<br>
to start or stop auto update database<br>

we also add a command :Manualupdatedatabaseonetime <br>
which porvide a chance to update database onetime <br>
espiaclly, user disable g:auto_run_function_when_cscope_connect = 0  <br>

#easy create new cscope and ctags databse by command  :Createtag
-----
can intelligent identificate kernel dir eg:<br>
even U eidt at subdir like  vim kirkwood-cpufreq.c  at dir kernel/drivers/cpufreq <br>
we can intelligent detect it is a kernel tree, then call make cscope [ARCH] for gen <br>
kernel database<br>

suppor ARCH:<br>
alpha', 'arm', 'avr32', 'c6x', 'frv', 'hexagon', 'm68k', 'microblaze', 'mn10300', <br>
parisc', 's390', 'sh', 'tile', 'unicore32', 'xtensa', 'arc', 'arm64', 'blackfin', <br>
cris', 'h8300', 'ia64', 'm32r', 'metag', 'mips', 'openrisc', 'powerpc', 'score', <br>
sparc', 'um', 'x86<br>
 
if we can not  match kernel tree we will use  find command to gen needed files  <br>

Install
===

#Install before todo
-----
U need remove old config like: <br>
1: remove hard config database in vimrc eg: set tag=tags; <br>
2: remove hard config database in vimrc eg: cs add xxx <br>
3: also need remove database manage plugn if U used <br> 
ps: 1 2 3 function already be integrated in "auto_update_cscope_ctags_database" <br>


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

more
-----
remove autoload_cscope.vim if u have install this script(we add more interface in autoload_cscope_ctags.vim,<br> 
which base on autoload_cscope.vim )<br>


Env check
===
need must install: cscope ctags sed python and vim_with_python( vim --version| grep python) <br>

if you os support command: gnome-osd-client or notify-send , GUI will show mesage when collect　database <br>

also suggest build vim with timers(vim --version| grep timers)<br>

if U vim do not support timers , Feature (auto reset cscope' and 'check_update_when_first_load_vim)will be disable<br>
which will can use base function(update cscope and ctags database)<br>

#build new vim for support timers and python
-----
0: before build vim,suggest install: （ubuntu）sudo apt-get install libgtk2.0-dev libxt-dev libx11-dev <br>
tcl-dev libperl-dev libncurses5-dev python-dev python3-dev(if U use python3) <br>
a:  https://github.com/vim/vim download vim src <br>
b: ./configure  -with-features=huge --enable-rubyinterp --enable-perlinterp=yes --enable-tclinterp=yes <br>

for python please choose python2 or python3  <br>

python2 <br>
--enable-pythoninterp=yes  <br>
--with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu/  (this dir may diff between diff pc)  <br>

python3<br>
-enable-python3interp=yes<br>
--with-python-config-dir=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu/ (this dir may diff between diff pc) <br>

suggest  build with python2 <br>
c:make -j2<br>
d:sudo make install <br>
e:open a new terminal input command: vim --version to check vim support feature<br>

config you own prefer Featrue(Do not config anything, plugn also work fine)
===
g:Auto_update_cscope_ctags_debug_log <br>
-----
default value 0<br>




g:Auto_update_cscope_ctags_timer_filter<br>
-----
For filter Time:<br>
default value 60<br>
this time for filter modify frequency"<br>
if you want to see database update immediately<br>
you can modify to 10s or 1s, which I do not suggest<br>
,caused by csocpe or ctags gen database may take a<br>
big occupy on disk,you can override at .vimrc<br>


g:Auto_update_cscope_ctags_lock_floor_max<br>
-----
default value 1800<br>
this time for wait cscope or ctag gen tags finish<br>
or vim closed when gen ctags run last time, <br>
on SSD , gen cscope database(kernel code) may take 20s<br>
on HDD/7200 gen cscope database(kernel code)may take 50s <br>
so, I suggest keep, this vale to 1800(30min), if you PC<br>
I/O is so slow more than 30min, you may chang this value<br>
you can override at .vimrc<br>


g:auto_update_cscope_ctags_backup_run_py_dir_cache<br>
-----
default  '~/.vim/bundle/auto_update_cscope_ctags_database/plugin/auto_update_cscope_ctags_backup_run.py'<br>

you may set this in you .vimrc<br>
for plugn run quickly, but even<br>
you config err, we can also find it"<br>


g:auto_run_function_when_cscope_connect<br>
-----
default 1<br>
:when find cscope connect/first load<br>
or buffers swith<br>
if you set to 0 in vimrc, <br>
you need use command: <br>
:Manualstartstopautoupdatedatabas<br>
to start or stop auto update database<br>


g:check_update_when_first_load_vim<br>
-----
default 1<br>
when 1, we will try to check database need update or not<br>
eg: you add some file in project or edit src by git pull or <br>
other editer like gedit or notepad, we can detect the update<br>
you can disable this Feature in .vimrc<br>

issue report
==== 
*1:enable  'let g:Auto_update_cscope_ctags_debug_log = 1' in ~/.vimrc <br>
*2:reopen vim , reproducte issue<br>
*3:upload logfile : /tmp/.Auto_update_cscope_ctags_debug_back_run.log /tmp/.Auto_update_cscope_ctags_debug_log.log<br>
*4:also upload err info in vim eidt window

