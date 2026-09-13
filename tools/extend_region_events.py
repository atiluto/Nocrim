"""One-time authored supplement. Normal editing uses catalog.json, never this seed."""
import json,re
from pathlib import Path
B=Path(__file__).resolve().parents[1]/'scenario/events'
p=B/'catalog.json'; d=json.loads(p.read_text(encoding='utf-8')); es=d['events']
src=json.loads((B/'source_registry.json').read_text(encoding='utf-8'))
def effect(path,value,op='add'):return dict(op=op,path=path,value=value)
def flag(key,value=True):return effect('flags.'+key,value,'set')
def condition(path,value=True,op='eq'):return dict(path=path,value=value,op=op)
def define(id,text,rows,conditions=None,**extra):
    assert es[id]['status']=='pending',f'{id}: already authored; do not overwrite'
    nodes={'entry':dict(type='choice',text=text,choices=[])}
    gaps=[]
    for i,(label,result,effects,cost,requirements) in enumerate(rows):
        name='result'+str(i+1)
        row=dict(id=str(i+1),text=label,next=name,effects=effects,cost=cost,conditions=requirements)
        if result is None:
            row['pending']=True;result='';gaps.append(label+': 후속 기능/전투 미구현')
        nodes['entry']['choices'].append(row)
        nodes[name]=dict(type='result',text=result,next='END')
    es[id].update(status='partial' if gaps else 'ready',unimplemented=gaps,start='entry',nodes=nodes,conditions=conditions or [],**extra)
def row(label,result,effects=None,cost=None,conditions=None):return (label,result,effects or [],cost or {},conditions or [])
define('DG-R02','양쪽 부하 사이에 어느 산이 더 나은지 자존심 싸움이 붙었다.',[
 row('말림','부하들을 말려 다툼을 끝냈다.',[effect('regional.factions.dal',2)]),
 row('대련 허용','서로 다치지 않도록 지켜보며 대련을 허락했다.\n숙련 +2',[effect('training',2)],{'ap':1}),
 row('강산도 끼어듦','나도 대련에 끼어들었다.\n숙련 +3 · 체력 -3',[effect('training',3),effect('health',-3)],{'ap':1})])
define('DG-R03','달개울채에서 도망쳐 나온 산적이 숨겨 달라고 청했다.',[
 row('숨겨준다','도망친 산적을 숨겨 주었다.',[flag('dal_fugitive_sheltered'),effect('regional.factions.dal',-3)]),
 row('돌려보낸다','그를 달개울채로 돌려보냈다.',[flag('dal_fugitive_returned'),effect('regional.factions.dal',2)]),
 row('사정을 조사','그가 도망친 사정과 산채 내부의 불만을 조사했다.\n정보 +1',[flag('dal_discontent_known'),effect('intel',1)],{'ap':1}),
 row('영입','그를 산채의 식구로 받아들였다.\n인구 +1',[effect('regional.vars.population',1),flag('dal_fugitive_recruited'),effect('regional.factions.dal',-5)])],
 [condition('regional.locations.dal.discontent',20,'gte')])
define('AG-R01','안개재에서 낯선 자들이 검문을 핑계로 통행세를 요구했다.',[
 row('돈 낸다','돈을 내고 검문을 벗어났다.',[],{'gold':10}),
 row('정체를 캐묻는다','소속을 캐묻자 답이 엇갈렸다. 가짜 검문이었다.\n정보 +1',[flag('false_checkpoint_exposed'),effect('intel',1)]),
 row('싸운다',None),row('우회','검문이 없는 샛길로 돌아갔다.',[],{'ap':1})])
define('GM-R01','관문을 지키던 병사가 걸음을 막았다.',[
 row('신분 제시','신분을 밝히고 검문을 받았다.',[flag('gate_identity_shown')]),
 row('뇌물','돈을 건네고 검문을 벗어났다.',[],{'gold':15}),
 row('도주','추적을 피해 관문에서 물러났다.',[flag('gate_fled'),effect('regional.vars.yunga_alert',1)],{'ap':1}),
 row('위조 신분','위조한 신분으로 검문을 빠져나왔다.',[flag('gate_forged_identity_used')],{},[condition('regional.items.forged_identity',1,'gte')])])
