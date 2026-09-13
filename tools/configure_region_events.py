"""One-time authored implementation data for the imported regional catalog.
Do not rerun over user edits. Unspecified numeric balance is isolated here/in catalog.
"""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]; BASE=ROOT/'scenario/events'
path=BASE/'catalog.json';d=json.loads(path.read_text(encoding='utf-8'));es=d['events'];src=json.loads((BASE/'source_registry.json').read_text(encoding='utf-8'))
if any(e['status']!='pending' for k,e in es.items() if not k.startswith('MY-')):
    raise SystemExit('Refusing to overwrite authored regional events; edit scenario/events/catalog.json.')

def C(p,v=True,op='eq'):return dict(path=p,value=v,op=op)
def V(k,v=True,op='eq'):return C('regional.vars.'+k,v,op)
def E(p,v,op='add'):return dict(op=op,path=p,value=v)
def F(k,v=True):return E('flags.'+k,v,'set')
def M(k,v,op='add'):return E('regional.vars.'+k,v,op)
def fac(k,v):return E('regional.factions.'+k,v)
def item(k,v=1):return E('regional.items.'+k,v)
def when(cond,effects):return [dict(e,when=cond) for e in effects]
def define(id,labels,effects,costs=None,conditions=None,**kw):
    e=es[id];e.update(status='ready',unimplemented=[],conditions=conditions or [],**kw)
    rows=[];nodes={}
    for i,label in enumerate(labels):
        target='result'+str(i)
        rows.append(dict(id=str(i+1),text=label,next=target,effects=effects[i],cost=(costs or [{}]*len(labels))[i]))
        changes=[]
        for effect in effects[i]:
            if effect['op']=='add' and effect['path'] in ['gold','rice','mercy','fear','health','intel','training']:
                changes.append({'gold':'자금','rice':'식량','mercy':'선량 평판','fear':'악명','health':'체력','intel':'정보','training':'숙련'}[effect['path']]+f" {effect['value']:+}")
        nodes[target]=dict(type='result',text=label+'\n'+' · '.join(changes),next='END')
    intro=re.search(r'도입:\s*\n((?:>[^\n]*\n?)+)',src[id]['body'])
    nodes['entry']=dict(type='choice',text=re.sub(r'^> ?','',intro[1],flags=re.M).strip() if intro else es[id]['title'],choices=rows)
    e.update(start='entry',nodes=nodes)
def original_labels(id):
    body=src[id]['body'];match=re.search(r'선택(?:지)?:\s*\n(.*?)(?:\n\n|\Z)',body,re.S)
    return re.findall(r'^\d+\.\s*(.+)',match[1],re.M) if match else []
def choice(id,effects,costs=None,**kw): define(id,original_labels(id),effects,costs,**kw)
def report(id,text,effects,**kw):
    es[id].update(status='ready',unimplemented=[],conditions=kw.pop('conditions',[]),start='report',nodes={'report':dict(type='result',text=text,next='END')},complete=effects,**kw)
def flags(id,names,**kw):report(id,src[id]['title'],[F(x) for x in names],**kw)

