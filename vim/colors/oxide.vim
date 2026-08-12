" Vim color scheme -- oxide
"
" Matches the Tango [Dark] terminal palette (ghostty/themes/tango-ptyxis-dark)
" and the accent colours used by the oxide zsh prompt
" (oh-my-zsh/custom/themes/oxide.zsh-theme).
"
" The background is deliberately transparent: vim inherits whatever ghostty is
" painting, so the scheme follows the terminal theme (and any transparency)
" automatically.
"
" Every group is defined with both cterm and gui attributes, so it works in a
" plain 256-colour terminal and picks up exact colours under 'termguicolors'.
"
" Palette
" -------
" Tango [Dark], terminal slots 0-15 (these follow the ghostty theme):
"   0  #2e3436  bg          8  #555753  brblack / grey
"   1  #cc0000  red         9  #ef2929  brred
"   2  #4e9a06  green      10  #8ae234  brgreen
"   3  #c4a000  yellow     11  #fce94f  bryellow
"   4  #3465a4  blue       12  #729fcf  brblue
"   5  #75507b  magenta    13  #ad7fa8  brmagenta
"   6  #06989a  cyan       14  #34e2e2  brcyan
"   7  #d3d7cf  fg         15  #eeeeec  brwhite
"
" oxide prompt accents, fixed xterm-256 cube indices (unaffected by the
" terminal theme, which only overrides slots 0-15):
"   73   #5fafaf  turquoise   git branch
"   179  #d7af5f  orange      unstaged marker
"   140  #af87d7  purple
"   167  #d75f5f  red         error
"   107  #87af5f  limegreen   cwd, staged marker
"
" Neutral fills, used where the palette has no step between bg and grey:
"   237  #383e40  subtle raised background
"   238  #444a4c  selected raised background

hi clear
if exists('syntax_on')
    syntax reset
endif

set background=dark
let g:colors_name = 'oxide'

" {{{ Base
hi Normal        ctermfg=7   ctermbg=NONE guifg=#d3d7cf guibg=NONE
hi NormalNC      ctermfg=7   ctermbg=NONE guifg=#d3d7cf guibg=NONE
hi Cursor        ctermfg=0   ctermbg=7    guifg=#2e3436 guibg=#d3d7cf
hi lCursor       ctermfg=0   ctermbg=179  guifg=#2e3436 guibg=#d7af5f
hi CursorLine    ctermfg=NONE ctermbg=237 guifg=NONE    guibg=#383e40 cterm=NONE gui=NONE
hi CursorColumn  ctermfg=NONE ctermbg=237 guifg=NONE    guibg=#383e40
hi ColorColumn   ctermfg=NONE ctermbg=237 guifg=NONE    guibg=#383e40
" }}}

" {{{ Syntax
hi Comment       ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE cterm=italic gui=italic

hi Constant      ctermfg=140 ctermbg=NONE guifg=#af87d7 guibg=NONE
hi String        ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE
hi Character     ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE

hi Identifier    ctermfg=7   ctermbg=NONE guifg=#d3d7cf guibg=NONE cterm=NONE gui=NONE
hi Function      ctermfg=179 ctermbg=NONE guifg=#d7af5f guibg=NONE

hi Statement     ctermfg=167 ctermbg=NONE guifg=#d75f5f guibg=NONE cterm=NONE gui=NONE
hi Operator      ctermfg=7   ctermbg=NONE guifg=#d3d7cf guibg=NONE

hi PreProc       ctermfg=73  ctermbg=NONE guifg=#5fafaf guibg=NONE
hi Type          ctermfg=73  ctermbg=NONE guifg=#5fafaf guibg=NONE cterm=NONE gui=NONE

hi Special       ctermfg=179 ctermbg=NONE guifg=#d7af5f guibg=NONE
hi Delimiter     ctermfg=7   ctermbg=NONE guifg=#d3d7cf guibg=NONE

hi Underlined    ctermfg=12  ctermbg=NONE guifg=#729fcf guibg=NONE cterm=underline gui=underline
hi Ignore        ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE
hi Todo          ctermfg=0   ctermbg=179  guifg=#2e3436 guibg=#d7af5f cterm=bold gui=bold
hi Error         ctermfg=15  ctermbg=1    guifg=#eeeeec guibg=#cc0000 cterm=NONE gui=NONE

