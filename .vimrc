" ==== 基础 ====
let mapleader = " "
let maplocalleader = " "

" ==== 编辑手感 ====
set hidden
set updatetime=100
set shortmess+=c
set signcolumn=yes
set number relativenumber
set cursorline
set scrolloff=8
set ignorecase smartcase incsearch hlsearch
set wildmenu
set splitright splitbelow
set mouse=a
set undofile
set undodir=~/.vim/undo//
if has('clipboard')
  set clipboard=unnamedplus
endif

" ==== 插件 (vim-plug) ====
call plug#begin('~/.vim/plugged')

" 配色
Plug 'junegunn/seoul256.vim'
" 对齐
Plug 'junegunn/vim-easy-align'
" fzf 本体 + vim 封装(:Files / :Rg / :Buffers)
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
" coc.nvim 智能补全/诊断
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
" Git
Plug 'tpope/vim-fugitive'
" 编辑增强
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
" 快速跳转
Plug 'justinmk/vim-sneak'
" 状态栏
Plug 'itchyny/lightline.vim'

call plug#end()

" 配色需要在 plug#end() 之后加载
silent! colorscheme seoul256

" ==== 对齐 (vim-easy-align) ====
" gA 避开 Vim 内置的 ga(查看字符编码)
vmap gA <Plug>(EasyAlign)
nmap gA <Plug>(EasyAlign)

" ==== coc.nvim 补全与片段 ====
" Tab: 补全菜单可见时选择下一项;否则展开/跳转片段;最后回退到 Tab/刷新补全
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" 补全菜单可见时,回车确认选中项;否则正常换行
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" ==== coc 诊断与导航 ====
nmap <silent><nowait> [g <Plug>(coc-diagnostic-prev)
nmap <silent><nowait> ]g <Plug>(coc-diagnostic-next)
nmap <silent><nowait> gd <Plug>(coc-definition)
nmap <silent><nowait> gy <Plug>(coc-type-definition)
nmap <silent><nowait> gi <Plug>(coc-implementation)
nmap <silent><nowait> gr <Plug>(coc-references)
nnoremap <silent> K :call ShowDocumentation()<CR>
nmap <leader>rn <Plug>(coc-rename)

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" 光标悬停时高亮当前符号及其引用
autocmd CursorHold * silent call CocActionAsync('highlight')

" ==== 模糊搜索 (fzf.vim) ====
nnoremap <leader>f :Files<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>h :History<CR>

" ==== 文件树 (coc-explorer) ====
nmap <space>e <Cmd>CocCommand explorer<CR>

" ==== 状态栏 (lightline) ====
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'cocstatus', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'cocstatus': 'coc#status'
      \ },
      \ }
