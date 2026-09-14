"""Compile the editable prologue Markdown. Never runs automatically on game launch."""
from pathlib import Path
import json, re, argparse, difflib

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'scenario'
OUTPUT = ROOT / 'godot/data/prologue.json'

def resolve_scene_status(status, identity, calendar):
    status = status.copy()
    if set(status) not in ({'date','location','period'}, {'date','location','period','calendar'}):
        raise ValueError('Scene status needs date, location, period (optional calendar): '+identity)
    if 'calendar' in status:
        value = status['calendar']
        if not isinstance(value,dict) or set(value)!={'era','cycle'} or value['era'] not in calendar['eras'] or type(value['cycle']) is not int or value['cycle']<0:
            raise ValueError('Invalid scene calendar (era, nonnegative integer cycle): '+identity)
        start = calendar['eras'][value['era']]
        index = (start['month']-1)*3+value['cycle']
        status['date'] = f"{start['prefix']}{start['year']+index//36}년 {(index%36)//3+1}월 {calendar['segments'][index%3]}"
    if status['period'] not in calendar['phases']:
        raise ValueError('Invalid scene period: '+identity)
    if not all(isinstance(status[key],str) and status[key].strip() for key in ['date','location','period']):
        raise ValueError('Empty scene status: '+identity)
    return status

