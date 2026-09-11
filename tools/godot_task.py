"""Run Godot with editor caches, logs, and test saves contained in this project."""
from pathlib import Path
import os, subprocess, sys
root = Path(__file__).resolve().parents[1]
runtime = root/'.tools/godot'
(runtime/'_sc_').touch()
env = os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    path = root/'tests/godot-runtime'/key.lower()
    path.mkdir(parents=True, exist_ok=True)
    env[key] = str(path)
saves = root/'tests/godot-saves'
saves.mkdir(parents=True, exist_ok=True)
args = sys.argv[1:]
exe = runtime/'Godot_v4.7.2-stable_win64_console.exe'
command = [str(exe),'--log-file',str(root/'tests/godot-run.log'),
           '--path',str(root/'godot')]
if '--' in args:
    i=args.index('--'); command += args[:i]+['--','--save-root='+saves.as_posix()]+args[i+1:]
else: command += args+['--','--save-root='+saves.as_posix()]
raise SystemExit(subprocess.call(command, env=env, cwd=root))
