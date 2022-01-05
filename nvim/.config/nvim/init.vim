" ==================== PLUGINS ====================
"
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'preservim/nerdtree'
" Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vimwiki/vimwiki'
Plug 'jremmen/vim-ripgrep'
Plug 'psliwka/vim-smoothie'
" Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

" Initialize plugin system
call plug#end()

" ==================== MAPPINGS ====================
"
map <C-f> :Files<CR>
map <C-n> :NERDTreeToggle<CR>
":map <C-p> :GFiles<CR>
":map <C-p> :FZF<CR>

" Bring search results to midscreen
nnoremap n nzz
nnoremap N Nzz

" ==================== SETTINGS ====================
"
set nohlsearch
set number
set relativenumber
set ignorecase
set clipboard=unnamedplus
set scrolloff=5
" use indentation of previous line
set autoindent
" use intelligent indentation for C
set smartindent
" configure tabwidth and insert spaces instead of tabs
set tabstop=4 " tab width is 4 spaces
set shiftwidth=4 " indent also with 4 spaces
set expandtab " expand tabs to spaces
" wrap lines at 100 c
" set textwidth=100

syntax on
filetype plugin on

