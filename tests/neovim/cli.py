"""Check selection framing against real PTYs, without invoking a model."""
import os
from pathlib import Path
import subprocess
import tempfile

source = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='neo-vim-cli-') as directory:
    base = Path(directory)
    tools = base / 'bin'
    tools.mkdir()
    for tool in ('codex', 'claude'):
        executable = tools / tool
        executable.write_text('''#!/usr/bin/python3
import os
from pathlib import Path
import sys
import tty
tty.setraw(0)
os.write(1, b'\\x1b[?2004hREADY\\r\\n')
with open(Path.cwd() / (Path(sys.argv[0]).name + '.paste'), 'ab', buffering=0) as output:
    while True:
        data = os.read(0, 65536)
        if not data:
            break
        output.write(data)
''')
        executable.chmod(0o755)
    for name in ('project one', 'project two'):
        root = base / name
        root.mkdir()
        (root / 'CMakeLists.txt').write_text('project(selection_probe)\n')
        (root / 'sample with spaces.cpp').write_text('original disk content\n')
    subprocess.run(
        [str(Path.home() / '.local/bin/nvim-zed'), '--headless', '+luafile tests/neovim/cli.lua'],
        cwd=source, env=dict(os.environ, NEO_CLI_TEST_BASE=str(base)), check=True, timeout=20,
    )