choice('SB-01',[[E('health',35),M('fatigue',-20)],[ ]],[{'ap':1},{}],conditions=[C('owned','sol','contains')])
es['SB-01']['nodes']['entry']['choices'][0]['effects'] += when(V('building',80,'gte'),[E('health',15)])
es['SB-01']['nodes']['result1']['next']='DEFER'
report('SB-02','산채의 인구·식량·자금·건물·경비·사기와 진행 중인 문제를 확인했다.',[],report='stockade')
choice('SB-R01',[[M('building',15),F('roof_problem_seen')],[M('building',30),F('roof_problem_seen')],[M('building',-5),F('roof_problem_seen')]], [{'ap':1},{'gold':20},{}],conditions=[V('building',80,'lte')])
choice('SB-R02',[[M('security',5)],[E('morale',3),E('health',-3)],[M('security',2)],[M('discontent',5)]],conditions=[V('population',5,'gte')])
choice('SB-R03',[[M('population',1)],[E('intel',1)],[]])
choice('SB-C01',[[F('solbaram_house_built'),M('building',30)],[]],[{'regional.vars.wood':10},{}],conditions=[C('flags.prologue_complete'),V('wood',10,'gte')],**{'from':dict(year=732,month=3),'until':dict(year=732,month=3,day=30,period=2)})
es['SB-C01']['nodes']['result1']['next']='DEFER'
choice('SB-C02',[[E('rice',40)],[E('rice',25)],[E('rice',45),E('fear',5),M('civilian_harm',1)],[E('rice',10),E('morale',-5)]],[{'gold':20},{'ap':1},{'ap':1},{}],conditions=[V('population',8,'gte'),C('rice',30,'lte')],repeatable=True,cooldown_days=10)
choice('SB-C03',[[M('population',6),F('first_settlers')],[M('population',3),F('first_settlers')],[]],conditions=[C('mercy',20,'gte'),V('refugees_rescued',2,'gte')])
choice('SB-C04',[[F('stockade_roles_open'),M('security',10)],[]],conditions=[V('population',15,'gte')])
choice('SB-C05',[[E('rice',70)],[M('wood',40)],[E('rice',40),fac('escort',5)],[]],[{'gold':35},{'ap':1},{'gold':20},{}],**{'from':dict(year=732,month=11),'until':dict(year=733,month=2,day=30,period=2)},settle_after_completion=True,expire=when([C('rice',60,'gte'),V('wood',20,'gte')],[F('first_winter_result','enough'),E('morale',5)])+when({'not':{'all':[C('rice',60,'gte'),V('wood',20,'gte')]}},[F('first_winter_result','shortage'),M('population',-2),E('health',-10)]),expire_text='월동 물자에 따라 첫 겨울의 결과가 확정되었다.')
define('SJ-01',['식량을 산다','공구를 산다','의약품을 산다','보유 약초를 판다'],[[E('rice',40)],[item('tools')],[E('medicine',1)],[E('gold',6)]],[{'gold':20},{'gold':12},{'gold':10},{'regional.items.herb':1}])
report('SJ-02','장시에서 소문을 들었다.',[],report='rumors')
choice('SJ-R01',[[E('gold',3),E('mercy',2)],[E('gold',3)],[E('gold',-5)]])
choice('SJ-R02',[[item('fake_medicine')],[E('mercy',2)],[]],[{'gold':5},{},{}])
choice('SJ-R03',[[E('mercy',2)],[],[fac('greenwood',2)],[]],conditions=[{'op':'period_in','value':['낮','밤']}])
flags('SJ-C01',['merchant_partner'],conditions=[C('flags.merchant_cart_helped'),V('cart_helped_at',14,'since')])
choice('SJ-C02',[[F('market_growth_1')],[]],[{'gold':50},{}],conditions=[V('security',40,'gte')],**{'from':dict(year=733,month=1)})
choice('SJ-C03',[[F('consignment_income')],[]],conditions=[C('mercy',40,'gte')])
define('CM-01',['산세를 살핀다','돌아간다'],[[E('training',2),M('cheolma_searches',1)],[]],[{'ap':1},{}])
define('CM-02',['약초를 찾는다','돌아간다'],[[item('herb'),M('cheolma_searches',1)],[]],[{'ap':1},{}])
choice('CM-R01',[[E('rice',12),E('health',-4)],[],[E('intel',1)]],[{'ap':1},{},{'ap':1}])
choice('CM-R02',[[item('scrap')],[E('intel',1)],[]])
choice('CM-R03',[[E('mercy',2)],[E('mercy',5),item('herb')],[E('gold',8),E('fear',2)],[]],[{}, {'ap':1},{},{}])
flags('CM-C01',['strange_mountain_flow'],conditions=[C('flags.gigam_unlocked')])
flags('CM-C03',['cheolma_cave_open'],conditions=[V('cheolma_searches',3,'gte')])
flags('CM-C04',['true_clue_cheolma_01'],**{'from':dict(year=734,month=1)})
report('BU-01','고개 너머로 이어지는 길을 살폈다.',[],report='roads')
choice('BU-R01',[[F('merchant_cart_helped'),E('regional.vars.cart_helped_at',None,'stamp'),E('mercy',6)],[E('gold',12),F('merchant_cart_helped'),E('regional.vars.cart_helped_at',None,'stamp')],[],[E('gold',25),E('fear',10),M('civilian_harm',1),F('merchant_cart_robbed')]],[{'ap':1},{'ap':1},{},{}])
choice('BU-R02',[[],[E('health',-5)],[E('health',10)]],[{'ap':1},{},{'ap':1}])
choice('BU-R03',[[E('intel',1)],[item('scrap')],[E('mercy',3)],[]],[{'ap':1},{},{'ap':1},{}])
flags('BU-C04',['true_clue_baekun_01'],**{'from':dict(year=734,month=7)})
choice('BU-C05',[[E('mercy',8),F('baekun_rescued')],[E('mercy',4),F('baekun_rescued')],[]],[{'ap':1},{'rice':15},{}],conditions=[{'op':'month_in','value':[11,12,1,2]}],duration_days=3,priority=100,visibility='condition',yearly=True,repeatable=True,cooldown_days=300,expire=[F('baekun_rescue_failed'),E('regional.locations.white.casualties',1)],expire_text='구조 기한을 넘겨 상단에 인명 피해가 났다.')
es['BU-C05']['nodes']['result2']['next']='DEFER'
report('TB-01','녹림의 소문을 들었다.',[],report='rumors')
define('TB-02',['상납한다','돌아간다'],[[fac('greenwood',5)],[]],[{'gold':15},{}])
choice('TB-R01',[[fac('greenwood',2)],[fac('greenwood',-3)],[]],conditions=[C('regional.factions.greenwood',10,'lte')])
choice('TB-R02',[[fac('greenwood',3)],[fac('greenwood',1)],[],[]])
choice('TB-R03',[[fac('greenwood',3)],[fac('greenwood',-2)],[E('fear',2)],[E('intel',1)]],[{'gold':10},{},{},{'ap':1}])
flags('TB-C01',['kangsan_registered'],conditions=[C('flags.maegol_complete')])
choice('TB-C02',[[F('taebaek_warned',False)],[F('taebaek_warned')],[F('taebaek_warned')]],conditions=[C('owned',3,'count_gte')])
flags('TB-C03',['greenwood_council_open'],conditions=[C('owned',5,'count_gte'),C('regional.factions.greenwood',30,'gte')])
choice('TB-C04',[[F('toll_policy_debate','defend')],[F('toll_policy_debate','compromise')],[F('toll_policy_debate','absent')]],**{'from':dict(year=733,month=1),'until':dict(year=733,month=12,day=30,period=2)})
define('TB-C05',['대응 회의에 참석한다','회의에 가지 않는다'],[[F('subjugation_policy','attend')],[]],**{'from':dict(year=735,month=1),'until':dict(year=735,month=3,day=30,period=2)},priority=100,expire=[F('subjugation_policy','absent'),F('dalgaeul_735_side','neutral'),F('yunga_subjugation_vote','participate')],expire_text='강산이 없는 자리에서 각 세력은 토벌에 대한 입장을 정했다.')
es['TB-C05']['nodes']['result1']['next']='DEFER'
choice('TB-C06',[[F('taebaek_succession','support')],[F('taebaek_succession','self')],[F('taebaek_succession','neutral')]],**{'from':dict(year=736,month=1)})
define('AG-01',['샛길을 찾는다','돌아간다'],[[F('fogpass_shortcut')],[]],[{'ap':1},{}])
choice('AG-R02',[[F('refugee_family_saved'),M('refugees_rescued',1),M('population',3)],[E('gold',12),M('civilian_harm',1)],[E('intel',1)],[]])
flags('AG-C01',['fogpass_secret_route'],conditions=[V('my_companion')])
choice('AG-C02',[[F('fake_solbaram_resolved'),E('mercy',5)],[F('fake_solbaram_resolved'),E('mercy',2)],[F('fake_solbaram_resolved'),E('gold',25),E('fear',8)],[E('mercy',-5)]],conditions=[C('mercy',30,'gte')],**{'from':dict(year=733,month=1),'until':dict(year=734,month=12,day=30,period=2)})
define('AG-C03',['정보를 산다','돌아간다'],[[E('intel',2),F('haomun_contact_open')],[]],[{'gold':10},{}],conditions=[C('regional.factions.haomun',30,'gte')],repeatable=True,cooldown_days=10)
define('DG-01',['외교와 통행권을 논의한다','돌아간다'],[[fac('dal',3),F('dalgaeul_first_meeting')],[]],[{'ap':1},{}])
define('DG-02',['대련한다','돌아간다'],[[E('training',3),fac('dal',1)],[]],[{'ap':1},{}],conditions=[C('regional.factions.dal',0,'gte')])
flags('DG-C01',['dalgaeul_first_meeting'],**{'from':dict(year=732,month=3),'until':dict(year=732,month=5,day=30,period=2)})
flags('DG-C02',['dalgaeul_maegol_known'],conditions=[C('flags.maegol_complete')])
flags('DG-C03',['dalgaeul_joint_route'],conditions=[C('regional.factions.dal',30,'gte')])
flags('DG-C04',['dalgaeul_road_dispute'],conditions=[C('regional.factions.dal',-30,'lte')])
report('DG-C05','달개울채는 지난 관계를 바탕으로 입장을 정했다.',when(C('regional.factions.dal',30,'gte'),[F('dalgaeul_735_side','ally')])+when(C('regional.factions.dal',-30,'lte'),[F('dalgaeul_735_side','enemy')])+when([C('regional.factions.dal',-29,'gte'),C('regional.factions.dal',29,'lte')],[F('dalgaeul_735_side','neutral')]),**{'from':dict(year=735,month=1)})
define('DN-01',['배를 타고 강가를 돌아본다','돌아간다'],[[E('health',10)],[]],[{'ap':1},{}])
define('DN-02',['짐을 맡긴다','맡긴 짐을 찾는다'],[[F('cargo_stored')],[F('cargo_stored',False)]])
choice('DN-R01',[[E('mercy',5)],[E('mercy',2)],[]],[{'ap':1},{'gold':5},{}])
choice('DN-R03',[[item('river_box')],[E('mercy',3)],[item('scrap',2)],[]])
report('DN-C01','장맛비로 나루의 수위가 높아졌다. 강가를 지날 때 조심해야 한다.',[F('river_flood'),E('regional.locations.ferry.risk',10)],conditions=[{'op':'month_in','value':[6,7,8]}],yearly=True,repeatable=True,cooldown_days=300)
flags('DN-C03',['river_stockade_contact'],conditions=[C('flags.suro_contact')])
flags('DN-C04',['river_trade_war'],**{'from':dict(year=734,month=1)})
report('HD-01','현재 표행과 산길 정보를 확인했다.',[],report='rumors')
define('HD-02',['표행 의뢰를 받는다','돌아간다'],[[E('gold',18),fac('escort',3)],[]],[{'ap':1,'rice':5},{}],conditions=[C('regional.factions.escort',20,'gte')])
choice('HD-R01',[[E('gold',12),fac('escort',3)],[E('gold',8),fac('escort',2)],[]],[{'ap':1},{'rice':5},{}])
choice('HD-R02',[[E('intel',1)],[E('gold',8)],[]],[{'ap':1},{},{}])
choice('HD-C01',[[F('escort_testimony','truth'),fac('escort',10)],[F('escort_testimony','partial'),fac('escort',3)],[F('escort_testimony','deny'),fac('escort',-5)]],conditions=[C('flags.prologue_complete')])
choice('HD-C02',[[F('jinyemyeong_relic_result','returned'),fac('escort',10),item('jinyemyeong_relic',-1)],[F('jinyemyeong_relic_result','kept')],[F('jinyemyeong_relic_result','lie'),fac('escort',-5)]],conditions=[C('regional.items.jinyemyeong_relic',1,'gte')])
flags('HD-C03',['escort_info_exchange'],conditions=[C('regional.factions.escort',20,'gte')])
flags('HD-C04',['escort_greenwood_treaty'],conditions=[C('regional.factions.escort',40,'gte')],**{'from':dict(year=733,month=1)})
flags('HD-C05',['escort_new_route'],**{'from':dict(year=734,month=1)})
define('CH-01',['약초를 찾는다','돌아간다'],[[item('herb')],[]],[{'ap':1},{}])
define('CH-02',['집터를 살핀다','집을 짓는다','돌아간다'],[[F('cheonghak_site')],[F('cheonghak_house')],[]],[{'ap':1},{'regional.vars.wood':20,'gold':20},{}])
flags('CH-R01',['cheonghak_spring'],repeatable=False)
choice('CH-R02',[[E('mercy',3)],[E('rice',10)],[]],[{'regional.items.herb':1},{'ap':1},{}])
choice('CH-R03',[[F('abandoned_hut'),F('cheonghak_house')],[F('cheonghak_site')],[]],[{'regional.vars.wood':10},{},{}],repeatable=False)
choice('CH-C01',[[F('home_cheonghak'),dict(op='home',value='crane')]],[{'ap':1}],conditions=[C('flags.cheonghak_house')])
choice('CH-C03',[[F('cheonghak_settlement'),E('regional.locations.crane.population',5),M('population',-5)],[],[]],conditions=[V('population',25,'gte')])
define('JS-01',['목재를 모은다','돌아간다'],[[M('wood',10)],[]],[{'ap':1},{}])
define('JS-02',['동굴을 조사한다','돌아간다'],[[E('intel',1)],[]],[{'ap':1},{}],conditions=[C('flags.abandoned_mine')])
choice('JS-R01',[[F('small_fire',False),F('saved_jeoksong')],[F('small_fire',False),F('saved_jeoksong')],[F('small_fire'),dict(op='schedule',value='JS-C02',days=1)]],[{'ap':1},{'rice':8},{}])
choice('JS-R02',[[E('fear',1)],[E('gold',8)],[M('population',1)],[]])
flags('JS-R03',['abandoned_mine'],repeatable=False)
define('JS-C01',['벌목대를 편성한다','미룬다'],[[M('wood',35)],[]],[{'ap':1,'rice':10},{}],conditions=[V('wood',10,'lte'),C('flags.construction_planned')])
define('JS-C02',['대형 산불을 끈다','사람부터 대피시킨다','방치한다'],[[F('great_fire_result','extinguished'),F('small_fire',False)],[F('great_fire_result','evacuated'),F('small_fire',False)],[]],[{'ap':1,'rice':10},{'ap':1},{}],conditions=[C('flags.small_fire')],duration_days=2,priority=100,expire=[F('great_fire_result','damage'),F('small_fire',False),M('wood',-20),E('mercy',-5)],expire_text='산불이 번져 목재와 주민의 신뢰를 잃었다.')
es['JS-C02']['nodes']['result2']['next']='DEFER'
flags('JS-C03',['saved_jeoksong'],conditions=[{'any':[C('flags.great_fire_result','extinguished'),C('flags.great_fire_result','evacuated')]}])
flags('JS-C04',['true_clue_mine_01'],conditions=[C('flags.abandoned_mine')],**{'from':dict(year=734,month=1)})
report('GM-02','관문의 수배지를 살폈다.',[],report='wanted')
choice('GM-R02',[[],[E('fear',2)],[]],[{'gold':5},{},{'ap':1}])
choice('GM-R03',[[E('gold',10)],[E('fear',5)],[]])
flags('GM-C01',['gate_alert'],conditions=[C('fear',50,'gte')],repeatable=True,cooldown_days=10)
flags('GM-C02',['gate_identity_shared'],conditions=[C('regional.factions.yunga',-40,'lte')])
choice('GM-C03',[[E('intel',2)],[fac('yunga',-10)],[F('gate_patrol_avoided')],[E('intel',1)]],**{'from':dict(year=735,month=1)},priority=100)
flags('GM-C04',['outside_factions_arrived'],**{'from':dict(year=737,month=1)})
define('YG-01',['윤가 사람과 이야기를 나눈다','돌아간다'],[[fac('yunga',2)],[]],[{'ap':1},{}],conditions=[C('regional.factions.yunga',-30,'gte')])
define('YG-02',['대련을 신청한다','돌아간다'],[[E('training',3)],[]],[{'ap':1},{}],conditions=[C('regional.factions.yunga',0,'gte')])
choice('YG-R01',[[],[fac('yunga',-2)],[E('training',1)],[fac('yunga',1)]])
choice('YG-C01',[[F('yunga_first_assessment','cooperate'),fac('yunga',5)],[F('yunga_first_assessment','hidden')],[F('yunga_first_assessment','hostile'),fac('yunga',-5)]],conditions=[C('flags.kangsan_registered')],**{'from':dict(year=732,month=3),'until':dict(year=732,month=5,day=30,period=2)})
flags('YG-C02',['yunga_moderates'],conditions=[V('civilian_harm',0,'lte'),C('mercy',30,'gte')])
flags('YG-C03',['yunga_hardliners'],conditions=[C('fear',40,'gte')])
flags('YG-C04',['yunga_trade_war'],**{'from':dict(year=734,month=1)})
choice('YG-C05',[[F('yunga_subjugation_vote','negotiate')],[F('yunga_subjugation_vote','hostile')],[F('yunga_subjugation_vote','enemy')],[F('yunga_subjugation_vote','moderate')]],**{'from':dict(year=735,month=1)},priority=100)
flags('YG-C06',['yunga_greenwood_cooperation'],conditions=[C('regional.factions.yunga',30,'gte'),C('owned',3,'count_gte')])

