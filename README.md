# vim-conf

个人开发环境配置仓库，覆盖 **Vim + tmux + Zsh + Git** 四个常用工具，克隆后按 README 操作即可在另一台机器上复用同一套配置。

> 注意：本仓库只保存“你自己的配置文件”，第三方框架和插件（vim-plug、oh-my-zsh、gpakosz/.tmux、coc 扩展等）仍需要在目标机器上安装，README 已给出对应命令。

## 仓库结构

| 文件 | 说明 |
| --- | --- |
| `.vimrc` | Vim 主配置（按键、插件列表、coc 集成） |
| `.vim/coc-settings.json` | coc.nvim 与语言服务器配置 |
| `tmux/.tmux.conf.local` | tmux 自定义配置（基于 gpakosz/.tmux，含 vim-tmux-navigator 联动） |
| `zsh/.zshrc` | zsh + oh-my-zsh 配置（含 zsh-vi-mode） |
| `zsh/.p10k.zsh` | Powerlevel10k 主题配置 |
| `git/.gitconfig` | Git 全局配置（身份、默认分支、别名） |
| `README.md` | 本说明 |

## 环境要求

- Vim 9（或 >= 8.2 且支持 `<Cmd>`）或 Neovim；建议带 `+clipboard` 的构建（见下方剪贴板说明）
- `git`、`curl`（安装 vim-plug / 插件时需要）
- Node.js >= 18（coc.nvim 及其扩展的运行环境）
- `clangd` 在 PATH 中（C/C++ 补全/诊断）
- `rg`（ripgrep，`:Rg` 与 coc-fzf-preview 的预览依赖它）
- Python 3（使用 coc-pyright 编写 Python 时需要）
- zsh + [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) + [Powerlevel10k](https://github.com/romkatv/powerlevel10k)（zsh 配置需要）
- tmux（>= 2.4）与 [gpakosz/.tmux](https://github.com/gpakosz/.tmux)（tmux 配置需要）
- 可选工具：`lsd`（ls 别名）、`fdfind`（fd 别名）、`autojump`（zshrc 的 autojump 插件用到）

## Vim 快速安装

### 1. 获取本仓库

```bash
git clone https://github.com/quehengrong/vim-conf.git
cd vim-conf
```

### 2. 安装 Vim 配置文件

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

### 4. 启用系统剪贴板（仅 Linux 需要）

检查当前 Vim 是否支持剪贴板：

```bash
vim --version | grep +clipboard
```

没有输出则安装带剪贴板支持的构建：

```bash
sudo apt-get install -y vim-gtk3
```

安装后重新打开 Vim，`.vimrc` 会自动执行 `set clipboard=unnamedplus`，Vim 内外复制粘贴互通。

### 5. 安装 Vim 插件

打开 Vim 并执行：

```vim
:PlugInstall
```

插件列表里的 `junegunn/fzf` 会在安装后自动编译到 `~/.fzf`（post-update hook），不需要额外安装 fzf。

### 6. 安装 coc 扩展

```vim
:CocInstall -sync coc-clangd coc-json coc-tsserver coc-pyright coc-pairs coc-explorer coc-fzf-preview coc-snippets https://github.com/rafamadriz/friendly-snippets@main
```

重启 Vim 即可使用。`coc-python` 已弃用，不再安装，Python 使用 coc-pyright。

## 常用按键

`<leader>` 是空格键。

| 模式 | 按键 | 功能 |
| --- | --- | --- |
| 插入 | `Tab` | 补全菜单可见时选下一项；否则展开/跳转代码片段；最后回退为插入 Tab/刷新补全 |
| 插入 | `Shift-Tab` | 上一个补全项 |
| 插入 | `Enter` | 补全菜单可见时确认选中项，否则正常换行 |
| 普通 | `[g` / `]g` | 上一条/下一条诊断 |
| 普通 | `gd` / `gy` | 跳转到定义 / 类型定义 |
| 普通 | `gi` / `gr` | 跳转到实现 / 查找引用 |
| 普通 | `K` | 查看悬浮文档 |
| 普通 | `<leader>rn` | 符号重命名 |
| 普通 | `<leader>f` | fzf 模糊搜索文件（`:Files`） |
| 普通 | `<leader>g` | fzf 内容搜索（`:Rg`） |
| 普通 | `<leader>b` | 切换已打开 buffer（`:Buffers`） |
| 普通 | `<leader>h` | 打开命令历史（`:History`） |
| 普通 | `<leader>F` | 搜索 Git 跟踪的文件（`:GFiles`） |
| 普通 | `<leader>l` | 当前文件内行搜索（`:BLines`） |
| 普通 | `<leader>a` | 对当前行应用 code action（重构等） |
| 普通 | `<leader>qf` | 自动修复当前行可修复的问题 |
| 普通 | `<leader>d` | 打开诊断列表（`:CocList diagnostics`） |
| 普通 | `<leader>o` | 打开当前文件大纲（`:CocList outline`） |
| 普通 | `<leader>s` | 打开代码片段列表（`:CocList snippets`） |
| 普通 | `s` / `S` | vim-sneak 快速跳转（按两字符后跳转） |
| 普通/可视 | `gA` | vim-easy-align 对齐（避开内置 `ga`） |
| 普通 | `<space>e` | coc-explorer 文件树 |
| 普通 | `ys`/`cs`/`ds` | vim-surround 增删改环绕符号 |
| 普通 | `gcc` | vim-commentary 注释/取消注释 |
| 普通 | `:G status` / `:G blame` | vim-fugitive Git 操作 |
| 普通 | `]c` / `[c` | vim-gitgutter 跳到下一处/上一处改动 |
| 普通 | `Ctrl-h/j/k/l` | Vim 内切换分屏，到边缘时无缝切到相邻 tmux pane |
| 普通 | `Ctrl-\` | 在 Vim split 与 tmux pane 的上一位置间往返 |

光标悬停时会自动高亮当前符号及其引用。进入 snippet 后，片段内占位符跳转由 `Tab` 完成。

## tmux 配置

仓库里只保存 tmux 的自定义部分 `tmux/.tmux.conf.local`，主题基础仍使用 [gpakosz/.tmux](https://github.com/gpakosz/.tmux)。

首次安装：

```bash
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
ln -sf ~/vim-conf/tmux/.tmux.conf.local ~/.tmux.conf.local
tmux source-file ~/.tmux.conf
```

`Ctrl-h/j/k/l` 在 Vim 分屏和 tmux pane 之间无缝切换所需的两侧配置已分别包含在 `.vimrc` 插件与 `.tmux.conf.local` 中，无需再手工加绑定。

常用 tmux 按键：

- `Ctrl-b` 或 `Ctrl-a` 为 prefix；
- `Ctrl-b -`：上下分屏；`Ctrl-b _`：左右分屏；
- `Ctrl-b x`：关闭当前 pane；`Ctrl-b &`：关闭整个窗口；
- `Ctrl-b h/j/k/l`：在 pane 之间移动；`Ctrl-b Ctrl-h/l`：切换上一个/下一个窗口。

## Zsh 配置

仓库里保存 `zsh/.zshrc` 与 `zsh/.p10k.zsh`（Powerlevel10k 主题配置）。

首次安装（假设已安装 zsh 与 oh-my-zsh）：

```bash
# 1. 软链接配置文件
ln -sf ~/vim-conf/zsh/.zshrc ~/.zshrc
ln -sf ~/vim-conf/zsh/.p10k.zsh ~/.p10k.zsh

# 2. 安装 Powerlevel10k 主题
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# 3. 安装 .zshrc 用到的自定义插件
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
git clone https://github.com/jeffreytse/zsh-vi-mode \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-vi-mode"

# 4. 重启 shell
exec zsh
```

`zsh-vi-mode` 让命令行编辑接近 Vim：

- `Esc` 进入 normal 模式，`i` 返回 insert 模式；
- 支持 `b`/`w`/`e`、`ciw`/`diw`/`caw` 等文本对象；
- 可视模式选择文本、`yy`/`p` 复制粘贴、`.` 重复上次操作；
- `vv` 用外部编辑器编辑整条命令行，`gx` 打开光标下的 URL/路径。

> 依赖提醒：`.zshrc` 里的 `ls` 别名需要 `lsd`，`fd` 别名需要 `fdfind`，`autojump` 插件需要对应二进制；新机器缺哪个工具就装哪个，或删掉对应行。

## Git 配置

仓库保存 `git/.gitconfig`，作为全局 `~/.gitconfig` 的唯一配置源：

```bash
ln -sf ~/vim-conf/git/.gitconfig ~/.gitconfig
git config --global --list   # 验证
```

包含内容：Git 身份、默认分支 `main`、`pull --rebase`、`push.autoSetupRemote` 和常用别名。

常用别名速查：

- `git st`：简洁状态；
- `git lg`：图形化提交日志；
- `git co`：切换分支；
- `git br`：查看分支及跟踪关系；
- `git unstage`：取消暂存；`git undo`：软撤销最近一次提交；
- `git amend`：修改最近一次提交信息。

## 跨机器注意事项

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
bind-key -n 'C-\' if-shell "$is_vim" 'send-keys C-\\'  'select-pane -l'
```

改完后在当前 tmux 会话里执行 `tmux source-file ~/.tmux.conf` 即可生效。

## 跨机器注意事项

- **clangd**：`coc-settings.json` 不再写死路径，coc-clangd 会从 PATH 中查找 `clangd`。换机器后确认 `which clangd` 有输出即可。
- **剪贴板**：Linux 需要 Vim 带 `+clipboard`（建议 vim-gtk3），macOS 自带支持。
- **代码片段**：需要同时安装 `coc-snippets` 和 `friendly-snippets`（coc 扩展方式），见第 6 步。

## 更新

```bash
git -C ~/vim-conf pull          # 如果用了软链接
# Vim 内执行:
:PlugUpdate
:CocUpdate

# tmux 内执行(重载 tmux 配置):
tmux source-file ~/.tmux.conf

# zsh 配置更新后:
exec zsh
```

## 常见问题

- **Tab / 补全没反应**：检查 `:CocInfo`，确认 Node.js 版本 >= 18 且 coc 扩展安装成功。
- **片段不出现**：执行 `:CocCommand workspace.showOutput snippets`，确认 coc-snippets 与 friendly-snippets 已安装。
- **`E492: Not an editor command: Files`**：说明 `junegunn/fzf.vim` 未安装，重新执行 `:PlugInstall`。
- **`CocCommand explorer` 报错**：需要先 `:CocInstall coc-explorer`。
- **C/C++ 补全不可用**：确认 `clangd` 在 PATH 中。
- **无法和系统剪贴板互通**：确认 `vim --version | grep +clipboard` 有输出；Linux 上安装 vim-gtk3。
- **zsh 没进入 vi 模式**：确认 `.oh-my-zsh/custom/plugins/zsh-vi-mode` 存在且 `~/.zshrc` 的 plugins 列表包含 `zsh-vi-mode`，然后 `exec zsh`。
- **`ciw`/`diw` 没反应**：先按 `Esc` 确保在 normal 模式（光标会变成竖线/方块提示），文本对象只在该模式生效。
