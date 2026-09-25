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

## Attention plugin examples

Mark the current pane as waiting:

```bash
zellij pipe --name "zellij-attention::waiting::$ZELLIJ_PANE_ID"
```

Mark the current pane as completed:

```bash
zellij pipe --name "zellij-attention::completed::$ZELLIJ_PANE_ID"
```
