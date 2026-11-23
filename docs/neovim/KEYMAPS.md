# Neovim 快捷键

Leader 为空格。以下是实际配置；Ctrl-Shift、Ctrl-Tab、Ctrl-/ 默认不开启，需要 `local.lua` 中设置 `extended_keys = true` 并确认终端能区分。Zed 风格工作区映射主要用于编辑 buffer，不改变终端和 agent 输入模式。

## 文件与窗口

| 功能 | 按键 |
| --- | --- |
| 搜文件 | Ctrl-P（普通/插入），`空格 ff` |
| 搜项目 | `空格 fg`、`g/`；条件别名 Ctrl-Shift-F |
| 搜隐藏文件 / 含 ignored 文件 | `空格 fH` / `空格 fI` |
| 搜 ignored 文件内容 | `空格 fG` |
| 搜当前文件 | Ctrl-F、`/`（普通模式） |
| 命令选择器 | F1、`空格 :`；条件别名 Ctrl-Shift-P |
| 保存 | Ctrl-S（普通/插入）、`:w` |
| 文件树 | Ctrl-B、`空格 e`（tmux 优先用后者） |
| buffer / 最近文件 | `空格 fb` / `空格 fr` |
| 关闭 buffer、保持布局 | `空格 bd` |
| 分屏右 / 下 | `空格 wv` / `空格 ws`，原生 Ctrl-W v/s |
| 窗口导航 | Ctrl-h/j/k/l、`空格 wh/wj/wk/wl` |
| 终端 | `空格 tt` |
| 搜索快捷键 | `空格 ?` |
| 主题选择器（预览并记住选择） | `空格 ut` |
| 显示搜索根与 LSP 根 | `空格 wr`、`:NeoRoot` |

`:NeoRoot /path` 为当前 tab 覆盖搜索根；`:NeoRootReset` 清除。Git diff 始终按实际文件所属 worktree 计算，避免把搜索根覆盖误用于 Git 操作。

## 快速更换主题

默认使用 Catppuccin Mocha，保留 Dracula 作为备选。在普通模式按 `空格 ut` 打开主题选择器，输入名称过滤，用方向键或 Ctrl-n/p 选择并实时预览，Enter 确认；Esc 取消选择器时恢复原主题（若先退出输入模式，再按 Esc 关闭）。选择器只列出已安装或 Neovim 自带的主题。

通过选择器确认的主题会保存到 `~/.local/state/nvim-zed/theme.json`，重新打开 `vim` 后仍然生效。状态栏自动跟随当前主题配色，本机主题偏好不写入 Git。

也可执行 `:NeoTheme` 打开选择器，或使用命令直接切换并记住：

| 命令 | 效果 |
| --- | --- |
| `:NeoTheme catppuccin-mocha` | 深色 Mocha（默认） |
| `:NeoTheme catppuccin-macchiato` | 深色 Macchiato |
| `:NeoTheme catppuccin-frappe` | 深色 Frappé |
| `:NeoTheme catppuccin-latte` | 浅色 Latte |
| `:NeoTheme dracula` | 切回 Dracula |

原生 `:colorscheme 名称` 仍可使用，但只影响当前进程；需要重启后保留时使用 `:NeoTheme 名称` 或主题选择器。安装其他主题插件后，会出现在选择器中。

## 代码

| 功能 | 按键 |
| --- | --- |
| 定义 / 声明 / 类型 | `gd` / `gD` / `gy`，F12 定义 |
| 实现 / 引用 | `gI` / `gA`、`gr`（普通模式） |
| 悬浮说明 | `K`、`gh` |
| 重命名 | F2、`cd`、`空格 cr` |
| 代码动作 | `g.`、`空格 ca` |
| 文件符号 / 项目符号 | `gs` / `gS` |
| 打开/收起代码大纲（保留编辑焦点） | `空格 co` |
| 打开并聚焦代码大纲 | `空格 cO` |
| 开关顶部固定代码上下文 | `空格 uc` |
| 诊断上 / 下 | `[d` / `]d` |
| 诊断列表 | `空格 xx` |
| 格式化文件 / 可视选区 | `空格 =`；条件别名 Ctrl-Shift-I |
| 注释 | `gcc`、可视模式 `gc` |
| 对齐 | `空格 ce`（EasyAlign 操作符） |
| surround | 原有 `ys` / `cs` / `ds` |

