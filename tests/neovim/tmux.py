"""Use a separate tmux server; never attach to or alter a user's sessions."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time

source = Path(__file__).resolve().parents[2]
socket = 'neo-vim-test-' + str(os.getpid())
tmux = ['tmux', '-L', socket, '-f', '/dev/null']
with tempfile.TemporaryDirectory(prefix='neo-vim-tmux-') as directory:
    report = Path(directory) / 'report.json'
    command = shlex.join(['env', 'NEO_UI_REPORT=' + str(report), str(Path.home() / '.local/bin/nvim-zed'),
                          'tests/neovim/structure.cpp', '+luafile tests/neovim/ui.lua'])
    try:
        subprocess.run(tmux + ['new-session', '-d', '-s', 'validation', '-x', '150', '-y', '45',
                               '-c', str(source), command], check=True)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline and not report.exists():
            time.sleep(0.1)
        assert report.exists(), 'tmux UI probe timed out'
        data = json.loads(report.read_text())
        assert data['ok'] and data['dracula'] and all(data['checks'].values()) and not data['errors'], data
        print('PASS tmux UI:', ', '.join(data['checks']))
    finally:
        subprocess.run(tmux + ['kill-server'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
