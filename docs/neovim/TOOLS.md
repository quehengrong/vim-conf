# 工具与兼容集合

验证日期：2026-11-23。机器为 Linux x86_64 / Ubuntu 20.04，glibc 2.31。机器可读清单见 [tools-lock.json](../../nvim/tools-lock.json)。

| 组件 | 本机版本 / 处理 |
| --- | --- |
| Neovim | 0.12.6，在用户目录从 v0.12.6 源码编译 |
| 主题 | 默认 Catppuccin Mocha，保留 Dracula；插件确切提交见 lazy-lock.json |
| 插件 | 22 个，确切提交见 [lazy-lock.json](../../nvim/lazy-lock.json) |
| 代码阅读辅助 | nvim-treesitter-context、aerial.nvim，使用现有 parser/LSP 并跟随主题 |
| Tree-sitter CLI | 0.26.1，从对应 tag 的 crates/cli 编译 |
| Rust | 1.100.0，隔离工具链，仅用于 CLI 构建 |
| parser | C/C++、Python、Lua、JSON、JS/TS/TSX、Vim/Vimdoc、Bash、Markdown；确切源提交见 [parsers-lock.json](../../nvim/parsers-lock.json) |
| Node | 独立 v22.21.1；未改变 `/usr/local/bin/node` 的 v20.11.1 |
| Claude ACP | `@agentclientprotocol/claude-agent-acp` 0.109.1 |
| Codex ACP | `@agentclientprotocol/codex-acp` 2.10.0 |
| TypeScript language server | 5.0.0，配 TypeScript 5.9.3 |
| JSON 等语言服务 | vscode-langservers-extracted 4.10.0 |
| LuaLS | 3.19.2，独立用户目录 |
| clangd | 复用已有 23.1.0 |
| Pyright | 复用已有 1.1.408 |
| Lazygit | 复用已有 commit 24c3b7da，2026-10-27 构建 |
| Git / tmux | 2.47.1 / 3.0a |

两个官方预编译包（Neovim、Tree-sitter CLI）都要求更高 glibc，已使用源码构建解决，未修改系统库。Blink 使用 Lua 模糊匹配实现，启动时不下载 Rust 动态库。

安装时发现旧命名空间 `@zed-industries/codex-acp` 已弃用，因此使用其后续 `@agentclientprotocol/codex-acp`。TypeScript language server 6.1.0 要求 Node >=22.22.2，本配置选择兼容 Node 22.21.1 的 5.0.0，避免引入引擎版本不匹配。最终 npm 安装没有 engine warning，完整传递依赖由 [package-lock.json](../../nvim/tools/package-lock.json) 锁定。

Agentic 的项目隔离包装使用锁定版本的 session registry API，并有终端/tmux 回归测试。升级 Agentic 后，应首先重跑 `ui.py` 和 `tmux.py`，确认上下文与会话不会跨项目复用。

锁文件的职责不同：插件锁管理插件源码，parser 清单管理实际 parser 源提交，npm 锁管理 Node 工具依赖；工具清单记录宿主二进制版本。复现还依赖兼容系统、编译器、CLI 认证和项目编译数据库。

参考：[Neovim 发布](https://github.com/neovim/neovim/releases/tag/v0.12.6)、[Tree-sitter 分支/API 说明](https://github.com/nvim-treesitter/nvim-treesitter)、[Agentic](https://github.com/carlos-algms/agentic.nvim)。
