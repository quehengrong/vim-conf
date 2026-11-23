"""Probe real ACP processes without sending model prompts or printing secrets."""
import json
import os
from pathlib import Path
import selectors
import signal
import subprocess
import tempfile
import time

prefix = Path.home() / '.local'
env = dict(os.environ)
env['PATH'] = f"{prefix}/opt/neo-vim-node-22.21.1/bin:{prefix}/share/nvim-zed/tools/node_modules/.bin:" + env['PATH']
for provider in ['claude-agent-acp', 'codex-acp']:
    with tempfile.TemporaryDirectory(prefix='neo-vim-acp-') as directory, tempfile.TemporaryFile() as errors:
        process = subprocess.Popen([provider], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=errors, env=env, cwd=directory, start_new_session=True)
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)

        def request(request_id, method, params):
            process.stdin.write((json.dumps({'jsonrpc': '2.0', 'id': request_id, 'method': method, 'params': params}) + '\n').encode())
            process.stdin.flush()
            deadline = time.monotonic() + 25
            while time.monotonic() < deadline:
                for key, _ in selector.select(timeout=1):
                    line = key.fileobj.readline()
                    if not line:
                        raise RuntimeError(f'{provider} exited: {process.poll()}')
                    value = json.loads(line)
                    if value.get('id') == request_id:
                        return value
            raise TimeoutError(f'{provider}: {method} timed out')

        try:
            result = request(1, 'initialize', {'protocolVersion': 1, 'clientCapabilities': {},
                                             'clientInfo': {'name': 'neo-vim-validation', 'version': '1'}})
            assert 'result' in result, f'{provider}: initialization failed'
            print(provider + ': initialize PASS', flush=True)
            result = request(2, 'session/new', {'cwd': directory, 'mcpServers': []})
            if 'result' in result and result['result'].get('sessionId'):
                print(provider + ': empty session PASS (no model prompt sent)', flush=True)
            else:
                error = result.get('error', {})
                # Only report the code: free-form provider errors may contain private paths.
                print(provider + ': session unavailable, error code ' + str(error.get('code')), flush=True)
        finally:
            selector.close()
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
