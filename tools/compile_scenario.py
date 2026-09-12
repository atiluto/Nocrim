"""Compile the editable prologue Markdown. Never runs automatically on game launch."""
from pathlib import Path
import json, re, argparse, textwrap

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'scenario'
OUTPUT = ROOT / 'godot/data/prologue.json'

def compile_data():
    manifest = json.loads((BASE/'manifest.json').read_text(encoding='utf-8'))
    presentation = json.loads((BASE/'presentation.json').read_text(encoding='utf-8'))
    scene_cards = presentation.get('scene_cards',{})
    beats, chapters, ids, runtime_ids = [], [], set(), set()
    for filename in manifest['chapters']:
        path = BASE / filename
        text = path.read_text(encoding='utf-8')
        title = text.splitlines()[0].removeprefix('# ')
        chapter_id = path.stem.split('_')[0]
        chapters.append({'id':chapter_id,'title':title,'start':len(beats),'file':filename})
        memory_mode = False
        for match in re.finditer(r'^### ([A-Z0-9-]+)\n(.*?)(?=^### |\Z)', text, re.M|re.S):
            identity, body = match.groups()
            if identity in ids: raise ValueError('Duplicate beat '+identity)
            ids.add(identity)
            meta, line = body.split('\n대사:\n',1)
            fields = dict(re.findall(r'^([^:\n]+): *(.*)$',meta,re.M))
            memory_value = fields.get('회상','').strip().lower()
            if memory_value=='on': memory_mode = True
            elif memory_value=='off': memory_mode = False
            elif memory_value: raise ValueError('Memory must be on or off: '+identity)
            beat = {'id':identity,'chapter':chapter_id,'title':title,'text':line.strip()}
            for key, source in [('speaker','화자'),('background','배경'),('sprite','인물'),('side','위치'),('music','음악'),('ambience','환경음'),('sfx','효과음'),('effect','연출'),('transition','장면')]:
                beat[key] = fields.get(source,'')
            beat['transition'] = scene_cards.get(identity,beat['transition'])
            if chapter_id=='P01':
                beat['background']={'room':'modern_room','road':'modern_forest','rain':'modern_rain'}.get(beat['background'],beat['background'])
            else:
                beat['background']={'road':'forest_path','hut':'solbaram_den','village':'village_overcast','stockade':'maegol_stockade','camp':'solbaram_night'}.get(beat['background'],beat['background'])
            if beat['sprite']=='extra':
                if chapter_id=='P04': beat['sprite']='npc_villager'
                elif chapter_id in ['P06','P08'] and beat['speaker']!='추격자': beat['sprite']='npc_captive'
                elif chapter_id=='P05' or beat['speaker'] in ['조만식','추격자']: beat['sprite']='npc_bandit_brute'
                else: beat['sprite']='npc_bandit_scout'
            beat['memory'] = memory_mode
            if not beat['text']: raise ValueError('Empty dialogue '+identity)
            if beat['side'] not in ['left','right']: raise ValueError('Invalid side '+identity)
            if beat['effect'] not in ['','fade','fadein','jump','shake','flash','blackout','walk']: raise ValueError('Invalid effect '+identity)
            if beat['sprite'] not in ['', 'mawung', 'npc_bandit_scout', 'npc_bandit_brute', 'npc_villager', 'npc_captive']: raise ValueError('Unknown sprite '+identity)
            if beat['background'] not in ['black','modern_room','modern_forest','modern_rain','forest_path','solbaram_den','village_overcast','maegol_stockade','solbaram_night']: raise ValueError('Unknown background '+identity)
            if beat['sprite'] and not (ROOT/'godot/assets/prologue'/(beat['sprite']+'.png')).is_file(): raise ValueError('Missing sprite '+identity)
            if beat['background']!='black' and not (ROOT/'godot/assets/prologue'/(beat['background']+'.png')).is_file(): raise ValueError('Missing background '+identity)
            for key in ['music','ambience','sfx']:
                if beat[key] and not (ROOT/'godot/assets/audio'/beat[key]).is_file(): raise ValueError('Missing audio '+beat[key])
            # Let authors write naturally. Game data is paginated without rewriting Markdown.
            wrapped = []
            for source_line in beat['text'].splitlines():
                wrapped.extend(textwrap.wrap(source_line, width=28, break_long_words=True,
                                             break_on_hyphens=False) or [''])
            pages = ['\n'.join(wrapped[i:i+2]) for i in range(0,len(wrapped),2)]
            for page_index, page in enumerate(pages):
                page_beat = beat.copy()
                page_beat['id'] = identity if page_index==0 else identity+'-PAGE%02d' % (page_index+1)
                page_beat['text'] = page
                if page_index>0:
                    page_beat['sfx'] = ''
                    page_beat['effect'] = ''
                if page_beat['id'] in runtime_ids: raise ValueError('Generated page ID collision '+page_beat['id'])
                runtime_ids.add(page_beat['id'])
                beats.append(page_beat)
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
