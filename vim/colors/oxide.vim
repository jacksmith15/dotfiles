" Vim color scheme -- oxide
"
" Matches the oxide theme used by the pi agent (pi/agent/themes/oxide.json),
" which in turn descends from the oxide zsh prompt
" (oh-my-zsh/custom/themes/oxide.zsh-theme).
"
" The background is deliberately transparent: vim inherits whatever ghostty is
" painting, so the scheme follows the terminal theme (and any transparency)
" automatically. This works because oxide's own bg is #2e3436, which is exactly
" the Tango [Dark] background ghostty is configured with.
"
" Every group is defined with both cterm and gui attributes, so it works in a
" plain 256-colour terminal and picks up exact colours under 'termguicolors'.
"
" Palette
" -------
" Accents, all exact xterm-256 cube indices:
"   73   #5fafaf  turquoise   types, builtins, links, selection
"   179  #d7af5f  orange      special chars, warnings, active search
"   140  #af87d7  purple      constants, numbers, literals
"   167  #d75f5f  red         keywords, operators, imports, errors
"   107  #87af5f  limegreen   definition sites, additions, cwd
"   144  #afaf87  khaki       strings
"
" Neutrals, from the greyscale ramp (232-255):
"   236  #2e3436  bg          background (Normal leaves it transparent)
"   237  #383f41  bgRaise1    cursorline, popups, inactive statusline
"   238  #424a4d  bgRaise2    active statusline, selected tab
"   239  #4d5659  bgRaise3    matched paren, quickfix line
"   240  #585d5e  border      line numbers, splits, chrome
"   241  #626768  selected    visual selection
"   243  #777b7c  muted       comments, punctuation
"   188  #d7d7d7  offWhite    text
"
" Blended backgrounds. Each is bg mixed 14.6% toward its accent, the same ratio
" pi uses for its success/error fills; DiffText goes to 28% so the changed span
" reads as an intensification of the changed line:
"   22   #3b463c  successBg   DiffAdd
"   52   #4c3a3b  errorBg     DiffDelete, Error
"   23   #354648  changeBg    DiffChange
"   23   #3c5658  changeBg+   DiffText
"
" Note the cterm indices avoid slots 0-15 entirely. Terminal themes only
" override those, so the scheme no longer shifts when ghostty's theme changes.
" The sole exception is g:terminal_ansi_colors at the bottom, which is meant to
" track the terminal.

hi clear
if exists('syntax_on')
    syntax reset
endif

set background=dark
let g:colors_name = 'oxide'

" {{{ Base
hi Normal        ctermfg=188 ctermbg=NONE guifg=#d7d7d7 guibg=NONE
hi NormalNC      ctermfg=188 ctermbg=NONE guifg=#d7d7d7 guibg=NONE
hi Cursor        ctermfg=236 ctermbg=188  guifg=#2e3436 guibg=#d7d7d7
hi lCursor       ctermfg=236 ctermbg=179  guifg=#2e3436 guibg=#d7af5f
hi CursorLine    ctermfg=NONE ctermbg=237 guifg=NONE    guibg=#383f41 cterm=NONE gui=NONE
hi CursorColumn  ctermfg=NONE ctermbg=237 guifg=NONE    guibg=#383f41
hi ColorColumn   ctermfg=NONE ctermbg=237 guifg=NONE    guibg=#383f41
" }}}

" {{{ Syntax
hi Comment       ctermfg=243 ctermbg=NONE guifg=#777b7c guibg=NONE cterm=italic gui=italic

hi Constant      ctermfg=140 ctermbg=NONE guifg=#af87d7 guibg=NONE
hi String        ctermfg=144 ctermbg=NONE guifg=#afaf87 guibg=NONE
hi Character     ctermfg=144 ctermbg=NONE guifg=#afaf87 guibg=NONE

hi Identifier    ctermfg=188 ctermbg=NONE guifg=#d7d7d7 guibg=NONE cterm=NONE gui=NONE
hi Function      ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE

