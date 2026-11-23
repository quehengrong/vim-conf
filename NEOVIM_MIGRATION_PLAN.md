# Vim → Neovim 迁移方案与 Codex 执行说明

状态：用户已于 2026-11-23 授权实施，分支 `neo-vim`，主题指定为 Dracula。实际验收见 `docs/neovim/VALIDATION.md`。

实施调整：原生 gitgraph 在 NDAS 大仓库同步加载约 12 秒，默认改为异步 `git log --graph` 视图，保留提交选择、端点比较和 Diffview 联动；`:NeoNativeGraph` 仍可显式打开原生图。

本文既是迁移设计，也是 Codex 的执行规格。实施保留隔离试用和旧 Vim，不自动切换默认编辑器。

## 1. 目标与取舍

将终端 Vim 迁移为一套精简、可复现的 Neovim 开发环境，优先适配 C/C++，兼顾 Python、Lua、JSON 和现有 JavaScript/TypeScript 能力。

必须覆盖：

1. Zed 风格的文件搜索、项目搜索、保存、侧栏、代码操作和窗口管理。
2. 语法感知的函数、结构体和类选择，以及上下一个结构的跳转。
3. 原生 LSP 的补全、定义、引用、重命名、诊断与格式化。
4. 在编辑器内使用 Claude、Codex，发送选区和文件，处理操作审批并查看改动。
5. 分支和提交关系图、工作区双栏 diff、暂存区 diff、文件历史与按块操作。
6. 终端、SSH、tmux 下稳定工作；原有 Vim 保持可用。

采用自定义 Lua 配置和 lazy.nvim 管理插件，不直接套用大型发行版。不追求界面与 Zed 完全相同，也不承诺终端能接收全部 GUI 组合键。验收以实际操作与结果为准。

首版不包含调试器、自动执行大型构建、AI 灰字补全、多光标、自动同步远程机器、自动更新插件或替换 shell 默认编辑器。现有 surround、注释、对齐等编辑能力应保留。

## 2. 已检查的现状

以下是本机只读检查结果，不等于相关功能已经通过运行验收。

| 项目 | 已知现状 | 迁移处理 |
| --- | --- | --- |
| 配置仓库 | `/home/hque/vim-conf`，检查时工作区干净 | 新配置继续入此仓库 |
| Vim | `/usr/local/bin/vim`，9.1 | 保留可执行文件与配置 |
| Vim 配置 | `~/.vimrc` 链接到仓库 `.vimrc` | 不覆盖或改成 Neovim 配置 |
| 插件 | vim-plug、CoC、fzf、Fugitive、GitGutter、surround、commentary、sneak、easy-align、lightline、tmux navigator | 按功能替换或复用 |
| CoC | 配置链接有效，扩展包括 clangd、pyright、TS、JSON、explorer、snippets | Neovim 使用原生 LSP，不加载 CoC |
| 撤销目录 | Vim 配置的 `~/.vim/undo` 不存在 | Neovim 使用独立 state 目录并自动创建 |
| Neovim | 此前 PATH 检查未发现 `nvim` | 实施前重新确认，包括非 PATH 安装 |
| Node | `/usr/local/bin/node` 为 v20.11.1；`/usr/bin/node` 为 v10.19.0 | 显式检查 agent 进程实际使用的版本 |
| 工具 | 存在 rg、fd、fzf；CLI 的 PATH 随启动环境可能不同 | 使用普通终端和 tmux 分别检查 |
| clangd | Zed 配置指定 `~/.local/opt/clangd_23.1.0/bin/clangd`；`~/.local/bin/clangd` 链接到它 | 优先复用并检查可执行性 |
| tmux | `C-h/j/k/l` 用于 Vim 与 tmux 分屏切换 | 默认保留，不直接映射为 Zed 底栏键 |
| Zed | 本机 settings 未显式指定 `vim_mode` 或 `base_keymap`；未发现用户 keymap 文件 | 暂按 Linux Zed 默认工作区键位 + Vim 模态编辑设计 |

