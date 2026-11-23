# 安装、试用与恢复

## 在本机启动

```sh
~/.local/bin/nvim-zed
~/.local/bin/nvim-zed path/to/file.cpp
```

这是 `NVIM_APPNAME=nvim-zed` 的隔离配置，默认采用 Catppuccin Mocha，可用 `空格 ut` 预览、切换并记住其他主题。按用户后续要求，本机 Zsh/Bash 的交互式 `vim` 已设置别名指向此启动器，因此 `vim path/to/file.cpp` 也会使用这套配置。`.vimrc`、CoC、tmux 和 Zed 配置保留；不设置 EDITOR/VISUAL。未创建全局 `nvim` 链接，启动器直接调用用户目录中的固定版本。

新终端自动生效；当前 Zsh 可执行 `source ~/.zshrc`，Bash 可执行 `source ~/.bash_aliases`。别名只影响交互 shell，不改变通过 PATH 启动编辑器的外部程序。需要原 Vim 时使用 `command vim` 或 `/usr/local/bin/vim`。

进入后先用 `:NeoHealth` 查看工具与路径，`:NeoRoot` 查看搜索根和 LSP 根，`空格 ?` 查看映射。`空格` 后暂停会显示 which-key 分组。

## 在另一台 Linux x86_64 机器安装

```sh
git clone --branch neo-vim <你的仓库地址> vim-conf
cd vim-conf
./scripts/install-neovim.sh
./scripts/install-neovim-tools.sh
```

第一个脚本安装 Neovim、隔离配置链接、启动器及锁定插件；第二个脚本安装独立 Node、锁定 npm 工具、LuaLS、Tree-sitter CLI 和 parsers。需要 git、curl、tar、xz、gzip 和 C/C++ 编译器。老系统二进制不能运行时，Neovim 从源码编译，需要 make、CMake、Ninja、unzip、gettext 等上游构建依赖；Tree-sitter CLI 会使用隔离 Rust 工具链编译。脚本不使用 sudo，不升级 glibc。

新机首次安装可能需要数分钟到十几分钟，取决于源码编译和下载速度。clangd、Pyright、Lazygit 和 rg/fd 优先复用本机已有工具，需按 `TOOLS.md` 补齐；缺少工具会在 `:NeoHealth` 中标识。脚本暂不支持 macOS/ARM 或自定义 XDG_DATA_HOME；使用默认 `~/.local/share` 数据目录。

脚本拒绝覆盖已有的无关链接或目录。若已有 `~/.config/nvim-zed`，先保留原路径再安装；不要复制 `ln -sf` 覆盖。升级 Neovim 与 Tree-sitter 前先核对兼容性。

## 安装位置

| 路径 | 内容 |
| --- | --- |
| `~/.config/nvim-zed` | 链接到本仓库 `nvim/` |
| `~/.local/bin/nvim-zed` | 链接到本仓库启动脚本 |
| `~/.local/opt/nvim-0.12.6` | 当前机器编译的 Neovim |
| `~/.local/opt/neo-vim-node-22.21.1` | 仅启动器优先使用的 Node |
| `~/.local/opt/tree-sitter-cli-0.26.1` | 兼容本机的 Tree-sitter CLI |
| `~/.local/opt/neo-vim-luals-3.19.2` | Lua language server |
| `~/.local/opt/neo-vim-rust` | 本机编译 CLI 所需的隔离工具链 |
| `~/.local/share/nvim-zed` | 插件、parser、ACP/LSP npm 依赖 |
| `~/.local/state/nvim-zed` | 撤销、日志与状态 |
| `~/.cache/nvim-zed` | 编辑器缓存 |
| `~/.cache/neo-vim-install` | 安装下载、构建和验证日志 |

本次安装前以上配置入口不存在，没有覆盖既有配置，因此没有需要恢复的旧入口。业务文件和 Git index 未用于写入测试。

## 本机覆盖配置

将 `nvim/local.example.lua` 复制为 `nvim/local.lua`，按需填写绝对路径或代理；该文件被 Git 忽略。

```lua
return {
  clangd = '/path/to/clangd',
  agent_provider = 'codex-acp',
  -- extended_keys = true,
  -- lsp = { clangd = { cmd = { 'clangd', '--compile-commands-dir=/path/to/build' } } },
}
```

