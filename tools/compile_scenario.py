"""Compile the editable prologue Markdown. Never runs automatically on game launch."""
from pathlib import Path
import json, re, argparse, textwrap

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'scenario'
OUTPUT = ROOT / 'godot/data/prologue.json'

def compile_data():
    manifest = json.loads((BASE/'manifest.json').read_text(encoding='utf-8'))
    presentation = json.loads((BASE/'presentation.json').read_text(encoding='utf-8'))
    scene_status = presentation['scene_status']
    current_status = None
    staging = json.loads((BASE/'staging.json').read_text(encoding='utf-8'))
    cast, slots, cues = staging['cast'], staging['slots'], staging['cues']
    sprite_roles = staging['sprite_roles']
    exclusive = staging['exclusive_sprites']
    for actor, spec in cast.items():
        if not isinstance(spec.get('speaker'),str) or not (ROOT/'godot/assets/prologue'/(spec['sprite']+'.png')).is_file():
            raise ValueError('Invalid cast asset or speaker: '+actor)
        if not spec.get('role') or sprite_roles.get(spec['sprite'])!=spec['role']:
            raise ValueError('Sprite used outside its registered role: '+actor)
        if spec['sprite'] in exclusive and exclusive[spec['sprite']]!=actor:
            raise ValueError('Exclusive character sprite reused: '+actor)
    beats, chapters, ids, runtime_ids = [], [], set(), set()
    for filename in manifest['chapters']:
        path = BASE / filename
        text = path.read_text(encoding='utf-8')
        title = text.splitlines()[0].removeprefix('# ')
        chapter_id = path.stem.split('_')[0]
        chapters.append({'id':chapter_id,'title':title,'start':len(beats),'file':filename})
        memory_mode = False
        stage = []
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
            if identity in scene_status:
                current_status = scene_status[identity]
                if set(current_status) != {'date', 'location', 'period'}:
                    raise ValueError('Scene status needs date, location, period: '+identity)
                if current_status['period'] not in ['아침','낮','밤']:
                    raise ValueError('Invalid scene period: '+identity)
                if not all(isinstance(value,str) and value.strip() for value in current_status.values()):
                    raise ValueError('Empty scene status: '+identity)
            if current_status is None: raise ValueError('Missing initial scene status: '+identity)
            beat['transition'] = identity in scene_status or bool(beat['transition'])
            beat['scene_status'] = current_status.copy()
            if chapter_id=='P01':
                beat['background']={'room':'modern_room','road':'modern_forest','rain':'modern_rain'}.get(beat['background'],beat['background'])
            else:
                beat['background']={'road':'forest_path','hut':'solbaram_den','village':'village_overcast','stockade':'maegol_stockade','camp':'solbaram_night'}.get(beat['background'],beat['background'])
            beat['memory'] = memory_mode
            cue = cues.get(identity,{})
            if set(cue)-{'stage','motions'}: raise ValueError('Unknown staging field: '+identity)
            if 'stage' in cue:
                stage = []
                for actor in cue['stage']:
                    if actor['actor'] not in cast or actor['slot'] not in slots:
                        raise ValueError('Unknown cast actor/slot: '+identity)
                    spec = dict(id=actor['actor'], **cast[actor['actor']], **slots[actor['slot']])
                    if set(slots[actor['slot']])!={'x','enter'} or not (-40<=spec['x']<=960 and spec['enter'] in ['left','right']):
                        raise ValueError('Invalid actor placement: '+identity)
                    stage.append(spec)
                if len(stage)>3 or len({actor['id'] for actor in stage})!=len(stage):
                    raise ValueError('Stage requires up to three distinct actors: '+identity)
                if len({actor['sprite'] for actor in stage})!=len(stage):
                    raise ValueError('Duplicate NPC image in one stage: '+identity)
            motions = cue.get('motions',[])
            for motion in motions:
                if motion['actor'] not in [actor['id'] for actor in stage] or motion['motion'] not in ['jump','approach','shake']:
                    raise ValueError('Invalid actor motion: '+identity)
            beat['actors'] = [actor.copy() for actor in stage]
            beat['actor_motions'] = motions
            # Legacy single-sprite field is derived from the actual cast, never generic extra substitution.
            beat['sprite'] = next((actor['sprite'] for actor in stage if actor['speaker']==beat['speaker']), '')
            if not beat['text']: raise ValueError('Empty dialogue '+identity)
            if beat['side'] not in ['left','right']: raise ValueError('Invalid side '+identity)
            if beat['effect'] not in ['','fade','fadein','jump','shake','flash','blackout','walk']: raise ValueError('Invalid effect '+identity)
            if beat['sprite'] and beat['sprite'] not in sprite_roles: raise ValueError('Unknown sprite '+identity)
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
                    page_beat['transition'] = False
                    page_beat['actor_motions'] = []
                if page_beat['id'] in runtime_ids: raise ValueError('Generated page ID collision '+page_beat['id'])
                runtime_ids.add(page_beat['id'])
                beats.append(page_beat)
    if not beats: raise ValueError('No beats')
    if set(scene_status)-ids: raise ValueError('Unknown scene status IDs: '+str(sorted(set(scene_status)-ids)))
    if set(cues)-ids: raise ValueError('Unknown staging IDs: '+str(sorted(set(cues)-ids)))
    positions = {beat['id']:index for index,beat in enumerate(beats)}
    for actor, end_id in staging['retired_at'].items():
        if actor not in cast or end_id not in positions: raise ValueError('Invalid retirement boundary: '+actor)
        sprite = cast[actor]['sprite']
        if exclusive.get(sprite)!=actor: raise ValueError('Retired NPC must have an exclusive image: '+actor)
        if any(entry['sprite']==sprite for beat in beats[positions[end_id]:] for entry in beat['actors']):
            raise ValueError('Retired NPC image reappears: '+actor)
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
