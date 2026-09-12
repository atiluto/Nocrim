"""Compile the editable prologue Markdown. Never runs automatically on game launch."""
from pathlib import Path
import json, re, argparse, hashlib

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'scenario'
OUTPUT = ROOT / 'godot/data/prologue.json'

def compile_data():
    manifest = json.loads((BASE/'manifest.json').read_text(encoding='utf-8'))
    beats, chapters, ids = [], [], set()
    for filename in manifest['chapters']:
        path = BASE / filename
        text = path.read_text(encoding='utf-8')
        title = text.splitlines()[0].removeprefix('# ')
        chapter_id = path.stem.split('_')[0]
        chapters.append({'id':chapter_id,'title':title,'start':len(beats),'file':filename})
        for match in re.finditer(r'^### ([A-Z0-9-]+)\n(.*?)(?=^### |\Z)', text, re.M|re.S):
            identity, body = match.groups()
            if identity in ids: raise ValueError('Duplicate beat '+identity)
            ids.add(identity)
            meta, line = body.split('\n대사:\n',1)
            fields = dict(re.findall(r'^([^:\n]+): *(.*)$',meta,re.M))
            beat = {'id':identity,'chapter':chapter_id,'title':title,'text':line.strip()}
            for key, source in [('speaker','화자'),('background','배경'),('sprite','인물'),('side','위치'),('music','음악'),('ambience','환경음'),('sfx','효과음'),('effect','연출')]:
                beat[key] = fields.get(source,'')
            if not beat['text']: raise ValueError('Empty dialogue '+identity)
            # Conservative fit at the largest dialogue font (28px), including explicit newlines.
            if len(beat['text'].splitlines())>2 or any(len(line)>28 for line in beat['text'].splitlines()):
                raise ValueError('Keep dialogue within two lines of 28 characters: '+identity)
            if beat['side'] not in ['left','right']: raise ValueError('Invalid side '+identity)
            if beat['effect'] not in ['','fade','jump','shake','flash','blackout','walk']: raise ValueError('Invalid effect '+identity)
            if beat['sprite'] not in ['', 'extra', 'mawung']: raise ValueError('Unknown sprite '+identity)
            if beat['background'] not in ['room','rain','village','hut','stockade','road','camp']: raise ValueError('Unknown background '+identity)
            if beat['sprite'] and not (ROOT/'godot/assets/prologue'/(beat['sprite']+'.png')).is_file(): raise ValueError('Missing sprite '+identity)
            if beat['background'] not in ['road','camp'] and not (ROOT/'godot/assets/prologue'/(beat['background']+'.png')).is_file(): raise ValueError('Missing background '+identity)
            for key in ['music','ambience','sfx']:
                if beat[key] and not (ROOT/'godot/assets/audio'/beat[key]).is_file(): raise ValueError('Missing audio '+beat[key])
            beats.append(beat)
    if not beats: raise ValueError('No beats')
    if len(chapters)!=11: raise ValueError('Prologue must have 11 scenes')
    return {'version':1,'pagination_revision':2,'previous_beat_ids':manifest.get('previous_beat_ids',[]),'source':'scenario/manifest.json','chapters':chapters,'beats':beats}

if __name__=='__main__':
    args=argparse.ArgumentParser(); args.add_argument('--check',action='store_true'); ns=args.parse_args()
    result=compile_data()
    serialized=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
    if ns.check:
        assert OUTPUT.read_text(encoding='utf-8')==serialized,'Compiled data is stale'
    else:
        OUTPUT.write_text(serialized,encoding='utf-8')
    print(f"{len(result['chapters'])} chapters, {len(result['beats'])} beats: {'checked' if ns.check else 'compiled'}")
