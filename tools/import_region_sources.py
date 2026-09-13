"""One-time source registration. Does NOT run from the dialogue apply BAT.
Preserves source blocks; write-once editable event graphs and MD, never overwrite edits.
"""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'scenario/events'
BASE.mkdir(exist_ok=True)
def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    if path.exists(): raise RuntimeError('Refusing to overwrite authored file: '+str(path))
    path.write_text(data if isinstance(data,str) else json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
locations=dict(SB='sol',SJ='market',CM='iron',BU='white',TB='tae',AG='mist',DG='dal',DN='ferry',HD='guild',CH='crane',JS='red',GM='exit_east',YG='clan')
def C(path,value=True,op='eq'): return dict(path=path,value=value,op=op)
def V(k,v=True,op='eq'): return C('regional.vars.'+k,v,op)
def E(path,value,op='set'): return dict(op=op,path=path,value=value)
def F(k,v=True): return E('flags.'+k,v)
def M(k,v,op='add'): return E('regional.vars.'+k,v,op)
def result_effects(text):
    effects=[]
    for key,op,val in re.findall(r'`((?:my_)?(?:trust|affection|suspicion|debt|secret_known|kept_secret|romance|route_failed))\s*([+=-])\s*(true|false|\d+)`',text):
        key=key if key.startswith('my_') else 'my_'+key
        value=val=='true' if val in ['true','false'] else int(val)*(-1 if op=='-' else 1)
        effects.append(M(key,value,'set' if op=='=' else 'add'))
    return effects
sources={}
for name in ['철마산역_전체이벤트설계.md','마영란_철마산역_히로인_이벤트_전체대본.md']:
    text=(ROOT/'scenario'/name).read_text(encoding='utf-8')
    for m in re.finditer(r'^## ((?:MY-)?[A-Z]+-[A-Z0-9-]+) — ([^\n]+)\n(.*?)(?=^## [A-Z]+-[A-Z0-9-]+ — |^# \d|\Z)',text,re.M|re.S):
        id,title,body=m.groups(); sources[id]=dict(id=id,title=title,source=name,body=body.strip())
write(BASE/'source_registry.json',sources)
events={}
for id,s in sources.items():
    prefix=id.split('-')[1] if id.startswith('MY-') else id.split('-')[0]
    if prefix=='CHAIN': continue
    body=s['body']; head=body.split('###')[0]
    kind='STATIC' if 'STATIC' in head else 'RANDOM' if 'RANDOM' in head or '랜덤' in head or prefix=='R' else 'CONDITIONAL'
    events[id]=dict(id=id,title=s['title'],locations=[locations.get(prefix,'*')],type=kind,status='pending',visibility='hidden' if kind=='RANDOM' or '숨김' in head else 'condition',priority=100 if '긴급' in head or re.search(r'우선.*100',head) else 80 if id.startswith('MY-') else 90 if re.search(r'우선.*90',head) else 10 if kind=='STATIC' else 30 if kind=='RANDOM' else 60,repeatable=kind in ['STATIC','RANDOM'] and '1회성' not in head,cooldown_days=int((re.search(r'쿨다운[^\d]*(\d+)',head) or [None,15 if kind=='RANDOM' else 0])[1]),conditions=[],start='entry',nodes={},source=s['source'],unimplemented=['발생 조건·선택 결과의 상세 실행 데이터 미등록'])

staging=dict(cast={},slots=json.loads((ROOT/'scenario/staging.json').read_text(encoding='utf-8'))['slots'],cues={},sprite_roles={},exclusive_sprites={},retired_at={})
presentation={'scene_status':{}}
chapters=[]; beats_by_id={}
bg_by_loc={'sol':'solbaram_den','market':'village_overcast','guild':'village_overcast','clan':'village_overcast'}
def dialogue(id,key,text,loc):
    # Each explicit speaker paragraph is one stable beat; all other source text remains in registry.
    lines=[]
    for para in re.split(r'\n\s*\n',text.strip()):
        m=re.match(r'^\*\*([^*\n]+)\*\*\s*(?:\n(.*))?$',para,re.S)
        if not m: continue
        speaker,words=m.groups()
        if ':' in speaker: continue
        if words is None: words=speaker; speaker='독백'
        if speaker in ['침묵'] or speaker.endswith(('!','—','.')): words=speaker+('\n'+words if words!=speaker else ''); speaker='독백'
        lines.append((speaker,words.strip()))
    if not lines: return []
    ids=[]; content=['# '+sources[id]['title']+' — '+key+'\n']
    for i,(speaker,words) in enumerate(lines,1):
        bid=f'{id}-{key}-{i:03d}'; ids.append(bid)
        bg=bg_by_loc.get(loc,'forest_path')
        music='bgm/bgm_murim_survival.mp3'
        if loc in ['sol','market']: music='bgm/bgm_inn_afterhours.mp3'
        amb='sfx/amb_mountain_morning_loop_01.mp3' if bg=='forest_path' else ''
        content.append(f'### {bid}\n화자: {speaker}\n배경: {bg}\n인물:\n위치: right\n음악: {music}\n환경음: {amb}\n효과음:\n연출:\n\n대사:\n{words}\n')
        if i==1:
            staging['cues'][bid]={'stage':[]}
            presentation['scene_status'][bid]={'date':'현재','location':loc,'period':'현재','live':True}
    filename=f'chapters/{id}/{key}.md'; write(BASE/filename,'\n'.join(content)); chapters.append(filename)
    return ids
def row(i,text,next='END',effects=None,**kw):return dict(id=str(i),text=text,next=next,effects=effects or [],**kw)
def outcome_node(text,next='END'):return dict(type='result',text=text,next=next)

for id,event in events.items():
    if not id.startswith('MY-'): continue
    body=sources[id]['body']; head=body.split('###')[0]
    event['conditions']=[V('my_met'),V('my_route_failed',False)] if id!='MY-AG-01' else [C('flags.prologue_complete'),V('my_met',False)]
    for key,num in re.findall(r'(?:my_)?(trust|affection|suspicion|route_stage)\s*>=\s*(\d+)',head):event['conditions'].append(V('my_'+key,int(num),'gte'))
    for key in ['my_romance','my_kept_secret','my_likes_hair_tie']:
        if key in head:event['conditions'].append(V(key))
    if '동행' in head or id.startswith('MY-R-'):event['conditions'].append(V('my_companion'))
    if '밤' in head:event['conditions'].append({'op':'period_in','value':['밤']})
    if '연애 후' in head:event['conditions'].append(V('my_romance'))
    event['status']='partial'; event['unimplemented']=[]
    # Structural headings delimit authored branch dialogue; no prose is merged across choices.
    blocks=re.split(r'^(#### .+|### 마무리)\s*$',body,flags=re.M)
    intro=blocks[0]; branches={}; tail=''
    for n in range(1,len(blocks),2):
        if blocks[n].startswith('### 마무리'):tail=blocks[n+1]
        else:branches[blocks[n][5:]]=blocks[n+1]
    common=dialogue(id,'COMMON',intro,event['locations'][0])
    tailids=dialogue(id,'TAIL',tail,event['locations'][0])
    nodes=event['nodes']
    if tailids:nodes['tail']={'type':'dialogue','beats':tailids,'next':'END'}
    end='tail' if tailids else 'END'
    choices=re.findall(r'^\d+\.\s*(.+)$',intro,re.M)
    choices=[re.split(r'\s*→',x.replace('**',''))[0].strip() for x in choices]
    if branches:
        branchrows=[]
        for n,(title,branch) in enumerate(branches.items(),1):
            key='BRANCH'+str(n); ids=dialogue(id,key,branch,event['locations'][0])
            target=key if ids else 'result'+str(n)
            if ids:nodes[key]={'type':'dialogue','beats':ids,'next':end}
            else:
                prose=branch.split('결과:')[0].strip().replace('  \n','\n')
                nodes[target]=outcome_node(prose or re.sub(r'^\d+\.\s*','',title),end)
            branchrows.append(row(n,re.sub(r'^\d+\.\s*','',title),target,result_effects(branch)))
        nodes['branch']={'type':'choice','text':'','choices':branchrows}
        if common:nodes['common']={'type':'dialogue','beats':common,'next':'branch'}
        event['start']='common' if common else 'branch'
        if id in ['MY-AG-01','MY-AG-03']:
            nodes['entry']={'type':'choice','text':'안개재로 들어서자 진흙 위에 발자국이 보인다. 얼핏 보면 서너 명이 지나간 흔적 같다.' if id=='MY-AG-01' else '마영란이 갈림길 앞에 서 있었다.','choices':[row(1,choices[0],'common'),row(2,choices[1],'DEFER'),row(3,choices[2],'common')]}
            event['start']='entry'
    else:
        if common:nodes['common']={'type':'dialogue','beats':common,'next':'END'}
        if choices:
            nodes['entry']={'type':'choice','text':event['title'],'choices':[]}
            for n,label in enumerate(choices,1):
                deferred=any(word in label for word in ['지나간','모른 척','보류','혼자 간다','안 산다','부탁하지','돌아간다','시간 없','못하게'])
                supported=n==1 or deferred
                nodes['entry']['choices'].append(row(n,label,'DEFER' if deferred else 'common',result_effects(intro) if n==1 else [],pending=not supported))
                if not supported:event['unimplemented'].append(label+': 원문의 변형 대화/구체 결과 미작성')
            event['start']='entry'
        else:
            event['start']='common';event['complete']=result_effects(body)
    if not event['unimplemented']:event['status']='ready'
    if not common:event['status']='pending';event['unimplemented'].append('본 대화 미작성')

def adjust(id,**kw):events[id].update(kw)
adjust('MY-AG-01',**{'from':dict(year=732,month=3,day=21)},complete=[M('my_met',True,'set'),M('my_route_stage',1,'set'),E('regional.vars.my_met_at',None,'stamp')])
events['MY-AG-02']['conditions'] += [V('my_met_at',5,'since'),V('my_route_stage',2,'lte')]
events['MY-BU-01']['conditions'] += [V('my_met_at',10,'since')]
events['MY-BU-01']['nodes']['entry']['choices'][0]['effects'] += [F('merchant_cart_helped'),E('regional.vars.cart_helped_at',None,'stamp')]
for id in ['MY-AG-03','MY-CM-01']:events[id]['complete']=[M('my_route_stage',2,'max')]
events['MY-BU-02']['complete']=[F('my_tracking_unlocked'),M('my_route_stage',3,'max')]
adjust('MY-BU-03',**{'from':dict(year=732,month=6,day=1),'until':dict(year=732,month=8,day=30,period=2)},priority=100,visibility='condition',immediate='MY-BU-04',expire_text='수상한 상단의 흔적이 사라졌다.')
events['MY-BU-03']['complete']=[M('my_route_stage',3,'max')]
adjust('MY-BU-04',type='FOLLOWUP',repeatable=False)
events['MY-CM-02']['nodes']['branch']['choices'][2]['effects'].append(F('my_secret_friendly'))
for id in ['MY-SJ-03']:events[id]['complete']=[M('my_likes_hair_tie',True,'set')]
for id in ['MY-SB-03']:adjust(id,**{'from':dict(year=732,month=11),'until':dict(year=732,month=12,day=30,period=2)})
events['MY-SB-04']['conditions'].append(C('regional.completed.MY-SB-03',0,'gte'))
events['MY-SB-06']['conditions'].append(V('lodging_spare',0,'lte'))
events['MY-SB-07']['conditions'] += [V('my_companion'),V('my_met_at',30,'since')]
events['MY-SB-07']['complete']=[F('my_guard_system')]
events['MY-JS-01']['conditions'] += [C('regional.completed.MY-BU-03',0,'gte'),C('flags.small_fire')]
events['MY-JS-01']['complete']=[F('my_fire_cooperation'),F('saved_jeoksong')]
adjust('MY-JS-03',locations=['sol','red'],**{'from':dict(year=733,month=1),'until':dict(year=733,month=1,day=30,period=2)},duration_days=2,priority=100,visibility='condition',expire=[M('my_trust',-20),M('my_rescue_missed',1)],expire_text='마영란은 다친 채 자력으로 돌아왔다.',complete=[F('my_core_rescue'),M('my_route_stage',5,'max')])
events['MY-JS-03']['conditions'].append(V('my_route_stage',3,'gte'))
events['MY-DG-01']['conditions'].append(C('flags.dalgaeul_first_meeting'))
events['MY-DG-01']['complete']=[F('my_dal_intel')]
events['MY-DN-02']['complete']=[F('my_smuggling_route')]
events['MY-HD-01']['conditions'].append(C('flags.escort_testimony'))
adjust('MY-CH-02',**{'from':dict(year=733,month=2),'until':dict(year=733,month=3,day=30,period=2)})
events['MY-CH-02']['conditions'] += [C('flags.my_core_rescue'),V('civilian_harm',2,'lte')]
events['MY-CH-02']['nodes']['branch']['choices'] += [row(2,'지금 관계로도 충분하다고 한다.','END',[M('my_friendship',True,'set')]),row(3,'대답을 피한다.','DEFER')]
events['MY-CH-02']['complete']=[M('my_route_stage',6,'set')]
adjust('MY-YG-01',**{'from':dict(year=732,month=7)})
events['MY-YG-01']['conditions'].append(V('yunga_alert',1,'gte'))
adjust('MY-GM-01',**{'from':dict(year=732,month=9),'until':dict(year=732,month=10,day=30,period=2)},complete=[M('my_companion',False,'set'),E('regional.vars.my_departed_at',None,'stamp'),M('my_away',True,'set')])
events['MY-GM-02']['conditions'] += [V('my_departed_at',25,'since'),V('my_away')]
events['MY-GM-02']['complete']=[M('my_away',False,'set'),M('my_companion',True,'set')]
events['MY-TB-01']['conditions']=[C('regional.completed.MY-GM-01',0,'gte')]
events['MY-TB-01']['complete']=[M('my_kept_secret',True,'set'),M('my_route_stage',4,'max')]
events['MY-TB-02']['locations']=['mist','tae'];events['MY-TB-02']['conditions'] += [C('regional.completed.MY-TB-01',0,'gte'),V('my_away',False)]
for id in ['MY-R-07','MY-SB-05']:events[id]['conditions'].append({'op':'period_in','value':['밤']})
events['MY-R-09']['conditions'].append({'op':'month_in','value':[11,12,1,2]})
events['MY-R-10']['conditions'].append(V('my_romance'))
adjust('MY-FAIL-01',locations=['*'],priority=110,conditions=[V('my_met'),V('my_route_failed',False),{'any':[V('my_trust',-30,'lte'),V('civilian_harm',3,'gte'),V('my_rescue_missed',2,'gte'),V('torture_count',2,'gte')]}],complete=[M('my_route_failed',True,'set'),M('my_romance',False,'set'),M('my_companion',False,'set')])
defaults={'vars':dict(my_met=False,my_route_stage=0,my_trust=0,my_affection=0,my_suspicion=0,my_debt=0,my_secret_known=False,my_kept_secret=False,my_companion=False,my_romance=False,my_route_failed=False,my_friendship=False,my_likes_hair_tie=False,my_away=False,my_met_at=-9999,my_departed_at=-9999,my_rescue_missed=0,civilian_harm=0,torture_count=0,cart_helped_at=-9999,population=17,building=55,fatigue=0,security=20,discontent=0,wood=20,lodging_spare=2,yunga_alert=0),'items':{},'factions':{'greenwood':0,'yunga':0,'escort':0,'dal':0,'haomun':0},'locations':{}}
write(BASE/'catalog.json',{'version':1,'defaults':defaults,'companion':{'conditions':[V('my_met'),V('my_route_stage',3,'gte'),V('my_route_failed',False),V('my_away',False)]},'events':events})
write(BASE/'staging.json',staging);write(BASE/'presentation.json',presentation)
write(BASE/'manifest.json',{'chapters':chapters})
print(len(events),'events registered;',len(chapters),'dialogue segments. Run compile_events.py after editing catalog.')
