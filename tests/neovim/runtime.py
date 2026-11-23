import os
from pathlib import Path
import subprocess
import tempfile

editor = str(Path.home() / '.local/bin/nvim-zed')
with tempfile.TemporaryDirectory(prefix='neo-vim-runtime-') as directory:
    path = Path(directory) / 'undo.txt'
    path.write_text('original\n')
    env = dict(os.environ, NEO_TEST_FILE=str(path))

    def run(lua):
        result = subprocess.run([editor, '--headless', '+lua vim.cmd.edit(vim.env.NEO_TEST_FILE)',
                                 '+lua ' + lua, '+qa!'], env=env, capture_output=True, text=True)
        assert result.returncode == 0 and 'Error' not in result.stderr, result.stderr

    run("vim.cmd.normal({args={'A changed' .. string.char(27)},bang=true}); vim.cmd.write()")
    assert path.read_text() == 'original changed\n'
    run("vim.cmd.undo(); assert(vim.api.nvim_get_current_line()=='original', 'Persistent undo failed')")
    run("vim.api.nvim_set_current_line('unsaved'); vim.fn.writefile({'external'},vim.env.NEO_TEST_FILE); "
        "vim.cmd.checktime(); assert(vim.api.nvim_get_current_line()=='unsaved', 'Overwrote unsaved buffer')")
    print('PASS runtime: undo across restart; unsaved buffer survives external modification')
