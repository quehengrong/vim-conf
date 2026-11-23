#!/bin/sh
# Installs the isolated editor. Never overwrites an existing unrelated path.
set -eu
neo_repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
neo_prefix="$HOME/.local"
neo_cache="$HOME/.cache/neo-vim-install"
neo_target="$neo_prefix/opt/nvim-0.12.6"
mkdir -p "$neo_cache" "$neo_prefix/bin" "${XDG_CONFIG_HOME:-$HOME/.config}"

safe_link() {
  if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then return; fi
  if [ -e "$2" ] || [ -L "$2" ]; then
    echo "Refusing to replace existing path: $2. Back it up and retry." >&2
    exit 1
  fi
  ln -s "$1" "$2"
}

# Preflight before installing or changing links.
for neo_dest in "${XDG_CONFIG_HOME:-$HOME/.config}/nvim-zed" "$neo_prefix/bin/nvim-zed"; do
  if [ -e "$neo_dest" ] && [ ! -L "$neo_dest" ]; then
    echo "Existing path requires a backup: $neo_dest" >&2
    exit 1
  fi
done

if ! "$neo_target/bin/nvim" --version >/dev/null 2>&1; then
  case "$(uname -sm)" in
    'Linux x86_64') ;;
    *) echo 'This installer currently supports Linux x86_64 only.' >&2; exit 1 ;;
  esac
  mkdir -p "$neo_target"
  curl -fL --retry 2 https://github.com/neovim/neovim/releases/download/v0.12.6/nvim-linux-x86_64.tar.gz -o "$neo_cache/nvim-v0.12.6.tar.gz"
  tar -xzf "$neo_cache/nvim-v0.12.6.tar.gz" --strip-components=1 -C "$neo_target"
  if ! "$neo_target/bin/nvim" --version >/dev/null 2>&1; then
    echo 'Prebuilt binary is incompatible. Building v0.12.6 for this host.'
    if [ ! -d "$neo_cache/neovim-src/.git" ]; then
      git clone --depth 1 --branch v0.12.6 https://github.com/neovim/neovim.git "$neo_cache/neovim-src"
    fi
    test "$(git -C "$neo_cache/neovim-src" describe --tags --exact-match)" = v0.12.6
    make -C "$neo_cache/neovim-src" CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$neo_target" CMAKE_EXTRA_FLAGS=-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -j4
    make -C "$neo_cache/neovim-src" install
  fi
fi

safe_link "$neo_repo/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim-zed"
safe_link "$neo_repo/scripts/nvim-zed" "$neo_prefix/bin/nvim-zed"
neo_lazy="$neo_prefix/share/nvim-zed/lazy/lazy.nvim"
if [ ! -d "$neo_lazy/.git" ]; then
  git clone --filter=blob:none --branch stable https://github.com/folke/lazy.nvim.git "$neo_lazy"
fi
"$neo_prefix/bin/nvim-zed" --headless '+lua require("lazy").install({wait=true,lockfile=true})' '+Lazy! restore' +qa
echo 'Installed isolated editor. Start with: ~/.local/bin/nvim-zed'
echo 'Install language/ACP tools and parsers as described in docs/neovim/INSTALL.md.'