hi Statement     ctermfg=167 ctermbg=NONE guifg=#d75f5f guibg=NONE cterm=NONE gui=NONE
hi Operator      ctermfg=167 ctermbg=NONE guifg=#d75f5f guibg=NONE

" Import/include directives are keywords, not a category of their own, so the
" whole PreProc family sits on red. That leaves turquoise meaning exactly one
" thing -- types.
hi PreProc       ctermfg=167 ctermbg=NONE guifg=#d75f5f guibg=NONE
hi Type          ctermfg=73  ctermbg=NONE guifg=#5fafaf guibg=NONE cterm=NONE gui=NONE

hi Special       ctermfg=179 ctermbg=NONE guifg=#d7af5f guibg=NONE
hi Delimiter     ctermfg=243 ctermbg=NONE guifg=#777b7c guibg=NONE

hi Underlined    ctermfg=73  ctermbg=NONE guifg=#5fafaf guibg=NONE cterm=underline gui=underline
hi Ignore        ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE
hi Todo          ctermfg=236 ctermbg=179  guifg=#2e3436 guibg=#d7af5f cterm=bold gui=bold
hi Error         ctermfg=167 ctermbg=52   guifg=#d75f5f guibg=#4c3a3b cterm=bold gui=bold

hi MatchParen    ctermfg=188 ctermbg=239  guifg=#d7d7d7 guibg=#4d5659 cterm=bold gui=bold
" }}}

" {{{ Window chrome
" Chrome sits on 'border', one step dimmer than comments, so line numbers and
" fill characters recede further than anything you are meant to read.
hi LineNr        ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE
hi CursorLineNr  ctermfg=179 ctermbg=NONE guifg=#d7af5f guibg=NONE cterm=bold gui=bold
hi SignColumn    ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE
hi FoldColumn    ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE
hi Folded        ctermfg=243 ctermbg=237  guifg=#777b7c guibg=#383f41 cterm=italic gui=italic

hi StatusLine    ctermfg=188 ctermbg=238  guifg=#d7d7d7 guibg=#424a4d cterm=NONE gui=NONE
hi StatusLineNC  ctermfg=243 ctermbg=237  guifg=#777b7c guibg=#383f41 cterm=NONE gui=NONE
hi StatusLineTerm   ctermfg=188 ctermbg=238 guifg=#d7d7d7 guibg=#424a4d cterm=NONE gui=NONE
hi StatusLineTermNC ctermfg=243 ctermbg=237 guifg=#777b7c guibg=#383f41 cterm=NONE gui=NONE
hi VertSplit     ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE cterm=NONE gui=NONE

hi TabLine       ctermfg=243 ctermbg=237  guifg=#777b7c guibg=#383f41 cterm=NONE gui=NONE
hi TabLineSel    ctermfg=188 ctermbg=238  guifg=#d7d7d7 guibg=#424a4d cterm=bold gui=bold
hi TabLineFill   ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE cterm=NONE gui=NONE

hi NonText       ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE
hi EndOfBuffer   ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE
hi SpecialKey    ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE
hi Conceal       ctermfg=240 ctermbg=NONE guifg=#585d5e guibg=NONE

" Directory matches the oxide prompt's cwd colour.
hi Directory     ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE
hi Title         ctermfg=188 ctermbg=NONE guifg=#d7d7d7 guibg=NONE cterm=bold gui=bold
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
hi Visual        ctermfg=NONE ctermbg=241 guifg=NONE guibg=#626768
hi VisualNOS     ctermfg=NONE ctermbg=239 guifg=NONE guibg=#4d5659

