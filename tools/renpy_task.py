"""Run this project's pinned SDK with isolated test saves inside the workspace."""
from pathlib import Path
import os
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
sdk = root / ".tools" / "renpy-8.5.3-sdk"
env = os.environ.copy()
env["RENPY_PATH_TO_SAVES"] = str(root / "tests" / "sandbox-saves")
env["PYTHONIOENCODING"] = "utf-8"
command = [str(sdk / "lib" / "py3-windows-x86_64" / "python.exe"), str(sdk / "renpy.py")]
if sys.argv[1:2] == ["distribute"]:
    command += [str(sdk / "launcher"), "distribute", str(root), "--destination", str(root / "releases"), "--package", "win"] + sys.argv[2:]
else:
    command += [str(root)] + (sys.argv[1:] or ["run"])
raise SystemExit(subprocess.call(command, cwd=root, env=env))
