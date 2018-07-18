" Install Vim Plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source /home/jack/.vimrc 
endif

" Basic lightweight config
set number
set nobackup
set nowritebackup
set noswapfile
set columns=79
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smarttab
set expandtab

filetype indent on
filetype on
filetype plugin on

syntax on
colorscheme delek
