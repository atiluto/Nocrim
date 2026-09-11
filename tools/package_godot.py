"""Package a standalone Windows build and clean, portable Godot project."""
from pathlib import Path
import hashlib, shutil, zipfile

ROOT = Path(__file__).resolve().parents[1]
release = ROOT/'releases/Nocrim-Godot-0.2.0-win'
assert (release/'Nocrim.exe').is_file() and (release/'Nocrim.pck').is_file()
for folder in ['assets/characters/expressions','assets/audio/bgm','assets/audio/sfx']:
    (release/folder).mkdir(parents=True,exist_ok=True)
docs = ['GODOT_PLAY_GUIDE.md','GODOT_AUDIO.md','GODOT_REFERENCE_APPLIED.md','GODOT_VALIDATION.md','GODOT_ASSETS.md','GODOT-LICENSE.txt','FONT-LICENSE.txt','DEJAVU-LICENSE.txt']
for name in docs:
    if (ROOT/'docs'/name).is_file(): shutil.copy2(ROOT/'docs'/name,release/name)
(release/'실행안내.txt').write_text('녹림전생 · Godot 0.2.0\n\n압축을 모두 푼 뒤 Nocrim.exe를 실행하세요.\nNocrim.pck는 실행 파일과 같은 폴더에 있어야 합니다.\n\n자세한 조작법: GODOT_PLAY_GUIDE.md\n음원 파일명과 프롬프트: GODOT_AUDIO.md\n구현·검증 범위: GODOT_VALIDATION.md\n\nRen’Py판 저장 파일과 호환되지 않습니다.\n',encoding='utf-8-sig')
(release/'assets/여기에_에셋을_넣으세요.txt').write_text('characters: {id}_idle.png, {id}_portrait.png 및 동작·표정 파일\naudio/bgm: *_theme.mp3\naudio/sfx: *.wav\n\n파일 목록은 GODOT_PLAY_GUIDE.md, GODOT_AUDIO.md를 참고하세요.\n기본 PNG 이름을 사용하며 _alpha 접미사는 쓰지 않습니다.\n교체한 다음 게임을 다시 실행하세요.\n',encoding='utf-8-sig')
win_zip = ROOT/'releases/Nocrim-Godot-0.2.0-win.zip'
with zipfile.ZipFile(win_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
    for p in sorted(release.rglob('*')):
        if p.is_file(): z.write(p,Path(release.name)/p.relative_to(release))
source_zip = ROOT/'releases/Nocrim-Godot-0.2.0-source.zip'
with zipfile.ZipFile(source_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
    for p in sorted((ROOT/'godot').rglob('*')):
        if not p.is_file() or '.godot' in p.parts: continue
        arc=Path('Nocrim-Godot-source')/p.relative_to(ROOT)
        if p.name=='export_presets.cfg':
            text=p.read_text(encoding='utf-8')
            for mode in ['debug','release']:
                text=text.replace(f'custom_template/{mode}="../.tools/godot/templates/windows_{mode}_x86_64.exe"',f'custom_template/{mode}=""')
            z.writestr(str(arc),text)
        else: z.write(p,arc)
    for name in docs:
        p=ROOT/'docs'/name
        if p.is_file(): z.write(p,Path('Nocrim-Godot-source/docs')/name)
    for p in [ROOT/'README.md',ROOT/'docs/GODOT_DEVELOPMENT.md',ROOT/'tools/bootstrap_godot.py',ROOT/'tools/godot_task.py',ROOT/'tools/package_godot.py']:
        if p.is_file(): z.write(p,Path('Nocrim-Godot-source')/p.relative_to(ROOT))
for p in [win_zip,source_zip]:
    print(p.name,round(p.stat().st_size/1048576,2),'MiB',hashlib.sha256(p.read_bytes()).hexdigest())
