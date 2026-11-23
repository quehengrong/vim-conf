#!/bin/sh
set -eu
neo_repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
neo_cache="$HOME/.cache/neo-vim-install"
neo_node="$HOME/.local/opt/neo-vim-node-22.21.1"
neo_tools="$HOME/.local/share/nvim-zed/tools"
mkdir -p "$neo_cache" "$neo_tools"
if [ ! -x "$neo_node/bin/node" ]; then
  mkdir -p "$neo_node"
  curl -fL --retry 2 https://nodejs.org/dist/v22.21.1/node-v22.21.1-linux-x64.tar.xz -o "$neo_cache/node-v22.21.1.tar.xz"
  tar -xJf "$neo_cache/node-v22.21.1.tar.xz" --strip-components=1 -C "$neo_node"
fi
export PATH="$neo_node/bin:$PATH"
cp "$neo_repo/nvim/tools/package.json" "$neo_tools/package.json"
cp "$neo_repo/nvim/tools/package-lock.json" "$neo_tools/package-lock.json"
npm ci --prefix "$neo_tools" --no-audit --no-fund

neo_luals="$HOME/.local/opt/neo-vim-luals-3.19.2"
if [ ! -x "$neo_luals/bin/lua-language-server" ]; then
  mkdir -p "$neo_luals"
  curl -fL --retry 2 https://github.com/LuaLS/lua-language-server/releases/download/3.19.2/lua-language-server-3.19.2-linux-x64.tar.gz -o "$neo_cache/luals.tar.gz"
  tar -xzf "$neo_cache/luals.tar.gz" -C "$neo_luals"
fi

neo_tree="$HOME/.local/opt/tree-sitter-cli-0.26.1"
if ! "$neo_tree/bin/tree-sitter" --version >/dev/null 2>&1; then
  mkdir -p "$neo_tree/bin"
  curl -fL --retry 2 https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.1/tree-sitter-linux-x64.gz -o "$neo_cache/tree-sitter.gz"
  gzip -dc "$neo_cache/tree-sitter.gz" > "$neo_tree/bin/tree-sitter"
  chmod +x "$neo_tree/bin/tree-sitter"
  if ! "$neo_tree/bin/tree-sitter" --version >/dev/null 2>&1; then
    echo 'Tree-sitter binary incompatible. Building the pinned source using Rust.'
    export CARGO_HOME="$HOME/.local/opt/neo-vim-rust/cargo"
    export RUSTUP_HOME="$HOME/.local/opt/neo-vim-rust/rustup"
    export PATH="$CARGO_HOME/bin:$PATH"
    if [ ! -x "$CARGO_HOME/bin/cargo" ]; then
      curl -fL https://sh.rustup.rs -o "$neo_cache/rustup.sh"
      sh "$neo_cache/rustup.sh" -y --no-modify-path --profile minimal --default-toolchain 1.100.0
    fi
    if [ ! -d "$neo_cache/tree-sitter-src/.git" ]; then
      git clone --depth 1 --branch v0.26.1 https://github.com/tree-sitter/tree-sitter.git "$neo_cache/tree-sitter-src"
    fi
    rustup toolchain install 1.100.0 --profile minimal
    test "$(git -C "$neo_cache/tree-sitter-src" describe --tags --exact-match)" = v0.26.1
    cargo +1.100.0 install --path "$neo_cache/tree-sitter-src/crates/cli" --locked --root "$neo_tree" --force -j4
  fi
fi
"$HOME/.local/bin/nvim-zed" --headless '+lua require("nvim-treesitter").install({"c","cpp","python","lua","json","javascript","typescript","tsx","vim","vimdoc","bash","markdown","markdown_inline"}):wait(300000)' +qa
echo 'Tools installed. Run :NeoHealth in nvim-zed to inspect external tools.'
