"""Fetch official Godot binaries and only extract Windows export templates locally."""
from pathlib import Path
import hashlib, json, urllib.request, zipfile

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / '.tools' / 'godot'
VERSION = '4.7.2-stable'
DEST.mkdir(parents=True, exist_ok=True)
req = urllib.request.Request('https://api.github.com/repos/godotengine/godot-builds/releases/tags/' + VERSION, headers={'User-Agent': 'Nocrim-build'})
release = json.load(urllib.request.urlopen(req, timeout=60))
assets = {a['name']: a for a in release['assets']}
for suffix in ['win64.exe.zip', 'export_templates.tpz']:
    name = 'Godot_v' + VERSION + '_' + suffix
    asset = assets[name]
    archive = DEST / name
    if not archive.exists():
        print('Downloading ' + name, flush=True)
        urllib.request.urlretrieve(asset['browser_download_url'], archive)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    expected = asset.get('digest', '')
    if not expected:
        checks = urllib.request.urlopen(assets['SHA512-SUMS.txt']['browser_download_url']).read().decode()
        expected512 = next(line.split()[0] for line in checks.splitlines() if name in line)
        assert hashlib.sha512(archive.read_bytes()).hexdigest() == expected512
    else:
        assert expected == 'sha256:' + digest, 'Official checksum mismatch'
    with zipfile.ZipFile(archive) as z:
        for member in z.namelist():
            if suffix == 'export_templates.tpz' and Path(member).name not in ('windows_release_x86_64.exe', 'windows_debug_x86_64.exe'):
                continue
            target = (DEST / member).resolve()
            target.relative_to(DEST.resolve())
            z.extract(member, DEST)
    print(name + ' verified: ' + digest, flush=True)
