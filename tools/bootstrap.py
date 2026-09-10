"""Download the official, checksum-verified Ren'Py SDK into this workspace."""
from pathlib import Path
import hashlib
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "8.5.3"
archive = ROOT / ".tools" / "renpy-sdk.zip"
sdk = ROOT / ".tools" / ("renpy-" + VERSION + "-sdk")
if not sdk.exists():
    archive.parent.mkdir(exist_ok=True)
    if not archive.exists():
        print("Downloading official Ren'Py SDK...", flush=True)
        urllib.request.urlretrieve("https://www.renpy.org/dl/8.5.3/renpy-8.5.3-sdk.zip", archive)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest != "ff57648f9c04f27e381c48af6d8e3ee3cdec296bed4d3831f47f09b0a71b505e":
        raise SystemExit("SDK checksum mismatch; archive was not extracted.")
    with zipfile.ZipFile(archive) as z:
        for item in z.infolist():
            target = (archive.parent / item.filename).resolve()
            target.relative_to(archive.parent.resolve())
        z.extractall(archive.parent)
print(str(sdk), flush=True)
