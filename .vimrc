" ==== 基础 ====
let mapleader = " "
let maplocalleader = " "

" ==== 插件 (vim-plug) ====
call plug#begin('~/.vim/plugged')

" 配色
Plug 'junegunn/seoul256.vim'
" 对齐
Plug 'junegunn/vim-easy-align'
" fzf 本体 + vim 封装(:Files / :Rg)
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
" coc.nvim 智能补全/诊断
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
" 文件树(按需加载)
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

call plug#end()

" 配色需要在 plug#end() 之后加载
silent! colorscheme seoul256

"" 帮助跳转到别的文件(在当前文件未保存的前提下),不弹出未保存提示
set hidden

set updatetime=100

"" 补全的时候少显示一些补全 item
set shortmess+=c

"" Use tab for trigger completion with characters ahead and navigate
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

"" 补全菜单可见时,回车确认选中项;否则正常换行
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

"" Use [g and ]g to navigate diagnostics
nmap <silent><nowait> [g <Plug>(coc-diagnostic-prev)
nmap <silent><nowait> ]g <Plug>(coc-diagnostic-next)

"" GoTo code navigation
nmap <silent><nowait> gd <Plug>(coc-definition)
nmap <silent><nowait> gy <Plug>(coc-type-definition)
nmap <silent><nowait> gi <Plug>(coc-implementation)
nmap <silent><nowait> gr <Plug>(coc-references)

"" K 查看文档
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

"" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

"" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

"" 模糊搜索文件 / 内容(依赖 fzf.vim)
nnoremap <leader>f :Files<CR>
nnoremap <leader>g :Rg<CR>

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved
set signcolumn=yes

"" 文件树(coc-explorer)
nmap <space>e <Cmd>CocCommand explorer<CR>
