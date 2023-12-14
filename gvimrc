vim9script
colorscheme desert
#hi ModeMsg gui=bold guifg=black guibg=yellow
#highlight Cursor guifg=white guibg=black
#highlight iCursor guifg=white guibg=steelblue
set guifont=DejaVu\ Sans\ Mono:h12
# For each cursor type (n, i etc.) it seems that the settings need to be given
# all with one go. You can append settings for a specific cursor with multiple
# "+=" operations.
set guicursor=n-v-c:block-blinkon0
set guicursor+=i:ver25-Cursor-blinkwait700-blinkon700-blinkoff400
#set guicursor+=n-v-c:blinkon0
#set guicursor+=i:blinkwait10
#set guicursor+=n-v-c:blinkon0 # in normal-visual selection-command modes don't blink
#set guicursor+=i:blinkwait700-blinkon700-blinkoff400
set columns=150
set guioptions-=m
set guioptions-=T
