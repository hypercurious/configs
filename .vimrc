set nocompatible

set backspace=indent,eol,start
set softtabstop=4
set shiftwidth=4
set number
set relativenumber
set expandtab

filetype indent plugin on
syntax on
set showcmd
set ignorecase
set smartcase
set autoindent
set ruler
set laststatus=2
set scrolloff=999

autocmd BufNewFile *.c 0r %userprofile%\.vim\template.c "change %userprofile% to user path
