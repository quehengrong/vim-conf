import json
import os
from pathlib import Path
import subprocess
import tempfile

source = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='neo-vim-lsp-') as directory:
    root = Path(directory)
    (root / 'main.cpp').write_text('int add(int a, int b) { return a + b; }\nint main() { return add(1, 2); }\n')
    (root / 'compile_commands.json').write_text(json.dumps([
        {'directory': directory, 'file': str(root / 'main.cpp'),
         'arguments': ['clang++', '-std=c++17', '-c', str(root / 'main.cpp')]}
    ]))
    subprocess.run([str(Path.home() / '.local/bin/nvim-zed'), '--headless', '+luafile tests/neovim/lsp.lua'],
                   cwd=source, env=dict(os.environ, NEO_TEST_LSP=directory), check=True)
