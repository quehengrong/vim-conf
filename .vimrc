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
" 行级 Git 改动(增删改标记/hunk 预览)
Plug 'airblade/vim-gitgutter'
" 编辑增强
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
" 快速跳转
Plug 'justinmk/vim-sneak'
" Vim 与 tmux 分屏联动(C-h/j/k/l)
Plug 'christoomey/vim-tmux-navigator'
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
" 代码动作/自动修复
nmap <silent> <leader>a <Plug>(coc-codeaction)
xmap <silent> <leader>a <Plug>(coc-codeaction-selected)
nmap <silent> <leader>qf <Plug>(coc-fix-current)
" coc 列表(诊断/大纲/片段)
nnoremap <leader>d :CocList diagnostics<CR>
nnoremap <leader>o :CocList outline<CR>
nnoremap <leader>s :CocList snippets<CR>

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
nnoremap <leader>F :GFiles<CR>
nnoremap <leader>l :BLines<CR>

" ==== 文件树 (coc-explorer) ====
nmap <space>e <Cmd>CocCommand explorer<CR>

" ==== 终端开关 (<leader>t) ====
let s:term_bufnr = -1

" 返回终端 buffer 所在窗口号;没有可见的终端时返回 -1
function! s:TermWin() abort
  if s:term_bufnr < 0 || !bufexists(s:term_bufnr)
    return -1
  endif
  let l:wins = win_findbuf(s:term_bufnr)
  return empty(l:wins) ? -1 : l:wins[0]
endfunction

function! ToggleTerm() abort
  " 终端已显示:关闭窗口(进程留在后台,重新打开时历史仍在)
  let l:win = s:TermWin()
  if l:win > 0
    if winnr('$') > 1
      let l:nr = win_id2win(l:win)
      if l:nr > 0
        execute l:nr . 'close!'
      endif
    else
      enew
    endif
    return
  endif

  " 旧终端还活着就复用(保留 shell 历史),已经退出(如输入了 exit)则清掉重开
  if s:term_bufnr > 0 && bufexists(s:term_bufnr) && bufloaded(s:term_bufnr)
    if term_getstatus(s:term_bufnr) =~# 'running'
      execute 'botright sbuffer ' . s:term_bufnr
      setlocal nonumber norelativenumber signcolumn=no
      " sbuffer 只把 buffer 放回窗口,要再进 Terminal-Job 模式才能直接输入
      call feedkeys('i', 'n')
      return
    endif
    execute 'silent! bwipeout! ' . s:term_bufnr
  endif

  botright terminal
  let s:term_bufnr = bufnr('%')
  setlocal nonumber norelativenumber signcolumn=no
endfunction

nnoremap <silent> <leader>t :call ToggleTerm()<CR>
" 终端模式下 Esc 回到普通模式(再按 <leader>t 即可关闭)
tnoremap <silent> <Esc> <C-\><C-n>
" 终端模式下 <C-t> 直接关闭/隐藏终端
tnoremap <silent> <C-t> <C-\><C-n>:call ToggleTerm()<CR>

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
