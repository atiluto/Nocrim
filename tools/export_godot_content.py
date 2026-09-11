"""One-time content migration; the shipped Godot game requires no Python."""
from pathlib import Path
import sys, json, shutil, re
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'game/python-packages'))
from nocrim.world import REGIONS, PEOPLE, EVENTS, ENDINGS
dest = ROOT / 'godot'
for folder in ['data', 'scripts', 'tests', 'assets/characters/expressions', 'assets/backgrounds', 'assets/fonts', 'assets/audio/bgm', 'assets/audio/sfx']:
    (dest/folder).mkdir(parents=True, exist_ok=True)
(dest/'data/world.json').write_text(json.dumps(dict(regions=REGIONS, people=PEOPLE, events=EVENTS, endings=ENDINGS), ensure_ascii=False, indent=2), encoding='utf-8')
shutil.copy2(ROOT/'game/images/mountains.png', dest/'assets/backgrounds/mountains.png')
shutil.copy2(ROOT/'game/images/cast.png', dest/'assets/characters/cast.png')
shutil.copy2(ROOT/'game/fonts/SourceHanSansLite.ttf', dest/'assets/fonts/SourceHanSansLite.ttf')
shutil.copy2(ROOT/'.tools/renpy-8.5.3-sdk/renpy/common/DejaVuSans.ttf', dest/'assets/fonts/DejaVuSans.ttf')
print('Migrated', len(REGIONS), 'regions,', len(PEOPLE), 'people,', len(EVENTS), 'events.')