define('YG-R02','소작농이 윤가 하급 관리의 횡포를 호소했다. 아직 사실인지는 알 수 없다.',[
 row('조사','주민과 관리의 말을 모두 모아 진위를 조사했다.',[
  dict(op='random',options=[[flag('yunga_claim_inquiry','confirmed'),effect('mercy',3)],[flag('yunga_claim_inquiry','unsubstantiated'),effect('intel',1)]])],{'ap':1}),
 row('윤가에 전달','주장의 진위를 단정하지 않고 윤가에 조사를 요청했다.',[flag('yunga_claim_referred'),effect('regional.factions.yunga',1)]),
 row('주민 편','주민을 보호하며 관리에게 항의했다. 윤가 전체의 뜻인지는 아직 알 수 없다.',[flag('yunga_claim_protected'),effect('mercy',3),effect('regional.factions.yunga',-2)]),
 row('무시','이 일에 끼어들지 않고 지나갔다.')])
es['YG-R02']['nodes']['result1']['texts']=[
 dict(when=condition('flags.yunga_claim_inquiry','confirmed'),text='증언을 대조하니 하급 관리의 횡포가 확인되었다.\n선량 평판 +3'),
 dict(when=condition('flags.yunga_claim_inquiry','unsubstantiated'),text='조사한 자료만으로는 횡포 주장을 뒷받침할 수 없었다.\n정보 +1')]
define('HD-R03','피해 상인이 산적 때문에 장사를 망쳤다며 항의했다.',[
 row('피해를 듣는다','누가 어떤 피해를 입혔는지 들었다.\n정보 +1',[effect('intel',1),flag('merchant_harm_heard')]),
 row('보상한다','상인의 손해를 보상했다.\n선량 평판 +4',[effect('mercy',4),flag('merchant_harm_compensated')],{'gold':20}),
 row('지나간다','항의를 뒤로하고 지나갔다.')])
es['HD-R03']['weight_modifiers']=[dict(conditions=[condition('regional.vars.civilian_harm',1,'gte')],multiplier=3)]
define('DN-R02','어둠 속에서 배 한 척이 조용히 짐을 옮기고 있었다.',[
 row('물가에서 지켜본다','나루의 배와 짐이 오가는 흔적을 살폈다.\n정보 +1',[effect('intel',1),flag('suspected_smuggling_boat')],{'ap':1}),
 row('마영란에게 흔적을 보게 한다','마영란은 젖은 밧줄과 사람 발자국을 확인했다. 밀수선의 출입 흔적이었다.',[flag('smuggling_boat_found'),effect('intel',2)],{},[condition('regional.vars.my_companion')]),
 row('지나간다','배에 다가가지 않고 지나갔다.')])
es['DN-R02']['weight_modifiers']=[dict(conditions=[dict(op='period_in',value=['밤'])],multiplier=3)]
define('DG-R01','달개울채의 산적이 술 한잔을 권했다.',[
 row('술잔을 받는다','술잔을 주고받으며 이야기를 나누었다.',[effect('regional.factions.dal',2)],{'ap':1}),
 row('소문을 듣는다','술자리에서 산길의 소문을 들었다.\n정보 +1',[effect('intel',1)],{'ap':1}),
 row('가볍게 내기한다','작은 내기로 술자리가 흥겨워졌다.',[dict(op='random',options=[[effect('gold',10)],[effect('gold',-10)]])],{'ap':1,'gold':10}),
 row('다음에 마신다','다음에 마시기로 하고 자리를 떠났다.')],[condition('regional.factions.dal',0,'gte')])
define('AG-C04','뒤에서 추격대가 다가온다. 산길을 벗어날 방법을 골라야 한다.',[
 row('숨는다','나무와 바위 사이에 몸을 숨겨 추격대를 흘려보냈다.',[flag('pursuit_evaded')],{'ap':1}),
 row('매복',None),row('우회','추격대와 떨어진 길로 돌아갔다.',[flag('pursuit_evaded')],{'ap':1}),row('항복',None)],
 [condition('flags.wanted')],repeatable=True,cooldown_days=20)
d['defaults']['items']['forged_identity']=0
d['defaults']['locations']['dal']={'discontent':20}
# Explicit decision categories implement the requested ordering; numbers within a category break ties.
for id,e in es.items():
 e['category']='npc' if id.startswith('MY-') else 'general'
for id in ['SB-C01','SB-C05','TB-C01','TB-C02','TB-C03','TB-C04','TB-C05','TB-C06','DG-C01','DG-C02','DG-C03','DG-C04','DG-C05','HD-C01','HD-C02','HD-C03','HD-C04','YG-C01','YG-C02','YG-C03','YG-C04','YG-C05','GM-C04','GM-C05']:
 if id in es:es[id]['category']='main'
for id in ['CM-C01','CM-C02','CM-C03','CM-C04','BU-C01','BU-C02','BU-C03','BU-C04','AG-C01','AG-C03','CH-C02','CH-C04']:es[id]['category']='special'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