保存默认不格式化。与旧 Vim 的区别：对齐由 `gA` 改为 `空格 ce`；`gi` 恢复原生用途，跳实现用 `gI`；`cd` 为 Zed 风格重命名。

Tab/Shift-Tab 在菜单中选项，否则跳片段，最后缩进/反缩进。Enter 仅确认已明确选中的项，否则换行。Esc 先关菜单，再退出插入。手动补全 Ctrl-X Ctrl-O 或 Ctrl-Space。

## 代码阅读辅助：顶部上下文与大纲

已安装 `nvim-treesitter-context` 和 `aerial.nvim`，重新打开 `vim 文件名` 后加载，跟随当前主题配色。

Tree-sitter Context 默认开启，滚动时顶部最多固定 3 行所属函数/类型上下文；无需打开侧栏。`空格 uc` 随时开关，小窗口和大文件自动跳过。

Aerial 在右侧按需打开，优先使用 LSP 符号、回退到 Tree-sitter。推荐操作流程：

1. `空格 co` 打开大纲并继续编辑代码；再次按下收起。
2. `空格 cO` 聚焦大纲，使用 `j/k` 选择函数或类型。
3. Enter 跳到对应定义；`h/l` 折叠/展开层级，`q` 关闭大纲。

`gs` 仍然是临时文件符号搜索入口，Aerial 适合常驻查看文件结构。大纲使用文字图标，不要求 Nerd Font；Ctrl-j/k 保留窗口导航用途。缺少符号时可用 `:NeoHealth` 检查 LSP，并确认当前语言的 parser 已安装。

## 结构选择与跳转

| 对象或跳转 | 按键 |
| --- | --- |
| 整函数 / 函数体 | `af` / `if` |
| 整类型 / 类型主体 | `ac` / `ic` |
| 含分隔符参数 / 参数内部 | `aa` / `ia` |
| 函数开头下 / 上 | `]m` / `[m` |
| 函数结尾下 / 上 | `]M` / `[M` |
| 类型开头下 / 上 | `]]` / `[[` |
| 类型结尾下 / 上 | `][` / `[]` |

例如 `vaf` 选择、`yaf` 复制、`daf` 删除、`cif` 修改函数体、`>af` 缩进。支持 count，例如 `2]m`。C/C++ 导航包含命名函数、成员函数，跳过 lambda；在 lambda 内使用 `af` 可选 lambda。类型包含嵌套 struct/class/union，outer 包含模板头及适用分号，默认不包含前置注释。

空函数体暂时提示 Empty body，不执行删除；文件边界不循环。其他语言使用上游 textobjects query，具体对象边界按语言而定。大文件默认关闭结构解析，需要时 `:NeoLargeFileEnable`。

## 代码折叠

已永久启用 Tree-sitter 结构折叠，文件初始全部展开，左侧显示一列折叠标记。将光标放在函数、类型或其他可折叠代码块内，在普通模式使用：

| 功能 | 按键 |
| --- | --- |
| 切换当前块折叠/展开 | `za` |
| 折叠/展开当前块 | `zc` / `zo` |
| 折叠/展开当前块及内部所有块 | `zC` / `zO` |
| 全部折叠/全部展开 | `zM` / `zR` |
| 减少/增加展开层级 | `zm` / `zr` |

例如：打开 C++ 文件后按 `zM` 浏览整体结构，再把光标移到目标函数，按 `zo` 展开；`zR` 可恢复全部展开。折叠范围取决于对应语言 parser 和折叠 query。缺少 parser 的文件没有自动折叠，终端等特殊 buffer 和大文件跳过结构折叠。

默认 expr 模式不使用 `zf` 手动创建折叠；确需手动选择范围时，先 `:setlocal foldmethod=manual`，再选中范围按 `zf`。

## Agent

