set nocp
set number
set ruler
set laststatus=2
set mouse=a
set mousehide
set showcmd
set matchpairs+=<:>
set list
set listchars=tab:>-,trail:-
set autoread
set t_Co=256
set confirm
set title
set history=128
set shiftwidth=4
set tabstop=4
set smartindent
set directory=/tmp
set formatoptions=cro
syntax on

" set spell spelllang=ru,en

if has("autocmd")
    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event
    " handler (happens when dropping a file on gvim).
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif
endif