默认从 PATH 查找 clangd；本机已有 `~/.local/bin/clangd`，不重复下载。项目优先提供真实 `compile_commands.json` 与 `.clangd`；编辑器不会为大型项目自动跑构建。Python 使用项目环境，必要时填写 `python` 或按项目配置 server。

## Claude / Codex

`空格 aa` 默认在右侧打开 Codex CLI，`空格 ac` 打开 Claude CLI。`空格 aA` 打开 ACP agent 面板（默认 Codex），`空格 ap` 选 ACP provider 并创建独立会话，`空格 al` 返回已有 ACP 会话。Claude/Codex 都需要各自有效的认证或服务配置。已有 CLI 能用不代表 ACP 一定能用；两者启动环境与 provider 行为可能不同。

`空格 ap` 刻意使用新会话，避免把 Claude 的会话身份误当 Codex 会话；旧会话仍可从项目会话列表返回。跨项目建议新 tab 或独立 Neovim 进程。包装层按项目根维护会话，切换项目后创建或找回对应会话，不使用插件默认的“最近任意会话”回退。

首次连接需要登录时，在自己的终端完成 provider 文档要求的认证，随后重试。没有启用 bypass/自动批准模式。插件面板中按当前 provider 的审批提示操作；`空格 ax` 取消生成。`空格 ac/ao` 分别在右侧约 40% 宽度的分屏中打开 Claude/Codex 官方 CLI，重复快捷键可隐藏或恢复，保留运行中的进程。

CLI 初始化完成后，可回到代码选中文本，按 `空格 as` 加到 Codex CLI 的输入草稿，或 `空格 aS` 加到 Claude CLI。代码附带路径、行号和未保存状态，追加后可继续输入要求，手动 Enter 才提交。原 ACP 选区入口改为 `空格 av`。

代理只写入忽略的本机覆盖文件或已有环境变量，不复制 Zed 端口配置到公共配置。若从本机 SSH 到服务器，`127.0.0.1` 指的是服务器；自行确认服务实际可达。

## 终端与 tmux

默认关闭 Ctrl-Shift 类扩展映射；可用 `空格 ff/fg/:/e/fb/=` 完成对应操作。确认终端及 tmux 实际能传输组合键后，再打开 `extended_keys`。

tmux prefix 为 Ctrl-B 时，文件树用 `空格 e`；Ctrl-h/j/k/l 在普通模式继续切换窗口。终端输入不改这些键。Ctrl-S 若触发流控，可在当前交互 shell 明确执行 `stty -ixon`，用 `stty ixon` 恢复；安装器不改 shell 启动文件。

SSH 环境使用 Neovim 的 OSC52 剪贴板 provider，最终是否允许读取/写入由客户端终端决定。无法读取远端系统剪贴板时使用终端粘贴，编辑器内寄存器仍正常工作。

## 更新

平时启动不会自动安装缺失插件或更新 parser。复现插件使用 `:Lazy restore`；明确要升级时才使用 `:Lazy update`，review `nvim/lazy-lock.json` 变化。parser 更新显式执行 `:TSUpdate`，之后重跑结构测试并更新工具清单。

npm 工具使用 `nvim/tools/package-lock.json` 与 `npm ci`；更换版本时在隔离工具目录更新并同步清单，不改全局 npm 包。parser 的源提交见 `nvim/parsers-lock.json`，同时保留与之匹配的 Tree-sitter 插件锁。

## 回滚

直接退出 `nvim-zed`，使用 `command vim` 即可回到旧 Vim。要恢复普通 `vim` 的含义，当前 shell 执行 `unalias vim`，并删除 `~/.zshrc`、`~/.bash_aliases`（以及仓库 `zsh/.zshrc`）末尾新增的 Neovim 别名段。本机 Zsh 原文件备份位于 `~/.local/state/nvim-zed/backups/20261123-053819/zshrc`。

若要停用入口，先核对链接目标，再仅删除以下两个链接：

```sh
readlink ~/.config/nvim-zed
readlink ~/.local/bin/nvim-zed
unlink ~/.config/nvim-zed
unlink ~/.local/bin/nvim-zed
```

其余数据先保留，避免删除会话、撤销或日志。无需修改系统库或 Vim 配置。回滚编辑器配置不会回滚 agent 修改过的项目代码，项目修改需自行 review。
