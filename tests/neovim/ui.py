"""Real terminal smoke check. Captures escape sequences instead of printing them."""
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import tempfile
import termios
import time

source = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='neo-vim-ui-') as directory:
    report = Path(directory) / 'report.json'
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 45, 150, 0, 0))
    env = dict(os.environ, TERM='xterm-256color', COLORTERM='truecolor', NEO_UI_REPORT=str(report))
    process = subprocess.Popen([str(Path.home() / '.local/bin/nvim-zed'), 'tests/neovim/structure.cpp',
                                '+luafile tests/neovim/ui.lua'], cwd=source, env=env,
                               stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
    os.close(slave)
    deadline = time.monotonic() + 30
    try:
        while time.monotonic() < deadline and process.poll() is None:
            if select.select([master], [], [], 0.2)[0]:
                try:
                    os.read(master, 65536)
                except OSError as exc:
                    if exc.errno != errno.EIO:
                        raise
        assert process.poll() is not None, 'UI probe timed out'
        data = json.loads(report.read_text())
        assert data['ok'] and data['dracula'], data
        assert all(data['checks'].values()), data
        assert not data['errors'], data['errors']
        print('PASS UI:', ', '.join(data['checks']))
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=5)
        os.close(master)