def compile_data(base=BASE, event_mode=False):
    manifest = json.loads((base/'manifest.json').read_text(encoding='utf-8'))
    presentation = json.loads((base/'presentation.json').read_text(encoding='utf-8'))
    backgrounds = presentation.get('backgrounds',[])
    if not isinstance(backgrounds,list) or any(not isinstance(key,str) or not re.fullmatch(r'[a-z0-9_]+',key) for key in backgrounds):
        raise ValueError('Background registry needs lowercase asset names')
    weather_cues = presentation.get('weather',{})
    if not isinstance(weather_cues,dict) or any(value not in ['', 'rain', 'snow'] for value in weather_cues.values()):
        raise ValueError('Weather must be empty, rain or snow')
    scene_status = presentation['scene_status']
    calendar = json.loads((ROOT/'godot/data/calendar.json').read_text(encoding='utf-8'))
    current_status = None
    staging = json.loads((base/'staging.json').read_text(encoding='utf-8'))
    cast, slots, cues = staging['cast'], staging['slots'], staging['cues']
    sprite_roles = staging['sprite_roles']
    exclusive = staging['exclusive_sprites']
    for actor, spec in cast.items():
        if not isinstance(spec.get('speaker'),str):
            raise ValueError('Invalid speaker in scenario/staging.json cast: '+actor)
        sprite_path = ROOT/'godot/assets/prologue'/(spec['sprite']+'.png')
        if not sprite_path.is_file():
            similar = difflib.get_close_matches(sprite_path.name,
                [path.name for path in sprite_path.parent.glob('*.png')], n=3, cutoff=0.8)
            hint = ' Similar existing filenames: '+', '.join(similar)+'.' if similar else ''
            raise ValueError('Missing character image for '+actor+': '+
                sprite_path.relative_to(ROOT).as_posix()+'.'+hint+
                ' Check the image filename; this is not a dialogue text error.')
        if not spec.get('role') or sprite_roles.get(spec['sprite'])!=spec['role']:
            raise ValueError('Sprite used outside its registered role: '+actor)
        if spec['sprite'] in exclusive and exclusive[spec['sprite']]!=actor:
            raise ValueError('Exclusive character sprite reused: '+actor)
        for expression,sprite in spec.get('expressions',{}).items():
            if not expression or not (ROOT/'godot/assets/prologue'/(sprite+'.png')).is_file():
                raise ValueError('Missing expression sprite: '+actor+'/'+expression)
            if sprite_roles.get(sprite)!=spec['role'] or exclusive.get(sprite,actor)!=actor:
                raise ValueError('Expression sprite role mismatch: '+actor+'/'+expression)
    beats, chapters, ids, runtime_ids = [], [], set(), set()
    for filename in manifest['chapters']:
        path = base / filename
        text = path.read_text(encoding='utf-8')
        title = text.splitlines()[0].removeprefix('# ')
        chapter_id = path.stem.split('_')[0]
        chapters.append({'id':chapter_id,'title':title,'start':len(beats),'file':filename})
        memory_mode = False
        current_weather = ''
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
                if event_mode and scene_status[identity].get('live'):
                    current_status=scene_status[identity].copy()
                    if set(current_status)!={'date','location','period','live'}: raise ValueError('Invalid live scene status: '+identity)
                else:
                    current_status = resolve_scene_status(scene_status[identity],identity,calendar)
            if current_status is None: raise ValueError('Missing initial scene status: '+identity)
            beat['transition'] = identity in scene_status or bool(beat['transition'])
            beat['scene_status'] = current_status.copy()
            if chapter_id=='P01':
                beat['background']={'room':'modern_room','road':'modern_forest','rain':'modern_rain'}.get(beat['background'],beat['background'])
            else:
                beat['background']={'road':'forest_path','hut':'solbaram_den','village':'village_overcast','stockade':'maegol_stockade','camp':'solbaram_night'}.get(beat['background'],beat['background'])
            beat['memory'] = memory_mode
            current_weather = weather_cues.get(identity,current_weather)
            beat['weather'] = current_weather
            cue = cues.get(identity,{})
            if set(cue)-{'stage','motions','expressions'}: raise ValueError('Unknown staging field: '+identity)
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
            for actor_id,expression in cue.get('expressions',{}).items():
                target=next((actor for actor in stage if actor['id']==actor_id),None)
                if target is None or expression not in cast[actor_id].get('expressions',{}):
                    raise ValueError('Unknown actor/expression: '+identity+' '+actor_id+'/'+expression)
                target['sprite']=cast[actor_id]['expressions'][expression]
                target['expression']=expression
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
            if beat['background'] not in ['black','modern_room','modern_forest','modern_rain','forest_path','solbaram_den','village_overcast','maegol_stockade','solbaram_night']+backgrounds: raise ValueError('Unknown background '+identity)
            if beat['sprite'] and not (ROOT/'godot/assets/prologue'/(beat['sprite']+'.png')).is_file(): raise ValueError('Missing sprite '+identity)
            if beat['background']!='black' and not (ROOT/'godot/assets/prologue'/(beat['background']+'.png')).is_file(): raise ValueError('Missing background '+identity)
            for key in ['music','ambience','sfx']:
                if beat[key] and not (ROOT/'godot/assets/audio'/beat[key]).is_file(): raise ValueError('Missing audio '+beat[key])
            # One authored beat per click. Preserve explicit newlines; the UI wraps to its width.
            if identity in runtime_ids: raise ValueError('Beat ID collision '+identity)
            runtime_ids.add(identity)
            beats.append(beat)
    if not beats: raise ValueError('No beats')
    if set(scene_status)-ids: raise ValueError('Unknown scene status IDs: '+str(sorted(set(scene_status)-ids)))
    if set(cues)-ids: raise ValueError('Unknown staging IDs: '+str(sorted(set(cues)-ids)))
    if set(weather_cues)-ids: raise ValueError('Unknown weather IDs: '+str(sorted(set(weather_cues)-ids)))
    positions = {beat['id']:index for index,beat in enumerate(beats)}
    for actor, end_id in staging['retired_at'].items():
        if actor not in cast or end_id not in positions: raise ValueError('Invalid retirement boundary: '+actor)
        sprite = cast[actor]['sprite']
        if exclusive.get(sprite)!=actor: raise ValueError('Retired NPC must have an exclusive image: '+actor)
        retired_images = {sprite, *cast[actor].get('expressions',{}).values()}
        if any(entry['id']==actor or entry['sprite'] in retired_images for beat in beats[positions[end_id]:] for entry in beat['actors']):
            raise ValueError('Retired NPC image reappears: '+actor)
    if not event_mode and len(chapters)!=11: raise ValueError('Prologue must have 11 scenes')
    return {'version':1,'pagination_revision':3,'previous_beat_ids':manifest.get('previous_beat_ids',[]),
            'previous_paginated_beat_ids':manifest.get('previous_paginated_beat_ids',[]),
            'source':'scenario/manifest.json','chapters':chapters,'beats':beats}

if __name__=='__main__':
    args=argparse.ArgumentParser(); args.add_argument('--check',action='store_true'); ns=args.parse_args()
    result=compile_data()
    serialized=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
    if ns.check:
        assert OUTPUT.read_text(encoding='utf-8')==serialized,'Compiled data is stale'
    else:
        OUTPUT.write_text(serialized,encoding='utf-8')
    print(f"{len(result['chapters'])} chapters, {len(result['beats'])} beats: {'checked' if ns.check else 'compiled'}")
