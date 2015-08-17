set nocompatible
"NeoBundle Scripts-----------------------------
if has('vim_starting')
"  if &compatible
"    set nocompatible               " Be iMproved
"  endif

  " Required:
  set runtimepath+=/home/ubuntu/.vim/bundle/neobundle.vim/
endif

" Required:
call neobundle#begin(expand('/home/ubuntu/.vim/bundle'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" Add or remove your Bundles here:
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'Shougo/neosnippet.vim'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'ctrlpvim/ctrlp.vim'
NeoBundle 'flazz/vim-colorschemes'

" You can specify revision/branch/tag.
NeoBundle 'Shougo/vimshell', { 'rev' : '3787e5' }
NeoBundle 'tpope/vim-rails'

let g:syntastic_mode_map = { 'mode': 'passive',
            \ 'active_filetypes': ['ruby', 'javascript','coffee', 'scss'] }
let g:syntastic_ruby_checkers = ['rubocop'] " or ['rubocop', 'mri']
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_save = 1
"let g:syntastic_javascript_checkers = ['jshint']
"let g:syntastic_coffee_checkers = ['coffeelint']
"let g:syntastic_scss_checkers = ['scss_lint']
"let g:syntastic_error_symbol='✗'
"let g:syntastic_warning_symbol='⚠'
"let g:syntastic_style_error_symbol = '✗'
"let g:syntastic_style_warning_symbol = '⚠'
"let g:syntastic_check_on_wq = 1
"hi SyntasticErrorSign ctermfg=160
"hi SyntasticWarningSign ctermfg=220
let g:syntastic_javascript_checkers = ['eslint']

NeoBundle 'slim-template/vim-slim.git'
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'pangloss/vim-javascript'
NeoBundle 'mxw/vim-jsx'
NeoBundle 'moll/vim-node'
NeoBundle 'digitaltoad/vim-jade'
"NeoBundle 'cakebaker/scss-syntax'
NeoBundle 'hail2u/vim-css3-syntax'

NeoBundle 'scrooloose/syntastic'

" Required:
call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck
"End NeoBundle Scripts-------------------------
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set list
set listchars=tab:>.,trail:_,extends:>,precedes:<,nbsp:%,eol:$
   
function! ZenkakuSpace()
  highlight ZenkakuSpace cterm=reverse ctermfg=DarkMagenta gui=reverse guifg=DarkMagenta
endfunction
   
if has('syntax')
  augroup ZenkakuSpace
    autocmd!
    autocmd ColorScheme       * call ZenkakuSpace()
    autocmd VimEnter,WinEnter * match ZenkakuSpace /　/
  augroup END
  call ZenkakuSpace()
endif
set number

set whichwrap=b,s,h,l,<,>,[,],~
set incsearch
set hlsearch