后续还要核实：实际使用的终端、终端运行在本机还是 SSH 客户端、tmux 版本和有效 prefix、剪贴板传输方式、Claude/Codex 安装与登录状态、项目编译数据库位置。不能从单个 shell 的 PATH 推断交互环境缺少工具。

## 3. 目标架构与插件选型

下表为首选实现，实施时核对所锁版本的 API。若存在阻断兼容问题，可先采用表中降级方案并记录原因，不悄悄删掉对应需求。

| 能力 | 首选组件 | 选择理由与边界 |
| --- | --- | --- |
| 插件管理 | `folke/lazy.nvim` | 提交 lockfile，按功能加载 |
| 语言服务 | Neovim 原生 LSP + `neovim/nvim-lspconfig` 的 server 配置 | 同一 buffer 不重复启动同类服务 |
| 补全 | `saghen/blink.cmp` + `rafamadriz/friendly-snippets` | 使用其兼容的片段机制，避免同时装两套补全引擎 |
| 语法解析 | `nvim-treesitter/nvim-treesitter` | parser 与 queries 配套锁定 |
| 结构选择/移动 | `nvim-treesitter/nvim-treesitter-textobjects` + 少量 C/C++ queries | 函数和类型必须准确，不能只找花括号 |
| 搜索、文件树、终端、Lazygit 入口 | `folke/snacks.nvim` 对应模块 | 统一入口，只开启需要的模块 |
| 按键提示 | `folke/which-key.nvim` | 显示功能分组、中文描述或清晰英文描述 |
| 状态栏 | `nvim-lualine/lualine.nvim` | 显示模式、分支、诊断、文件和 LSP 状态 |
| 配色 | `Mofiqul/dracula.nvim` | 按用户指定采用 Dracula，状态栏同步配色 |
| Git 行级操作 | `lewis6991/gitsigns.nvim` | 标记、预览、跳转、部分暂存 |
| Git 多文件对照 | `sindrets/diffview.nvim` | 工作区/暂存区 diff、历史、冲突视图 |
| Git 提交图 | `isakbm/gitgraph.nvim` | 明确配置选择提交后打开 Diffview 的 hooks |
| Git 操作面板 | Lazygit，经 Snacks 打开 | 创建/切换分支、提交、stash 等操作 |
| Agent 主入口 | `carlos-algms/agentic.nvim` | 统一 ACP 界面接入 Claude/Codex |
| Agent 备用入口 | 内置终端运行官方 CLI | ACP 故障时仍能工作，不默认安装第二套聊天插件 |
| 括号与配对 | `windwp/nvim-autopairs` | 核对与补全确认的交互 |
| surround、repeat、对齐 | 优先复用现有对应插件 | 保留 `ys/cs/ds`、重复操作和对齐能力 |
| 注释 | 优先使用目标 Neovim 的内置注释能力 | 保留 `gcc` 与可视模式 `gc` |
| tmux 联动 | `christoomey/vim-tmux-navigator` | 保留已有窗口导航习惯 |

不同时引入 Telescope 和 Snacks Picker、CoC 和原生 LSP、Neogit 和 Lazygit。Sneak 暂不自动启用：确认用户是否依赖其 `s/S` 映射，再决定保留。