# Three core condition-only companion options, always hidden when their real condition fails.
for id,label,conditions,effects in [
 ('BU-R03','마영란에게 주변 발자국을 보게 한다',[V('my_companion')],[E('intel',2),F('my_ambush_detected')]),
 ('AG-R02','마영란에게 추격자의 수와 방향을 확인하게 한다',[V('my_companion')],[E('intel',2)]),
 ('BU-R01','기감으로 주위의 위험을 감지한다',[C('flags.gigam_unlocked')],[E('intel',1)])]:
    e=es[id];e['nodes']['special']=dict(type='result',text=label+'\n정보를 얻었다.',next='END')
    e['nodes']['entry']['choices'].append(dict(id='special',text=label,next='special',conditions=conditions,effects=effects))
d['defaults']['vars'].update(refugees_rescued=0,cheolma_searches=0)
d['defaults']['items'].update(herb=0,tools=0,fake_medicine=0,scrap=0,river_box=0,jinyemyeong_relic=0)
d['companion']['bonuses']={
 'sol':'발자국으로 침입·경비의 빈틈을 살핀다.','market':'소매치기와 미행 흔적을 살핀다.','iron':'사람이 남긴 야영 흔적을 찾는다.','white':'고개 주변 매복자의 흔적을 살핀다.','mist':'발자국을 따라 비밀 샛길을 찾는다.','dal':'사람들의 동선과 내부 불만을 살핀다.','ferry':'화물과 흘수선으로 밀수선을 살핀다.','guild':'발자국과 수레 자국으로 호송 경로를 분석한다.','crane':'사람과 짐승의 흔적을 구분한다.','red':'실종자와 도망자의 흔적을 추적한다.','exit_east':'순찰의 동선을 읽어 검문을 피한다.','clan':'군화 자국으로 병력 움직임을 살핀다.','tae':'사람들의 동선을 확인해 녹림 소문을 가려낸다.'}
d['balance_note']='문서에 없는 세부 수치(가격·회복량·평판 변화·기본 쿨다운)는 초도 플레이용 조정값. 원문 확정 수치와 구분해 편집 가능. 이벤트 원문은 source_registry.json에 전량 보존.'
path.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Configured',sum(e['status']!='pending' for e in es.values()),'playable/partial events of',len(es))
