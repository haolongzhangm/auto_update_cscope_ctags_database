"===========================================================================================
"Brief introduction
"vim srcipt for auto update cscope and ctags databse
"
"Install:
"        ways A: git clone git@github.com:haolongzhangm/auto_update_cscope_ctags_database.git 
"                then put plugn file to ~/.vim/plugn
"        ways B: use bundle
"                just add 
"                        'Bundle 'haolongzhangm/auto_update_cscope_ctags_database'
"                     in ~/.vimrc
"                     then run :
"                        :PluginInstall
"                        
" ==========================================================================================
" Env check: must install  cscope  ctags  sed  python  gnome-osd-client(not must, if install it , will GUI show
" after update finish)
" 
" 
" Config youself needed in ~.vimrc if needed (I think no need customization if really needed):
" 
" "For debug print"
" "g:Auto_update_cscope_ctags_debug_log
""default value 0"
"
""For lock reflash Time:"
""default value 60"
""g:Auto_update_cscope_ctags_lock_floor_min"
""                   this time for filter modify frequency"
""                   if you want to see database update immediately"
""                   you can modify to 10s or 1s, which I do not suggest"
""                   ,caused by csocpe or ctags gen database may take a"
""                   big occupy on disk,you can override at .vimrc"
"
"
""g:Auto_update_cscope_ctags_lock_floor_max"
""default value 1800"
""                   this time for wait cscope or ctag gen tags finish"
""                   or vim closed when gen ctags run last time, "
""                   on SSD , gen cscope database(kernel code) may take 20s"
""                   on HDD/7200 gen cscope database(kernel code)may take 50s "
""                   so, I suggest keep, this vale to 1800(30min), if you PC"
""                   I/O is so slow more than 30min, you may chang this value"
""                   you can override at .vimrc"
"
"
""g:auto_update_cscope_ctags_backup_run_py_dir_cache"
""default ~/.vim/plugin/"
""                   you may set this in you .vimrc"
""                   for plugn run quickly, but even"
""                   you config err, we can also find it"
"
"
"=======================================================================================
" 
"        
"        
"Bugreport:
"if you have any issue, please:
"1:enable  'let g:Auto_update_cscope_ctags_debug_log = 1' in ~/.vimrc
"2:reopen vim , reproducte issue
"3:upload logfile : /tmp/.Auto_update_cscope_ctags_debug_back_run.log /tmp/.Auto_update_cscope_ctags_debug_log.log
"
"