官方插件功能参考：[Snacks](https://github.com/folke/snacks.nvim)、[Blink](https://github.com/saghen/blink.cmp)、[lazy.nvim](https://github.com/folke/lazy.nvim)。

### 3.1 版本与依赖策略

- 当前查到的 Neovim 最新稳定发布为 [v0.12.6](https://github.com/neovim/neovim/releases/tag/v0.12.6)，首选以此作为候选基线；实施时核对平台、glibc 和插件兼容性后锁定，不自动追 nightly。
- 当前 Tree-sitter `main` 已重写，声明需要 Neovim 0.12+ 与 tree-sitter CLI 0.26.1+；旧 `master` 是另一套配置接口。不得混用 `main` 与旧版 `nvim-treesitter.configs.setup` 示例。参见 [Tree-sitter 当前说明](https://github.com/nvim-treesitter/nvim-treesitter)。
- Neovim、Tree-sitter、textobjects、parser、query 作为一个兼容集合验证。若必须选用其他稳定组合，记录确切版本、原因及未满足项。
- `lazy-lock.json` 只锁插件提交；另用工具清单记录 Neovim、parser/CLI、clangd、Lazygit、Node 和 ACP 程序版本。不得宣称只靠 lockfile 就完整复现。
- 优先用户目录安装 Neovim，避免替换系统 Vim。插件升级手动触发；parser 安装和更新显式执行，日常启动不自动下载。
- 检查 git、curl、tar、C 编译器、rg、fd、tree-sitter CLI，以及 Blink 所锁版本需要的本地库/预编译资源。网络受限时给出具体缺失项。
- Mason 不作为首版必要依赖；优先复用已安装工具，避免重复下载 clangd。可选安装流程写入文档。

## 4. 快捷键规格

`Leader` 和 `LocalLeader` 都为空格。下列为目标映射，不表示插件默认已提供。

全局规则：普通编辑 buffer 使用 Zed 工作区习惯；补全菜单、Picker、Agent 输入框和终端使用各自上下文。不得用无条件全局映射破坏输入框或终端原有按键。

### 4.1 工作区与文件

| 功能 | 主键 | 始终可用的备用入口 | 约束 |
| --- | --- | --- | --- |
| 搜文件 | `Ctrl-P` | `空格 ff` | 普通模式及主编辑区插入模式可用 |
| 搜项目内容 | `Ctrl-Shift-F` | `空格 fg`、普通模式 `g/` | Shift 组合需实际验证 |
| 当前文件搜索 | `Ctrl-F` | `/` | 普通模式接受覆盖原向下翻页；`Ctrl-D/U` 保留 |
| 保存 | `Ctrl-S` | `:w` | 插入模式保存后仍能继续输入 |
| 命令选择器 | `Ctrl-Shift-P`、`F1` | `空格 :`、原生 `:` | 是命令/映射选择器，不等同 Zed 完整命令面板 |
| 文件侧栏 | `Ctrl-B` | `空格 e` | tmux 默认 prefix 可能先截获，不能保证主键 |
| 已打开文件 | `Ctrl-Tab` | `空格 fb` | 按 buffer 选择；不为每个文件创建 tabpage |
| 关闭当前文件 | 自定义 `空格 bd` | `:bdelete` | 保持布局；修改未保存时正常提示 |
| 打开/收起终端 | 自定义 `空格 tt` | 命令选择器 | `Ctrl-J` 保留 tmux 导航，不作为底栏开关 |
| 帮助/快捷键 | 自定义 `空格 ?` | which-key、`:help` | F1 被命令面板占用后仍有帮助入口 |

搜索统一使用当前 buffer 所属的最近 Git worktree 根；不在 Git 中时查项目标记，最后回退当前目录。符号服务根目录可以与 Git 根不同，必须展示两者并允许覆盖。切换 worktree/项目后重新计算，避免固定在启动目录。

默认尊重 `.gitignore`，排除 `.git`；为搜索隐藏文件和被忽略文件分别提供显式开关。避免为所有项目写死忽略 build 目录，防止遗漏需要查看的生成代码。

### 4.2 代码语义与补全

| 功能 | 映射 |
| --- | --- |
| 定义 / 声明 / 类型定义 | `gd` / `gD` / `gy` |
| 实现 / 引用 | `gI` / 普通模式 `gA`；保留 `gr` 兼容入口 |
| 悬浮说明 | `K`、`gh` |
| 重命名 | `F2`、普通模式 `cd`、`空格 cr` |
| 代码动作 | `g.`、`空格 ca` |
| 当前文件 / 项目符号 | `gs` / `gS` |
| 上一条 / 下一条诊断 | `[d` / `]d` |
| 项目诊断列表 | `空格 xx` |
| 格式化文件或选区 | `Ctrl-Shift-I`、`空格 =` |
| 注释 | `gcc`、可视模式 `gc`；`Ctrl-/` 为条件可用别名 |
| 对齐 | `空格 =a` 不使用，避免与 `空格 =` 前缀冲突；改用 `空格 ce` |

`gI`、普通模式 `gA`、`cd` 等采用 Zed Vim 风格，会覆盖部分原生行为；普通模式与可视模式分别配置。原有对齐 `gA` 迁到 `空格 ce`，原有 `gi` 不再占用以恢复 Vim 原语义。

补全行为：菜单打开时 Tab/Shift-Tab 选择下一项/上一项；菜单关闭且位于 snippet 跳转点时前后跳转；其余情况正常缩进/反缩进，Shift-Tab 不得变成退格。Enter 在有明确选中项时确认，其余情况换行；Esc 第一次关闭菜单，再按退出插入模式。手动补全用 `Ctrl-X Ctrl-O`，可额外提供 `Ctrl-Space`。需要测试与配对括号、中文输入和片段跳转的组合。

### 4.3 结构选择与跳转

| 操作 | 映射 | 语义 |
| --- | --- | --- |
| 整个函数 / 函数内部 | `af` / `if` 文本对象 | `vaf`、`yaf`、`daf`、`cif`、`>af` 均可组合 |
| 整个类型 / 类型内部 | `ac` / `ic` 文本对象 | C++ struct/class/union；C struct/union |
| 参数及分隔符 / 参数内部 | `aa` / `ia` 文本对象 | 支持多行参数 |
| 下一/上一函数开头 | `]m` / `[m` | 函数定义，包括成员函数；默认跳过 lambda |
| 下一/上一函数结尾 | `]M` / `[M` | 对应函数定义末尾 |
| 下一/上一类型开头 | `]]` / `[[` | 类型定义，包含嵌套类型；不把普通函数当类型 |
| 下一/上一类型结尾 | `][` / `[]` | 对应类型定义末尾 |

这是明确的目标语义，不能假定上游 `@class` 或 `@function` capture 在每种语言都天然满足。检查实际语法树和 queries，必要时在 `queries/c/textobjects.scm`、`queries/cpp/textobjects.scm` 通过扩展 query 或小型 Lua 导航逻辑补齐，避免覆盖上游全部 captures。

边界约定：

- outer 函数包含签名和函数体；模板函数应包含模板头，成员函数处理限定名和修饰符。相邻文档注释默认不包含。
- outer 类型包含模板头、主体和适用的结尾分号；inner 不包含外层花括号，空主体应可预测地处理。
- 函数文本对象在 lambda 内可选择 lambda，自 lambda 外跳转 `]m` 默认只浏览命名函数，避免大型 C++ 文件跳转过密。
- count、可视模式、操作符等待模式、jumplist 都要验证；到文件边界默认不循环并给出提示。
- 首版 C/C++ 必须满足；其他语言按各自结构解释。无 parser、语法错误或不支持的结构应明确提示，保留 LSP 符号列表作为备用，不能静默用正则冒充结构解析。

参考：[textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)、[Zed Vim 模式](https://zed.dev/docs/vim)。

### 4.4 窗口与终端限制

- 普通模式 `Ctrl-h/j/k/l` 保留 Neovim/tmux 导航。插入模式、Agent 和终端输入中不强制重映射这些按键；提供 `Ctrl-W h/j/k/l` 及 `空格 w` 分组作为编辑窗口入口。
- 分屏使用原生 `Ctrl-W v/s`，另提供 `空格 wv/ws`。`Ctrl-W` 不全局改成关闭文件。
- 检查 tmux 当前 prefix；若为 `Ctrl-B`，保留 tmux 设置，Neovim 文件树用 `空格 e`。只有用户明确偏好改变 prefix 时再另作调整。
- `Ctrl-S` 遇到 XON/XOFF 时，先确认当前交互终端状态；需要关闭流控时采用明确记录、可回滚的 shell 配置。不在启动 Neovim 时偷偷修改终端。
- 通过 Neovim 输入检测分别记录普通终端与 tmux 收到的 Shift/Ctrl 组合。支持扩展键盘协议时才启用对应别名，不把 `Ctrl-Shift-P` 错误映射成 `Ctrl-P`。
- 不承诺远程终端的系统剪贴板自动可用；根据实际环境选本地 provider 或 OSC52，并进行复制粘贴实测。

## 5. LSP 与项目配置

### 5.1 C/C++

复用 Zed 指定的 clangd 候选路径与现有参数作为起点，包括后台索引及 `-j=6`；不重复安装一份。路径由本机覆盖配置指定，公共配置优先从 PATH 查找，避免他机复用失败。

实施时确认 `compile_commands.json` 的真实来源、构建目录、容器路径与头文件搜索路径。对于 Bazel/dazel 或特殊工具链项目，优先沿用项目已有生成和映射机制，不为验证编辑器启动完整构建，不凭空生成不正确的编译数据库。项目需要的 `.clangd` 或编译目录参数必须有依据。

大型仓库不自动遍历所有工作区；clangd 的后台索引资源占用单独记录。若编译数据库暂缺，可以验收基础语法功能，但语义准确性必须标记为“待验证”，不得宣称已完成 C++ 迁移。

### 5.2 其他语言与格式化

- Python 选择单一 Pyright 服务，识别项目 venv；不要同时启动 Pyright 和同类替代服务。
- JavaScript/TypeScript、JSON 使用可复用的 server，保证现有能力不会无说明地消失；Lua 增加适合 Neovim 配置编辑的服务。
- 每个 filetype 只指定一个格式化负责人；C/C++ 优先 clangd 可用的格式化能力与项目 `.clang-format`。
- 首版默认手动格式化。原 Vim 的保存格式化会造成行为差异，需在交付说明中突出；用户如希望保留，再按 filetype 开启。
- 不因保存自动组织 import 或修改无关文件；服务缺失时提供明确提示，基本编辑和搜索仍可使用。

原生接口以所锁版本文档为准，参考 [Neovim LSP 文档](https://neovim.io/doc/user/lsp.html)。

## 6. Claude / Codex 集成

使用 `agentic.nvim` 作为唯一主聊天界面，分别接入 `claude-agent-acp` 与 `codex-acp`。它们需要单独的 provider 程序；社区插件或适配器不等于 VS Code 官方扩展，也不保证官方 CLI 的所有特性和会话完全互通。安装命令、认证方式和版本以对应 provider 文档为准。[Agentic 配置说明](https://github.com/carlos-algms/agentic.nvim)

| 操作 | 拟定映射 | 行为 |
| --- | --- | --- |
| 开关面板 | `空格 aa` | 恢复当前项目会话，不每次新开 |
| 发送选区 | 可视模式 `空格 as` | 包含代码、路径、行范围；发送前能看到上下文 |
| 添加当前文件 | `空格 af` | 明确整文件上下文，不误传整个仓库 |
| 选择 provider | `空格 ap` | 显示 Claude/Codex，切换时保留原会话身份 |
| 新建会话 | `空格 an` | 与切换 provider 分开 |
| 查看工作区改动 | `空格 ad` | 与 `空格 gd` 使用同一 Diffview 入口 |

实施要求：

1. 核实当前 CLI 与 provider 的安装、版本、登录、代理和启动目录；复用正常工作的设置。不要将 Zed 的 agent server 配置直接当作已安装 provider 的证据。
2. Zed 已存在代理设置，但本地端口在 SSH/远端可能含义不同；先验证，不把代理地址硬编码进共享配置。
3. 同一项目会话不串到其他 worktree；发送尚未保存的选区时说明这是 buffer 内容，不能假设 agent 读磁盘会得到同样内容。
4. 审批使用 provider 的正常机制，不全局启用绕过审批。验证允许、拒绝、取消任务和退出面板的行为。
5. 文件被 agent 修改后，无未保存本地编辑的 buffer 可安全刷新；有本地修改时保留冲突提示，不能覆盖。
6. Diffview 默认显示整个工作区累计改动，不能标成“仅 agent 本次修改”。如需单独归因，使用任务前基线或单独 worktree。
7. 登录状态、token、聊天历史和 MCP 凭证不入配置仓库。无需为编辑器集成重新创建全部 agent 配置。
8. ACP 不可用时提供官方 CLI 终端入口，记录缺少的选区/diff 联动，不能把降级标成完整通过。

两个 provider 分别验收：选中函数 → 加入对话 → 请求一个小改动 → 正常审批 → 查看 diff → 回到编辑器。只需要人工触发的小型验证，不自动消耗大量任务额度。聊天接入不包含 AI 自动补全。

## 7. Git 设计

### 7.1 日常入口

| 功能 | 映射 | 语义 |
| --- | --- | --- |
| Git 操作面板 | `空格 gg` | Lazygit，本地分支、切换、提交、stash 等 |
| 分支/提交图 | `空格 gl` | 显示本地与已获取的远程 refs，区分 HEAD、branch、tag |
| 工作区 diff | `空格 gd` | Diffview 同时列出未暂存与已暂存两组 |
| 暂存区 diff | `空格 gD` | index 与 HEAD 对照 |
| 文件历史 | `空格 gh` | 当前文件历史；可视模式可扩展为范围历史 |
| 下/上一个改动块 | `]c` / `[c` | diff 窗口保留原生 diff 导航 |
| 预览改动块 | `空格 gp` | 局部浮窗或内联预览 |
| 暂存/取消暂存改动块 | `空格 gs` | 根据 staged 状态操作，避免依赖废弃 API |
| 撤销工作区改动块 | `空格 gR` | 清晰提示范围后执行，不使用易误触单键 |
| blame | `空格 gb` | 当前行最近修改信息 |
| 关闭 diff 视图 | `空格 gq` | 返回原编辑布局 |

参考：[Diffview](https://github.com/sindrets/diffview.nvim)、[Gitsigns](https://github.com/lewis6991/gitsigns.nvim)、[Lazygit](https://github.com/jesseduffield/lazygit)。

### 7.2 Git Graph 与大仓库

gitgraph 上游标明仍处于开发阶段，且将大仓库加载性能列为后续工作。因此它是候选，必须做真实仓库验证。首次只展示近期有限提交，例如 300 条，提供显式扩大范围和刷新操作，不照搬一次加载 5000 条的示例。[上游说明与 Diffview hooks](https://github.com/isakbm/gitgraph.nvim)

图中 Enter 查看选中提交 diff；选择两个提交可打开范围比较。普通提交默认与第一父提交比较；merge commit 应显示比较基准并允许选父提交；根提交使用空树作为基准。不能对所有提交盲目使用 `hash^`。

如果原生图无法达到可用性能，保留同一快捷键改用 Lazygit 的提交图或有界 `git log --graph` 视图，并明确说明它与原生交互图的差异。不得静默取消提交关系图需求。

### 7.3 Diff 的边界

- 明确区分工作区对 index、index 对 HEAD，以及累计对 HEAD 的比较。
- 显式显示 untracked 文件；二进制文件给出状态，不能承诺文本 diff。测试删除、重命名和仅有新增文件的仓库。
- Diffview 读磁盘/index；未保存 buffer 不保证出现在视图中。打开时提示相关未保存文件，不自动保存所有文件。
- worktree、空仓库、detached HEAD、merge conflict 都有明确显示或错误提示；不要求首次迁移实现完整子模块管理。
- 仓库图只显示已存在本地的远程跟踪 refs，不因打开图自动 fetch。
- 迁移过程不操作用户业务仓库的暂存、提交、reset 或分支；有修改的验收在临时测试仓库完成。推送、重写历史等是用户之后显式发起的操作。

## 8. 文件布局与隔离试用

建议仓库结构：

```text
vim-conf/
├── .vimrc                          # 现有 Vim 保留
├── .vim/                           # 现有 CoC 配置保留
├── nvim/
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lua/config/{options,keymaps,lazy,autocmds}.lua
│   ├── lua/config/{root,local,health}.lua
│   ├── lua/plugins/{ui,search,completion,lsp,treesitter,git,agent,editing}.lua
│   └── after/queries/{c,cpp}/textobjects.scm
├── docs/neovim/
│   ├── KEYMAPS.md
│   ├── INSTALL.md
│   ├── VALIDATION.md
│   └── TOOLS.md                     # 实际工具版本与安装位置
└── NEOVIM_MIGRATION_PLAN.md
```

本机路径、代理等覆盖配置存放在不入 Git 的文件；不提交凭证。公共默认值必须在没有本机覆盖文件时仍能启动。工具清单记录可复现所需版本，但不复制完整私有环境。

先将 `~/.config/nvim-zed` 链接到仓库 `nvim/`，用以下方式试用：

```sh
NVIM_APPNAME=nvim-zed nvim
```

这会将试用配置与默认 Neovim 的 config/data/state/cache 分开。安装脚本不能对已有同名路径直接 `ln -sf`；先检查实际文件/符号链接、备份并写清恢复方式。若已有默认 Neovim 配置，不自动覆盖。

用户可一直使用独立启动器 `nvim-zed`；最后是否将其设置为默认 `nvim` 配置属于单独的切换步骤。不要创建 `vim=nvim` alias，不自动修改 EDITOR/VISUAL 或全局 Git 编辑器。

## 9. Codex 实施阶段与交付

### 阶段 A：基线与兼容集合

1. 重读此文及仓库适用的 AGENTS.md，检查用户最新 review 意见和 Git 工作区。
2. 记录工具版本、PATH、系统架构/glibc、链接目标、终端和 tmux 设置。
3. 检查并备份将要写入的现有路径；记录备份清单。确认 Neovim 稳定版本与插件/parser 兼容集合。
4. 安装用户目录二进制、建立隔离配置和启动方式，不切换默认编辑器。

交付：最小可启动配置、版本清单、备份清单与安装记录。

### 阶段 B：编辑、搜索与 LSP

1. 配置基础选项、状态栏、命令/按键提示、持久撤销、剪贴板。
2. 统一项目根、搜索、文件树和 buffer 管理。
3. 接入 clangd 与其他必要 LSP；验证补全、片段、格式化与错误提示。
4. 配置快捷键上下文，先保证备用键，再启用可验证的 Zed 组合键。

交付：能独立完成日常编辑的环境与快捷键文档。

### 阶段 C：代码结构

1. 安装并锁定 parser，验证 textobjects API。
2. 实现第 4.3 节语义，补齐 C/C++ queries。
3. 在小型固定样例和一个真实项目文件中验证选择范围与跳转顺序。

交付：结构选择/跳转结果，记录不支持的语法情况。

### 阶段 D：Git

1. 接入 Gitsigns、Diffview、Lazygit 和提交图。
2. 临时仓库覆盖 staged/unstaged/untracked、rename/delete、merge/root commit 等情形。
3. 在用户大仓库只读验证图与 diff 性能，不更改业务 Git 状态。

交付：Git 快捷键、图与 diff 联动、性能和边界记录。

### 阶段 E：Agent

1. 检查 provider、登录与代理，安装所需兼容适配器。
2. 接入选区/文件上下文、provider 选择、审批和改动查看。
3. Claude/Codex 分别做一次最小人工触发流程，测试失败提示和终端降级。

交付：两种 agent 的实际通过项与待验证项，不能只凭配置文件判定通过。

### 阶段 F：试用、整理与切换

1. 使用真实编辑任务完成端到端检查，修复快捷键冲突。
2. 产出安装、更新、恢复、快捷键和验收文档，生成插件 lockfile。
3. 清楚列出通过、失败和因登录/编译数据库等缺失而未验证的项目。
4. 用户 review 试用结果后再决定默认配置切换；本阶段之前原 Vim 始终可用。

## 10. 验收清单

实施时逐项填写“通过 / 失败 / 未验证”，附最少必要证据，不预先勾选。

| 类别 | 验收内容 | 方法 |
| --- | --- | --- |
| 基础 | 隔离启动无配置错误；缺工具可诊断 | headless 加载检查 + 交互启动 |
| 基础 | 撤销重启保留，文件保存与关闭正确 | 临时文件实测 |
| 输入 | 普通终端/tmux 的常用组合键与备用键可用 | 两种环境记录实际按键 |
| 搜索 | 从子目录启动、切换项目/worktree 后范围正确 | 两个独立仓库，只读搜索 |
| LSP | clangd 仅一个实例，定义/引用/重命名准确 | 有正确编译数据库的 C++ 文件 |
| 补全 | Tab、Shift-Tab、Enter、Esc、片段和括号互相协调 | 交互输入样例 |
| 结构 | C/C++ 函数、类型、参数选择与移动 | 固定样例 + 真实文件 |
| 结构 | 模板、成员函数、嵌套 struct、union、lambda、多行宏和文件边界 | 检查行列范围与跳转序列 |
| Git | 多文件 diff、staged、untracked、rename/delete 正确 | 临时仓库 |
| Git | 单块暂存不包含其他块；撤销仅影响目标块 | 临时仓库，对照 Git CLI |
| 图 | 分叉/合并和 refs 正确；普通/根/merge 提交可查看 | 临时拓扑 + 大仓库只读 |
| Agent | Claude/Codex 均可传选区、审批、查看改动 | 各一次最小任务，用户登录可用时 |
| Agent | 未保存 buffer 不被外部改动覆盖，项目会话不串 | 临时文件和两个项目 |
| 回退 | 原 Vim 正常启动，试用配置可独立停用 | 实际启动验证 |

性能目标为验收预算，不是已有实测结果：完成安装后的普通文件热启动目标在 300ms 左右；用户大仓库应尽快出现搜索交互界面；提交图首屏目标 2 秒内；超过约 1MiB 或 20,000 行的文件默认关闭昂贵功能并支持手动恢复。记录机器和场景，不将 clangd 首次索引、网络下载混入启动指标。

只为关键自定义逻辑编写小型测试，例如 C/C++ query 范围、Git 根提交比较和项目根识别；不要为每条映射编写镜像实现的测试。Headless 检查不能替代终端按键、图形布局或 agent 登录验证。

## 11. 回滚与维护

- 试用期间回退：退出 Neovim，继续运行现有 `vim`；无需改回 `.vimrc`。
- 隔离配置停用：依据安装清单移走试用链接/启动器；保留数据与聊天记录，用户确认后再清理。不要无差别删除整个 `~/.local/share/nvim*`。
- 若已切换默认 Neovim：恢复原 `~/.config/nvim` 备份及安装清单中确实修改过的 shell 入口；撤回相关配置改动，不碰用户业务文件。
- 插件升级先在隔离环境验证，记录 lockfile 变化；Tree-sitter 升级连同 parser/query 验证。发现退化可恢复之前锁定集合。
- 回滚编辑器配置不等于回滚 agent 已修改的项目代码；代码使用正常 Git diff/review 流程处理，不用自动 reset 清理。

## 12. Review 决策点

下列是本文建议默认值，用户可以直接在 review 中修改：

1. 自定义轻量配置，先隔离试用，最后决定是否设为默认 Neovim。
2. Linux Zed 工作区习惯 + Vim 模态编辑；保留 tmux 导航/prefix，用备用键处理冲突。
3. 首版重点 C/C++，保留 Python/TS/JSON 日常能力；保存时默认不格式化。
4. `]m/[m` 默认跳过 lambda，`[[/]]` 明确跳类型；lambda 内文本对象仍可工作。
5. Agentic 为主入口，Claude/Codex 都接入；使用现有正常审批方式。
6. 首版包括 Git 提交图、Diffview 和 Lazygit；图插件若性能不达标，记录降级并保留图功能。
7. 用户已授权在 `neo-vim` 分支实施，主题改为 Dracula；默认编辑器切换仍单独决定。

## 13. 后续交给 Codex 的任务文本

> 按本仓库 NEOVIM_MIGRATION_PLAN.md 和我 review 后的修改实施 Vim → Neovim 迁移。先检查现状和兼容版本，再按阶段完成；使用独立 NVIM_APPNAME 试用，保留旧 Vim。实现 Zed 风格快捷键、C/C++ 结构文本对象和跳转、原生 LSP、Claude/Codex 集成，以及 Git 提交图和工作区 diff。锁定实际验证版本，交付配置、快捷键表、安装/回滚说明和验收结果。缺少登录或项目编译数据库时继续完成独立部分，明确记录未验证项，不编造通过结果。不自动切换默认编辑器，不操作业务仓库的提交/暂存/历史，不执行大型构建。
