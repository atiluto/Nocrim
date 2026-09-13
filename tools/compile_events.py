"""Compile event graphs plus MD through the existing scenario compiler."""
import json,argparse
from compile_scenario import ROOT,compile_data
BASE=ROOT/'scenario/events'

def validate_condition(value, context):
    if isinstance(value,list):
        for entry in value:validate_condition(entry,context)
        return
    assert isinstance(value,dict),(context,'condition must be object/list')
    if not value:return
    for group in ['all','any','not']:
        if group in value:
            assert len(value)==1,(context,'cannot mix condition groups')
            if group!='not':assert isinstance(value[group],list),(context,group)
            validate_condition(value[group],context);return
    op=value.get('op','eq')
    assert op in ['eq','ne','truthy','gte','lte','contains','count_gte','date_gte','date_lte','month_in','period_in','since'],(context,'unknown condition',op)
    if op in ['date_gte','date_lte']:validate_date(value['value'],context)
    elif op=='month_in':assert all(type(x)==int and 1<=x<=12 for x in value['value']),context
    elif op=='period_in':assert all(x in ['아침','낮','밤'] for x in value['value']),context
    else:validate_path(value.get('path',''),context)

def validate_date(value,context):
    assert isinstance(value,dict) and type(value.get('year'))==int and type(value.get('month'))==int,context
    assert value['year']>=732 and 1<=value['month']<=12 and 1<=value.get('day',1)<=30 and value.get('period',0) in [0,1,2],(context,'invalid date')

def validate_path(path,context):
    roots=['regional','flags','owned','roster','aff','gold','rice','health','mercy','fear','morale','ap','intel','qi','training','medicine','troops','lore','fame','turn']
    assert isinstance(path,str) and path.split('.')[0] in roots and all(path.split('.')),(context,'unknown state path',path)

def validate_effects(effects,context,events,places):
    assert isinstance(effects,list),context
    for effect in effects:
        op=effect.get('op')
        assert op in ['set','add','max','stamp','append','random','home','schedule'],(context,'unknown effect',op)
        validate_condition(effect.get('when',[]),context)
        if op=='random':
            assert effect['options'],context
            for option in effect['options']:validate_effects(option,context,events,places)
        elif op=='home':assert effect['value'] in places,context
        elif op=='schedule':assert effect['value'] in events and effect['days']>0,context
        else:
            validate_path(effect.get('path',''),context)
            if op in ['add','max']:assert isinstance(effect.get('value'),(int,float)),context
def compile_events(check=False):
    data=json.loads((BASE/'catalog.json').read_text(encoding='utf-8'))
    dialogue=compile_data(BASE,True)
    ids={b['id'] for b in dialogue['beats']}
    places=json.loads((ROOT/'godot/data/chapter_01_map.json').read_text(encoding='utf-8'))['nodes']
    events=data['events']
    for id,event in events.items():
        assert id==event['id']
        assert all(p in places or p=='*' for p in event['locations']),id
        assert event['type'] in ['STATIC','RANDOM','CONDITIONAL','FOLLOWUP'],id
        assert event['status'] in ['ready','partial','pending'],id
        validate_condition(event.get('conditions',[]),id)
        for date in ['from','until']:
            if date in event:validate_date(event[date],id)
        for effect in ['complete','expire']:validate_effects(event.get(effect,[]),id,events,places)
        for key in ['cost_modifiers','weight_modifiers']:
            for modifier in event.get(key,[]):
                validate_condition(modifier['conditions'],id)
                assert modifier['multiplier']>0,id
        if event['status']=='pending':continue
        assert event['start'] in event['nodes'],id
        for name,node in event['nodes'].items():
            assert node['type'] in ['choice','dialogue','result'],(id,name)
            assert all(b in ids for b in node.get('beats',[])),(id,name)
            assert len({r['id'] for r in node.get('choices',[])})==len(node.get('choices',[])),(id,name)
            if node['type']=='choice':assert node.get('choices'),(id,name,'empty choices')
            if node['type']=='dialogue':assert node.get('beats'),(id,name,'empty dialogue')
            for row in node.get('choices',[]):
                validate_condition(row.get('conditions',[]),(id,name,row['id']))
                validate_effects(row.get('effects',[]),(id,name,row['id']),events,places)
                for path,cost in row.get('cost',{}).items():
                    validate_path(path,id);assert isinstance(cost,(int,float)) and cost>=0,id
            for text in node.get('texts',[]):validate_condition(text['when'],id)
            for target in [node.get('next','END')]+[r['next'] for r in node.get('choices',[])]:
                assert target in event['nodes'] or target in ['END','DEFER'],(id,name,target)
        if event.get('immediate'):assert event['immediate'] in events,id
    for path,value in [(ROOT/'godot/data/region_events.json',data),(ROOT/'godot/data/event_dialogue.json',dialogue)]:
        text=json.dumps(value,ensure_ascii=False,indent=2)+'\n'
        if check:assert path.read_text(encoding='utf-8')==text,'Stale '+str(path)
        else:path.write_text(text,encoding='utf-8')
    print(f"Events: {len(events)}, playable/partial: {sum(e['status']!='pending' for e in events.values())}, dialogue beats: {len(ids)}; {'checked' if check else 'compiled'}")
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');compile_events(parser.parse_args().check)