| 功能 | 按键 |
| --- | --- |
| 默认 AI 入口：右侧 Codex CLI 开关 | `空格 aa`（也可用 `空格 ao`） |
| ACP agent 面板开关（默认 Codex，不自动添加文件） | `空格 aA` |
| 添加选区到 Codex CLI 输入框（不提交） | 可视模式 `空格 as` |
| 添加选区到 Claude CLI 输入框（不提交） | 可视模式 `空格 aS` |
| 添加选区到 ACP agent 面板 | 可视模式 `空格 av` |
| 添加文件到 ACP agent 面板 | `空格 af` |
| 选 provider 并新建会话 | `空格 ap` |
| 新会话 / 恢复历史 / 选活跃会话 | `空格 an` / `空格 ar` / `空格 al` |
| 取消生成 | `空格 ax` |
| 看整个工作区累计 diff | `空格 ad` |
| 右侧分屏 Claude / Codex CLI | `空格 ac` / `空格 ao` |

CLI 选区流程：用 `v`、`V`、Ctrl-V 或 `vaf` 选中文本 → `空格 as` 添加到右侧 Codex CLI（Claude 用 `空格 aS`）→ 补充要求 → 手动 Enter 提交。动作会打开或聚焦当前项目对应的 CLI，追加代码片段、文件路径与行号；未保存的修改按当前 buffer 快照传入并标注，不自动保存文件，也不修改复制寄存器。

多行代码使用 bracketed paste 粘贴，不自动按回车，已有 CLI 输入草稿会保留。大段内容可能由 CLI 显示成粘贴块，按其原生方式编辑即可。首次启动若出现登录、项目确认或其他初始化界面，先通过 `空格 aa/ac` 完成 CLI 启动，再回到代码选择并添加。控制字符 ESC/NUL 以可见转义形式传入。

ACP 选区流程：`vaf` → `空格 av` → 在面板输入要求 → 按 provider 提示审批 → `空格 ad` 检查 → 回到代码。添加上下文不会立即发送模型请求；在输入框确认后才发送。未保存选区是 buffer 内容，文件读取通常是磁盘版本。

默认按 `空格 aa` 打开 Codex CLI；`空格 ac` 打开 Claude CLI。两者使用右侧约 40% 宽度的真实分屏，左侧继续显示代码。重复同一快捷键会收起/恢复对应项目的 CLI，收起不会结束进程。CLI 输入中先按 Ctrl-\，再按 Ctrl-N 回到普通模式，即可用 Ctrl-h 切回左侧代码，或按 `空格 aa/ac/ao` 收起；也可以连按两次 Esc 进入普通模式。在终端普通模式按 `q` 隐藏窗口，按 `i` 继续输入。普通 shell 的 `空格 tt` 仍使用底部分屏。

ACP 面板仍可通过 `空格 aA` 打开，`空格 av/af/ap` 分别添加选区、添加文件和选择 provider；CLI 的 `空格 as/aS` 与这些 ACP 操作独立。

## Git

| 功能 | 按键 |
| --- | --- |
| Lazygit | `空格 gg` |
| 提交关系图 300 / 1500 条 | `空格 gl` / `空格 gL` |
| 工作区 / 暂存区 diff | `空格 gd` / `空格 gD` |
| 当前文件历史 | `空格 gh` |
| 关闭 diff | `空格 gq` |
| 上 / 下改动块 | `[c` / `]c` |
| 预览块 / blame | `空格 gp` / `空格 gb` |
| 暂存 / 取消暂存当前块 | `空格 gs`，可视模式支持部分行 |
| 丢弃工作区当前块 | `空格 gR`，有确认 |

默认图是异步 `git log --graph` 视图：先显示 HEAD 预览，再显示所有 refs。Enter 查看提交，merge 会选择比较父提交；可视选择多行后 Enter 比较最上/最下两个提交的状态。`r` 刷新，`a` 切换 HEAD/全部 refs，`q` 退出图；不自动 fetch。

原生 gitgraph 图保留为 `:NeoNativeGraph`，在大仓库可能阻塞十余秒，默认不使用。Diffview 左侧分文件，右侧双栏对比，Tab/Shift-Tab 切换文件，`空格 gq` 返回。

diff 只读取磁盘/index，未保存内容会提示但不会自动保存。`空格 ad` 显示所有当前改动，不会自动区分手工和 agent 修改。
