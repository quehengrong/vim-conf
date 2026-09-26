# Zellij config

This folder stores the Zellij configuration used on this machine.

## Contents

- `config.kdl`: main Zellij config.
- `layouts/zjstatus.kdl`: default layout using `zjstatus`.
- `themes/`: theme files copied from Zellij assets, with `flexoki-dark` enabled.
- `plugins/`: local wasm plugins used by the config.

## Install

```bash
mkdir -p ~/.config/zellij
cp -r zellij/config.kdl zellij/layouts zellij/themes zellij/plugins ~/.config/zellij/
zellij setup --check
```

Start a new session to load layout/theme/plugin changes:

```bash
zellij
```

## Plugin shortcuts

- `Alt r`: open `room` for quick tab search/switching.
- `Alt y`: open `zellij-forgot` for keybinding help.
- `zjstatus`: loaded by the default `zjstatus` layout.
- `zellij-attention`: loaded in the background by `load_plugins`.
- `zellij-autolock`: loaded in the background by `load_plugins`.

## Autolock (vim -> Locked mode)

`zellij-autolock` (https://github.com/fresh2dev/zellij-autolock) watches the
command running in the focused pane and switches Zellij to `Locked` mode while
`triggers` is running, then back to `Normal` when it exits. Inside `vim` this is
the equivalent of Zellij pressing `Ctrl g` automatically, so vim (and not Zellij)
receives every key.

```kdl
plugins {
    autolock location="file:~/.config/zellij/plugins/zellij-autolock.wasm" {
        is_enabled true
        triggers "vim|nvim|vi|vim.basic|vim.gtk3"
        print_to_log true
    }
}
load_plugins {
    autolock
}
```

Notes:

- In WSL/Ubuntu the running vim is reported by Zellij as `vi` (not `vim`), hence
  the extra entries in `triggers`. Add more commands (e.g. `lazygit|fzf|htop`) as
  needed; matching is on the executable name (first word of the command), not a
  substring of the whole command line.
- `sudo vim` is not detected, because the first word is then `sudo`.
- `print_to_log true` writes `[autolock] Detected command: ...` lines to
  `/tmp/zellij-$(id -u)/zellij-log/zellij.log`, which is handy for tuning the
  trigger list.
- Zellij asks for the plugin permissions (`ReadApplicationState`,
  `ChangeApplicationState`) once; the grant is cached in `~/.cache/zellij/permissions.kdl`.
- The plugin only takes effect in a newly started session (or after
  `zellij setup --check` + restart).

## Attention plugin examples

Mark the current pane as waiting:

```bash
zellij pipe --name "zellij-attention::waiting::$ZELLIJ_PANE_ID"
```

Mark the current pane as completed:

```bash
zellij pipe --name "zellij-attention::completed::$ZELLIJ_PANE_ID"
```
