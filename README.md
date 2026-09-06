# vim-conf

基于 [vim-plug](https://github.com/junegunn/vim-plug) + [coc.nvim](https://github.com/neoclide/coc.nvim) 的个人 Vim 配置，提供代码补全、诊断、跳转、文件模糊搜索和文件树等功能。

> 注意：只是把 `.vimrc` 拷到另一台机器**不够**。真正完整的配置由四部分组成：本仓库的配置文件 + vim-plug + vim-plug 插件 + coc 扩展 + 系统级命令，下面按顺序操作即可。

## 仓库结构

| 文件 | 说明 |
| --- | --- |
| `.vimrc` | Vim 主配置（按键、插件列表、coc 集成） |
| `.vim/coc-settings.json` | coc.nvim 与语言服务器配置 |
| `README.md` | 本说明 |

## 环境要求

- Vim 9（或 >= 8.2 且支持 `<Cmd>`）或 Neovim
- `git`、`curl`（安装 vim-plug / 插件时需要）
- Node.js >= 18（coc.nvim 及其扩展的运行环境）
- `clangd`（C/C++ 补全/诊断，路径见 `.vim/coc-settings.json`）
- `rg`（ripgrep，`:Rg` 与 coc-fzf-preview 的预览依赖它）
- Python 3（使用 coc-pyright 编写 Python 时需要）

## 快速安装

### 1. 获取本仓库

```bash
git clone https://github.com/quehengrong/vim-conf.git
cd vim-conf
```

### 2. 安装配置文件

推荐用软链接，之后 `git pull` 即可同步更新：

```bash
mkdir -p ~/.vim
ln -sf "$PWD/.vimrc" ~/.vimrc
ln -sf "$PWD/.vim/coc-settings.json" ~/.vim/coc-settings.json
```

不想用软链接就直接复制：

```bash
cp .vimrc ~/.vimrc
cp .vim/coc-settings.json ~/.vim/coc-settings.json
```

### 3. 安装 vim-plug

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### 4. 安装 Vim 插件

打开 Vim 并执行：

```vim
:PlugInstall
```

插件列表里的 `junegunn/fzf` 会在安装后自动编译到 `~/.fzf`（post-update hook），不需要额外安装 fzf。

### 5. 安装 coc 扩展

```vim
:CocInstall -sync coc-clangd coc-json coc-tsserver coc-pyright coc-pairs coc-explorer coc-fzf-preview
```

重启 Vim 即可使用。

## 常用按键

`<leader>` 是空格键。

| 模式 | 按键 | 功能 |
| --- | --- | --- |
| 插入 | `Tab` | 触发/下一个补全项 |
| 插入 | `Shift-Tab` | 上一个补全项 |
| 插入 | `Enter` | 补全菜单可见时确认选中项，否则正常换行 |
| 普通 | `[g` / `]g` | 上一条/下一条诊断 |
| 普通 | `gd` / `gy` | 跳转到定义 / 类型定义 |
| 普通 | `gi` / `gr` | 跳转到实现 / 查找引用 |
| 普通 | `K` | 查看悬浮文档 |
| 普通 | `<leader>rn` | 符号重命名 |
| 普通 | `<leader>f` | fzf 模糊搜索文件（`:Files`） |
| 普通 | `<leader>g` | fzf 内容搜索（`:Rg`） |
| 普通 | `<space>e` | coc-explorer 文件树 |

另外光标悬停时会自动高亮当前符号及其引用；`:NERDTreeToggle` 也可按需打开 NERDTree 文件树。

## 需要按机器调整的地方

`.vim/coc-settings.json` 里写死了 `"clangd.path": "/usr/bin/clangd"`。换机器后先用 `which clangd` 确认实际路径：

- Ubuntu：`sudo apt install clangd`，通常就是 `/usr/bin/clangd`；
- macOS / 其他发行版：若路径不同，请把 `clangd.path` 改成 `which clangd` 的输出。

## 更新

```bash
git -C ~/vim-conf pull          # 如果用了软链接
# 然后在 Vim 内执行:
:PlugUpdate
:CocUpdate
```

## 常见问题

- **Tab / 补全没反应**：检查 `:CocInfo`，确认 Node.js 版本 >= 18 且 coc 扩展安装成功。
- **`E492: Not an editor command: Files`**：说明 `junegunn/fzf.vim` 未安装，重新执行 `:PlugInstall`。
- **`CocCommand explorer` 报错**：需要先 `:CocInstall coc-explorer`。
- **C/C++ 补全不可用**：确认 `clangd` 已安装，且路径与 `.vim/coc-settings.json` 中的 `clangd.path` 一致。
