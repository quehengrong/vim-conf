# 迁移验收记录

日期：2026-11-23；分支 `neo-vim`。这里区分已执行检查与仍需真实使用确认的项目。

## 已通过

| 类别 | 证据与结果 |
| --- | --- |
| 启动与主题 | Neovim 0.12.6 可运行，默认 Catppuccin Mocha，保留 Dracula，22 个插件已安装并锁定 |
| 主题选择 | 真实 PTY 检查通过：选择器实时预览、取消恢复、确认记住、Latte/Mocha 明暗切换、状态栏跟随；独立进程重启后可恢复所选主题 |
| 代码阅读辅助 | 后续一次性真实 PTY 检查通过：长 C++ 函数顶部上下文可见、最多 3 行、可开关；Aerial 展示类型/函数，回车跳到目标定义；Dracula 保持正常 |
| 核心健康检查 | `checkhealth config vim.lsp nvim-treesitter` 无 ERROR/WARNING |
| 结构与补全基础 | `smoke.lua` 当前 48 个断言通过：C/C++ 函数/嵌套类型/union、模板头和分号、lambda 选择/跳过、count、边界、操作符选择、Shift-Tab 反缩进等 |
| 多行宏 | 测试样例中宏内花括号不会被当成函数定义 |
| 永久结构折叠 | C/C++ 样例验证通过：默认全部展开、折叠栏显示，`za` 切换、`zM/zR` 全部折叠/展开可用，大文件保护返回零折叠层级 |
| LSP | `lsp.py` 11 个断言通过：临时 C++ 项目正确编译数据库、仅一个 clangd、定义、引用、重命名、符号和格式化 |
| Git | `git.py` 24 个断言通过：带空格路径、部分暂存/取消暂存/撤销、保留其他块、staged/unstaged/untracked、删除/重命名、根提交、merge 选父、独立 worktree 和异步图 |
| ACP | Claude/Codex 两个真实适配器均完成 initialize 与 session/new；未发送模型 prompt |
| AI CLI 布局与默认入口 | 一次性 PTY 检查通过：`空格 aa` 默认启动 Codex CLI，右侧真实分屏宽约 40%，左侧代码可见；Codex/Claude 均可隐藏并恢复同一进程。布局测试使用临时同名交互进程，不发送模型请求；ACP 默认 provider 同时调整为 Codex，面板入口改为 `空格 aA` |
| 真实 PTY | `ui.py` 通过：Dracula、文件选择器、输入/选择框、agent 侧栏开关、函数选区加入上下文、跨项目会话隔离、原会话恢复 |
| tmux | 使用独立 tmux 3.0a 测试服务器，重复上述 UI/agent 检查通过；未修改用户会话 |
| 撤销与文件保护 | `runtime.py` 通过：重启后可撤销，磁盘被外部修改时不覆盖未保存 buffer |
| 保留旧环境 | `.vimrc`、`.vim/`、tmux/Zed 配置保留；未设置 EDITOR/VISUAL。用户后续要求增加交互 shell 的 vim 别名，原 Vim 可用 `command vim` 启动 |
| 静态检查 | Lua 文件可加载，shell 脚本语法检查通过，Git whitespace 检查通过 |

## 性能实测

机器和 Git 缓存状态会影响结果。以下为本机测量，不是跨机器保证。

- 空配置入口的实际含插件 headless 启动并退出：5 次热运行约 58–75ms，中位数约 65ms；不包含 UI 初始化或首次 LSP 索引。
- 原生 gitgraph 在 `/home/hque/workspaces/ndas-c183-tot` 绘制 300 条提交，约 12.2 秒同步阻塞，不符合默认入口要求。
- 默认已换成异步图，同一大仓库：视图打开约 7ms，HEAD 提交预览约 402ms，全 refs 图约 5.1 秒。后台加载期间编辑器可响应，`a` 可切到仅 HEAD，`q` 可退出并终止加载。
- 原生图作为 `:NeoNativeGraph` 保留，明确提示其同步行为。这是计划中允许且有实际证据的降级，图中 Enter、merge 父选择和 diff 联动仍可使用。

## 仍需真实任务确认

| 项目 | 当前边界 |
| --- | --- |
| 用户物理键盘/终端 | PTY/tmux 测试证明软件界面可运行，不能证明用户客户端能区分 Ctrl-Shift 等按键；默认使用稳定备用键 |
| 系统剪贴板 | provider 已配置；跨 SSH 的复制/读取取决于实际客户端，尚未人工确认 |
| NDAS 全量 C++ 语义 | clangd 在配置仓库和临时项目已连接；业务项目的真实编译数据库/容器路径未作修改或生成，尚未全量验收 |
| Agent 模型任务 | 两个 provider 握手和空会话通过，Claude 面板/选区/会话隔离通过；尚未发送付费模型任务，也未人工验证实际工具审批、拒绝和改动预览 |
| Agent 历史恢复 | 入口使用 provider 的原生恢复流程；不同 provider/CLI 的历史互通未承诺。历史会话不自动绑定到当前工作区；恢复后优先在其面板继续对话，新上下文入口使用受项目隔离的会话 |
| Python/TS/JSON/Lua 真实项目 | 二进制可发现、LSP 配置已接入；完整项目补全和环境识别仍需日常使用确认 |
| 完整 Git 冲突处理 | 已配置 Diffview 的冲突布局；尚未交互验收完整冲突解决流程 |
| UI 细节 | 未人工审查字体、OSC52 行为和所有窗口比例；可通过 `local.lua` 调整 |

常规 `:checkhealth` 会探测未启用的图片/PDF/LaTeX 等 Snacks 模块，在无图形终端报相关工具缺失；这些不是首版依赖，不为清空可选告警安装图片渲染工具。

## 重跑检查

从仓库根目录执行：

```sh
~/.local/bin/nvim-zed --headless '+luafile tests/neovim/smoke.lua'
python3 tests/neovim/lsp.py
python3 tests/neovim/git.py
python3 tests/neovim/runtime.py
python3 tests/neovim/acp.py
python3 tests/neovim/ui.py
python3 tests/neovim/tmux.py
sh -n scripts/install-neovim.sh scripts/install-neovim-tools.sh scripts/nvim-zed
git diff --check
```

Git/LSP 测试使用临时仓库或目录，不操作业务 index 或构建。ACP/界面检查会创建空 agent 会话、添加选区，但不发送 prompt。原生 `vim` 继续使用原配置。

安装、编译、初始插件和 parser 日志保存在本机 `~/.cache/neo-vim-install/`；包含宿主路径的原始日志不提交到仓库。