hi MatchParen    ctermfg=15  ctermbg=8    guifg=#eeeeec guibg=#555753 cterm=bold gui=bold
" }}}

" {{{ Window chrome
hi LineNr        ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE
hi CursorLineNr  ctermfg=179 ctermbg=NONE guifg=#d7af5f guibg=NONE cterm=bold gui=bold
hi SignColumn    ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE
hi FoldColumn    ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE
hi Folded        ctermfg=8   ctermbg=237  guifg=#555753 guibg=#383e40 cterm=italic gui=italic

hi StatusLine    ctermfg=15  ctermbg=8    guifg=#eeeeec guibg=#555753 cterm=NONE gui=NONE
hi StatusLineNC  ctermfg=7   ctermbg=237  guifg=#d3d7cf guibg=#383e40 cterm=NONE gui=NONE
hi StatusLineTerm   ctermfg=15 ctermbg=8    guifg=#eeeeec guibg=#555753 cterm=NONE gui=NONE
hi StatusLineTermNC ctermfg=7  ctermbg=237  guifg=#d3d7cf guibg=#383e40 cterm=NONE gui=NONE
hi VertSplit     ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE cterm=NONE gui=NONE

hi TabLine       ctermfg=7   ctermbg=237  guifg=#d3d7cf guibg=#383e40 cterm=NONE gui=NONE
hi TabLineSel    ctermfg=15  ctermbg=8    guifg=#eeeeec guibg=#555753 cterm=bold gui=bold
hi TabLineFill   ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE cterm=NONE gui=NONE

hi NonText       ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE
hi EndOfBuffer   ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE
hi SpecialKey    ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE
hi Conceal       ctermfg=8   ctermbg=NONE guifg=#555753 guibg=NONE

" Directory matches the oxide prompt's cwd colour.
hi Directory     ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE
hi Title         ctermfg=15  ctermbg=NONE guifg=#eeeeec guibg=NONE cterm=bold gui=bold
" }}}

" {{{ Messages
hi ErrorMsg      ctermfg=167 ctermbg=NONE guifg=#d75f5f guibg=NONE cterm=bold gui=bold
hi WarningMsg    ctermfg=179 ctermbg=NONE guifg=#d7af5f guibg=NONE
hi ModeMsg       ctermfg=179 ctermbg=NONE guifg=#d7af5f guibg=NONE cterm=bold gui=bold
hi MoreMsg       ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE
hi Question      ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE
" }}}

" {{{ Selection and search
" Visual sets background only, so syntax colours survive the selection.
hi Visual        ctermfg=NONE ctermbg=8   guifg=NONE guibg=#555753
hi VisualNOS     ctermfg=NONE ctermbg=238 guifg=NONE guibg=#444a4c

hi Search        ctermfg=0   ctermbg=179  guifg=#2e3436 guibg=#d7af5f cterm=NONE gui=NONE
hi IncSearch     ctermfg=0   ctermbg=11   guifg=#2e3436 guibg=#fce94f cterm=NONE gui=NONE
hi CurSearch     ctermfg=0   ctermbg=11   guifg=#2e3436 guibg=#fce94f cterm=NONE gui=NONE
hi WildMenu      ctermfg=0   ctermbg=73   guifg=#2e3436 guibg=#5fafaf cterm=bold gui=bold
hi QuickFixLine  ctermfg=NONE ctermbg=238 guifg=NONE    guibg=#444a4c
" }}}