" Warmer means active: khaki for every match, orange for the one under the
" cursor.
hi Search        ctermfg=236 ctermbg=144  guifg=#2e3436 guibg=#afaf87 cterm=NONE gui=NONE
hi IncSearch     ctermfg=236 ctermbg=179  guifg=#2e3436 guibg=#d7af5f cterm=NONE gui=NONE
hi CurSearch     ctermfg=236 ctermbg=179  guifg=#2e3436 guibg=#d7af5f cterm=NONE gui=NONE
hi WildMenu      ctermfg=236 ctermbg=73   guifg=#2e3436 guibg=#5fafaf cterm=bold gui=bold
hi QuickFixLine  ctermfg=NONE ctermbg=239 guifg=NONE    guibg=#4d5659
" }}}

" {{{ Popup menu
hi Pmenu         ctermfg=188 ctermbg=237  guifg=#d7d7d7 guibg=#383f41
hi PmenuSel      ctermfg=236 ctermbg=73   guifg=#2e3436 guibg=#5fafaf cterm=bold gui=bold
hi PmenuSbar     ctermfg=NONE ctermbg=238 guifg=NONE    guibg=#424a4d
hi PmenuThumb    ctermfg=NONE ctermbg=240 guifg=NONE    guibg=#585d5e
hi PmenuKind     ctermfg=140 ctermbg=237  guifg=#af87d7 guibg=#383f41
hi PmenuKindSel  ctermfg=236 ctermbg=73   guifg=#2e3436 guibg=#5fafaf
hi PmenuExtra    ctermfg=243 ctermbg=237  guifg=#777b7c guibg=#383f41
hi PmenuExtraSel ctermfg=236 ctermbg=73   guifg=#2e3436 guibg=#5fafaf
hi PmenuMatch    ctermfg=179 ctermbg=237  guifg=#d7af5f guibg=#383f41 cterm=bold gui=bold
hi PmenuMatchSel ctermfg=236 ctermbg=73   guifg=#2e3436 guibg=#5fafaf cterm=bold gui=bold
hi PopupNotification ctermfg=236 ctermbg=179 guifg=#2e3436 guibg=#d7af5f
" }}}

" {{{ Diff
hi DiffAdd       ctermfg=NONE ctermbg=22  guifg=NONE    guibg=#3b463c
hi DiffChange    ctermfg=NONE ctermbg=23  guifg=NONE    guibg=#354648
hi DiffDelete    ctermfg=167  ctermbg=52  guifg=#d75f5f guibg=#4c3a3b cterm=NONE gui=NONE
hi DiffText      ctermfg=NONE ctermbg=23  guifg=NONE    guibg=#3c5658 cterm=bold gui=bold

hi Added         ctermfg=107 ctermbg=NONE guifg=#87af5f guibg=NONE
hi Changed       ctermfg=73  ctermbg=NONE guifg=#5fafaf guibg=NONE
hi Removed       ctermfg=167 ctermbg=NONE guifg=#d75f5f guibg=NONE
" }}}

" {{{ Spell
hi SpellBad      ctermfg=167 ctermbg=NONE guifg=NONE guibg=NONE cterm=undercurl gui=undercurl guisp=#d75f5f
hi SpellCap      ctermfg=179 ctermbg=NONE guifg=NONE guibg=NONE cterm=undercurl gui=undercurl guisp=#d7af5f
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

" Python needs a few groups re-pointed, but python.vim uses 'hi! def link',
" whose bang defeats the 'default' -- it overrides anything set here. Those
" overrides live in after/syntax/python.vim instead.

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

" {{{ :terminal -- deliberately still Tango [Dark]
" These are not theme colours: they are what shell programs (ls, grep, git)
" request by ANSI slot. Matching ghostty's palette means an embedded shell looks
" identical to one outside vim, so this is the one place Tango belongs.
let g:terminal_ansi_colors = [
    \ '#2e3436', '#cc0000', '#4e9a06', '#c4a000',
    \ '#3465a4', '#75507b', '#06989a', '#d3d7cf',
    \ '#555753', '#ef2929', '#8ae234', '#fce94f',
    \ '#729fcf', '#ad7fa8', '#34e2e2', '#eeeeec',
    \ ]
" }}}

" vim: sw=4 foldmethod=marker
