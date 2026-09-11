from pathlib import Path
import json, urllib.request, struct, sys
root = Path(__file__).resolve().parents[1]
retry = '--alpha-candidates' in sys.argv
manifest = 'HIGGSFIELD_ALPHA_ATTEMPT.json' if retry else 'HIGGSFIELD_ASSETS.json'
folder = root/'art-source/alpha-candidates' if retry else root/'godot/assets/characters'
folder.mkdir(parents=True, exist_ok=True)
for item in json.loads((root/'docs'/manifest).read_text(encoding='utf-8')):
    dest = folder/(item['id'] + '_idle.png')
    if not dest.exists(): urllib.request.urlretrieve(item['url'], dest)
    raw = dest.read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n'
    w,h,depth,color = struct.unpack('>IIBB',raw[16:26])
    print(item['id'], w, h, 'PNG color type',color)
