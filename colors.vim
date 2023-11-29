vim9script
# This file will be loaded automatically if placed under .vim/after/plugin
# directory.

#colorscheme desert256
#hi ColorColumn ctermbg=DarkGrey
#hi Todo		ctermfg=red ctermbg=yellow
#hi StatusLineNC ctermfg=gray
#highlight Pmenu ctermbg=gray guibg=gray
#highlight Constant ctermfg=75
#

# Quickfix list highlight color
# Dark grey
#hi QuickFixLine term=reverse ctermbg=237

# Comment out below for light backgrounds!
#highlight Normal ctermfg=white
#hi StatusLine term=bold,reverse cterm=bold,reverse ctermfg=145 ctermbg=16 gui=reverse guifg=#c2bfa5 guibg=#000000
hi StatusLine cterm=bold,reverse
hi MatchParen ctermbg=blue
# Need to specify other search hit highlight color for Solarized light
# colortheme.
hi Search cterm=NONE ctermfg=white ctermbg=blue

# Try to make the mode sign "--INSERT--" more visible.
hi ModeMsg cterm=bold ctermfg=black ctermbg=yellow

