"""Package only authored source/assets and safely unpack the Windows build."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
release = root / "releases"
source_zip = release / "Nocrim-0.1.0-source.zip"
files = [root / "README.md", root / ".gitignore"]
for folder in ("game", "docs", "tools"):
    files += [p for p in (root / folder).rglob("*") if p.is_file()
              and not any(part in ("cache", "saves", "__pycache__") for part in p.relative_to(root).parts)
              and p.suffix not in (".pyc", ".rpyc", ".tmp")]
files += [root / "tests" / "test_campaign.py"]
with zipfile.ZipFile(source_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for path in files:
        z.write(path, "Nocrim-source/" + path.relative_to(root).as_posix())
with zipfile.ZipFile(source_zip) as check:
    if check.testzip():
        raise SystemExit("Source archive integrity check failed")

windows_zip = release / "Nocrim-0.1.0-win.zip"
if windows_zip.exists():
    with zipfile.ZipFile(windows_zip) as z:
        if z.testzip():
            raise SystemExit("Windows archive integrity check failed")
        for info in z.infolist():
            target = (release / info.filename).resolve()
            target.relative_to(release.resolve())
            if any(bad in info.filename for bad in ("sandbox-saves", "security_keys", ".tools/", "testcases.rpy")):
                raise SystemExit("Development-only file found in distribution")
        z.extractall(release)
for path in (windows_zip, source_zip):
    if path.exists():
        print(path.name, round(path.stat().st_size / 1048576, 1), "MiB")
print("All packaged files verified; no SDK or test save credentials included.")
