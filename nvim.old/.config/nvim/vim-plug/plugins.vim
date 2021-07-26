call plug#begin('~/.config/nvim/autoload/plugged')

	"Better syntax support
	Plug 'sheerun/vim-polyglot'
	"File explorer 
	Plug 'scrooloose/NERDTree'
	"Auto pairs for brackets
	"Plug 'jiangmiao/auto-pairs'
	"Vimwiki
	Plug 'vimwiki/vimwiki'	
	"VIm smooth scroll
	Plug 'psliwka/vim-smoothie'
	Plug 'prabirshrestha/vim-lsp'
	Plug 'omnisharp/omnisharp-vim'

	Plug 'ervandew/supertab'

	Plug 'neoclide/coc.nvim'

	"Plug 'puremourning/vimspector'

	"Plug 'prettier/vim-prettier', { 'do': 'npm install' , 'branch' : 'release/1.x' }
	Plug 'dense-analysis/ale'
	"Fuzzy Search
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	"Plug 'valloric/MatchTagAlways'
	Plug 'jiangmiao/auto-pairs'
	call plug#end()

:map <C-n> :NERDTreeToggle<CR>
:map <C-p> :GFiles<CR>
:map <C-f> :Files<CR>

" Supprot for different goto definitions for different file types.
autocmd FileType cs nmap <silent> gd :OmniSharpGotoDefinition<CR>
autocmd FileType cs nnoremap <buffer> <Leader>fu :OmniSharpFindUsages<CR>
autocmd FileType cs nnoremap <buffer> <Leader>fi :OmniSharpFindImplementations<CR>
autocmd FileType cs nnoremap <Leader><Space> :OmniSharpGetCodeActions<CR>

