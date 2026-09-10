from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parents[1]
game = root / "releases" / "Nocrim-0.1.0-win"
env = os.environ.copy()
env["RENPY_PATH_TO_SAVES"] = str(root / "tests" / "release-saves")
result = subprocess.run([str(game / "Nocrim.exe"), str(game), "quit"],
                        cwd=game, env=env, capture_output=True, timeout=30)
if result.returncode:
    print(result.stdout.decode("utf-8", errors="replace"))
    print(result.stderr.decode("utf-8", errors="replace"))
    raise SystemExit(result.returncode)
for path in ("game/images/cast.png", "game/images/mountains.png", "game/fonts/SourceHanSansLite.ttf",
             "game/python-packages/nocrim/engine.py", "docs/FONT-LICENSE.txt"):
    if not (game / path).is_file():
        raise SystemExit("Missing required file: " + path)
print("Packaged Nocrim.exe initialized and exited successfully using only its bundled runtime.")