" {{{ Popup menu
hi Pmenu         ctermfg=7   ctermbg=237  guifg=#d3d7cf guibg=#383e40
hi PmenuSel      ctermfg=0   ctermbg=73   guifg=#2e3436 guibg=#5fafaf cterm=bold gui=bold
hi PmenuSbar     ctermfg=NONE ctermbg=238 guifg=NONE    guibg=#444a4c
hi PmenuThumb    ctermfg=NONE ctermbg=8   guifg=NONE    guibg=#555753
hi PmenuKind     ctermfg=140 ctermbg=237  guifg=#af87d7 guibg=#383e40
hi PmenuKindSel  ctermfg=0   ctermbg=73   guifg=#2e3436 guibg=#5fafaf
hi PmenuExtra    ctermfg=8   ctermbg=237  guifg=#555753 guibg=#383e40
hi PmenuExtraSel ctermfg=0   ctermbg=73   guifg=#2e3436 guibg=#5fafaf
hi PmenuMatch    ctermfg=179 ctermbg=237  guifg=#d7af5f guibg=#383e40 cterm=bold gui=bold
hi PmenuMatchSel ctermfg=0   ctermbg=73   guifg=#2e3436 guibg=#5fafaf cterm=bold gui=bold
hi PopupNotification ctermfg=0 ctermbg=179 guifg=#2e3436 guibg=#d7af5f
" }}}

" {{{ Diff
hi DiffAdd       ctermfg=NONE ctermbg=22  guifg=NONE    guibg=#33401f
hi DiffChange    ctermfg=NONE ctermbg=23  guifg=NONE    guibg=#2c3a45
hi DiffDelete    ctermfg=167  ctermbg=52  guifg=#d75f5f guibg=#3f2222 cterm=NONE gui=NONE
hi DiffText      ctermfg=NONE ctermbg=58  guifg=NONE    guibg=#4a3a1a cterm=bold gui=bold

hi Added         ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE
hi Changed       ctermfg=73  ctermbg=NONE guifg=#5fafaf guibg=NONE
hi Removed       ctermfg=167 ctermbg=NONE guifg=#d75f5f guibg=NONE
" }}}

" {{{ Spell
hi SpellBad      ctermfg=167 ctermbg=NONE guifg=NONE guibg=NONE cterm=undercurl gui=undercurl guisp=#d75f5f
hi SpellCap      ctermfg=12  ctermbg=NONE guifg=NONE guibg=NONE cterm=undercurl gui=undercurl guisp=#729fcf
hi SpellRare     ctermfg=140 ctermbg=NONE guifg=NONE guibg=NONE cterm=undercurl gui=undercurl guisp=#af87d7
hi SpellLocal    ctermfg=73  ctermbg=NONE guifg=NONE guibg=NONE cterm=undercurl gui=undercurl guisp=#5fafaf
" }}}

" {{{ Group links
hi! link Number        Constant
hi! link Float         Constant
hi! link Boolean       Constant

hi! link Conditional   Statement
hi! link Repeat        Statement
hi! link Label         Statement
hi! link Keyword       Statement
hi! link Exception     Statement

hi! link Include       PreProc
hi! link Define        PreProc
hi! link Macro         PreProc
hi! link PreCondit     PreProc

hi! link StorageClass  Type
hi! link Structure     Type
hi! link Typedef       Type

hi! link SpecialChar   Special
hi! link Tag           Special
hi! link SpecialComment Comment
hi! link Debug         Special

hi! link Whitespace    NonText
hi! link LineNrAbove   LineNr
hi! link LineNrBelow   LineNr
hi! link FloatBorder   VertSplit
hi! link WinSeparator  VertSplit
hi! link MsgSeparator  StatusLineNC
hi! link Terminal      Normal

hi! link qfFileName    Directory
hi! link qfLineNr      LineNr
hi! link helpHyperTextJump Underlined
hi! link helpSpecial   Special
hi! link diffAdded     Added
hi! link diffChanged   Changed
hi! link diffRemoved   Removed
hi! link diffFile      Directory
hi! link diffLine      Title
" }}}

" {{{ :terminal -- the Tango [Dark] palette, so embedded shells look native
let g:terminal_ansi_colors = [
    \ '#2e3436', '#cc0000', '#4e9a06', '#c4a000',
    \ '#3465a4', '#75507b', '#06989a', '#d3d7cf',
    \ '#555753', '#ef2929', '#8ae234', '#fce94f',
    \ '#729fcf', '#ad7fa8', '#34e2e2', '#eeeeec',
    \ ]
" }}}

" vim: sw=4 foldmethod=marker
