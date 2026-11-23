"""Exercise the Git UI against disposable repositories, never a user's index."""
import os
from pathlib import Path
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parents[2]
EDITOR = Path.home() / '.local/bin/nvim-zed'

with tempfile.TemporaryDirectory(prefix='neo-vim git ') as directory:
    repo = Path(directory) / 'project'
    repo.mkdir()

    def git(*args):
        return subprocess.check_output(
            ['git', '-c', 'core.hooksPath=/dev/null', '-C', str(repo), *args],
            text=True, stderr=subprocess.DEVNULL,
        ).strip()

    git('init', '-b', 'main')
    git('config', 'user.name', 'Neovim Test')
    git('config', 'user.email', 'neovim-test@example.invalid')
    git('config', 'commit.gpgsign', 'false')
    text = ''.join(f'line {i}\n' for i in range(1, 41))
    (repo / 'main.txt').write_text(text)
    (repo / 'old.txt').write_text('rename me\n')
    git('add', '.')
    git('commit', '-qm', 'root')
    root_commit = git('rev-parse', 'HEAD')
    git('switch', '-qc', 'side')
    (repo / 'side.txt').write_text('side\n')
    git('add', '.')
    git('commit', '-qm', 'side')
    git('switch', '-q', 'main')
    (repo / 'other.txt').write_text('main\n')
    git('add', '.')
    git('commit', '-qm', 'main')
    git('merge', '--no-ff', '-m', 'merge side', 'side')
    (repo / 'main.txt').write_text(text.replace('line 2\n', 'staged change\n'))
    git('add', 'main.txt')
    (repo / 'main.txt').write_text((repo / 'main.txt').read_text()
                                 .replace('line 35\n', 'unstaged change\n')
                                 .replace('line 10\n', 'other unstaged change\n'))
    (repo / 'untracked.txt').write_text('new file\n')
    git('mv', 'old.txt', 'renamed.txt')
    (repo / 'other.txt').unlink()
    other = Path(directory) / 'other worktree'
    git('worktree', 'add', '--detach', str(other), root_commit)
    env = dict(os.environ, NEO_TEST_REPO=str(repo), NEO_TEST_WORKTREE=str(other), NEO_TEST_ROOT_COMMIT=root_commit)
    subprocess.run([str(EDITOR), '--headless', '+luafile tests/neovim/git.lua'], cwd=SOURCE, env=env, check=True)
