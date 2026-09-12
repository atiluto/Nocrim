"""One-time adaptation of universe prose to an editable VN script. Do not rerun over edits."""
from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[1]
source=(R/'universe/09_웹소설형_시나리오.md').read_text(encoding='utf-8')
out=R/'scenario/chapters/00_프롤로그/common'
out.mkdir(parents=True,exist_ok=True)
speakers={
1:['강산'],2:['강산','박달수','강산','조만식','조만식','강산','조만식','박달수','강산','최억칠','강산'],
3:['강산']*4,4:['마을 사람','강산','나무꾼','강산'],
5:['매골채 산적','강산','매골채 산적','강산','매골채 산적','강산','매골채 산적','강산','강산','강산','강산'],
6:['도망친 사람','강산','추격자','강산','추격자','강산','추격자','강산','강산','도망친 사람','강산','도망친 사람','강산','강산'],
7:['마웅철','강산','붙잡힌 산적','강산','붙잡힌 산적','강산','붙잡힌 산적','강산','붙잡힌 산적','강산','강산','붙잡힌 산적','강산','붙잡힌 산적','강산'],
8:['강산','강산','포로','강산','강산','강산'],
9:['강산','마웅철','강산','마웅철','강산','마웅철','강산','강산','강산'],10:['강산']*4,11:['강산']*2}
music={1:'rain_on_the_wandering_cart',2:'bgm_murim_survival',3:'rain_on_the_wandering_cart',4:'night_market_whispers',5:'bgm_murim_survival',6:'bgm_murim_survival',7:'bgm_broker_deal',8:'bgm_murim_survival',9:'bgm_murim_survival',10:'bgm_inn_rebuild',11:'bgm_inn_afterhours'}
bg={1:'room',2:'road',3:'hut',4:'village',5:'hut',6:'road',7:'stockade',8:'stockade',9:'stockade',10:'hut',11:'camp'}
files=[]
for section in re.split(r'(?m)^# 프롤로그 ',source)[1:]:
    heading,body=section.split('\n',1); n=int(heading.split(' — ')[0]); title='프롤로그 '+heading.strip()
    body=body.split('# 이후 장편 진행 메모')[0]
    # Keep the outcome intentionally nonspecific; no battle call or invented fate.
    body=re.sub(r'`\(게임 전투 돌입\)`.*?싸움이 끝났을 때', '비탈과 나무뿌리를 붙잡고 버틴 끝에, 나는 마웅철을 쓰러뜨렸다.\n\n포로 여섯 명은 매골채를 벗어났다. 무기를 버린 사람들은 쫓지 않았다.\n\n싸움이 끝났을 때',body,flags=re.S)
    paragraphs=[p.strip().replace('`','') for p in re.split(r'\n\s*\n',body) if p.strip() and p.strip()!='---']
    beats=[]; d=0; current_bg=bg[n]; current_music='bgm/'+music[n]+'.mp3'; ambience=''
    if n in [2,6,7,8,9]: ambience='sfx/amb_mountain_morning_loop_01.mp3'
    if n==4: ambience='sfx/amb_foothill_village_day_loop_01.mp3'
    for p in paragraphs:
        speaker='독백'; effect=''; sfx=''
        if p.startswith('"') and p.endswith('"'):
            speaker=speakers[n][d]; d+=1; p=p[1:-1]
        if n==1 and p=='그래서 산으로 갔다.': current_bg='road'
        if n==1 and p=='그날도 비가 왔다.': current_bg='rain'; ambience='sfx/amb_rain_mountain_loop_01.mp3'
        if '세상이 꺼졌다.' in p: effect='blackout'; ambience=''; current_music=''
        if '난간이 부러졌다.' in p: effect='shake'; sfx='sfx/sfx_wooden_mechanism_smash_01.wav'
        if '기억이 한꺼번에 들어왔다.' in p: effect='flash'; sfx='sfx/sfx_memory_surge_01.wav'
        if p in ['칼이 부딪쳤다.','도와 검이 부딪쳤다.']: effect='shake'; sfx='sfx/metal_01.wav'
        if '나는 낡은 집 안에 서 있었다.' in p: current_bg='hut'; effect='flash'; sfx='sfx/portal_whoosh.wav'; ambience=''; current_music='bgm/rain_on_the_wandering_cart.mp3'
        if n==3 and p=='새벽이 되자 나는 다시 산길로 내려갔다.': current_bg='road'; ambience='sfx/amb_mountain_morning_loop_01.mp3'
        if n==3 and p=='나는 하루 종일 땅을 팠다.': sfx='sfx/sfx_grave_soil_drop_01.wav'
        if n==3 and p=='솔바람채로 돌아온 뒤 낡은 책을 뒤졌다.': current_bg='hut'; ambience=''; sfx='sfx/paper_01.wav'
        if n==4 and p=='나는 같은 길을 몇 번이나 오르내렸다.': current_bg='road'; ambience='sfx/amb_mountain_morning_loop_01.mp3'; effect='walk'
        if n==4 and p=='그날 솔바람채로 돌아왔을 때 낯선 발자국을 발견했다.': current_bg='hut'; ambience=''
        if '댕댕댕댕!' in p: effect='shake'; sfx='sfx/metal_01.wav'
        if p=='문을 달았다.': sfx='sfx/sfx_handsaw_wood_short_01.wav'
        if p=='문이 닫혔다.': sfx='sfx/sfx_wooden_door_bolt_lock_01.wav'
        if p in ['세상이 뒤집혔다.','눈앞이 바뀌었다.']: effect='flash'; sfx='sfx/portal_whoosh.wav'; current_music='bgm/bgm_return_ritual.mp3'
        if p=='눈이 번쩍 떠졌다.': effect='jump'; sfx='sfx/sfx_memory_surge_01.wav'
        if speaker!='독백' and p in ['누구세요?','아. 잠깐만.','태현아! 정신 차려!','어?','일단 뛰어요!']: effect='jump'
        if speaker=='마웅철': sprite='mawung'
        elif speaker not in ['독백','강산']: sprite='extra'
        else: sprite=''
        row={'text':p,'speaker':speaker,'background':current_bg,'music':current_music,'ambience':ambience,'sprite':sprite,'side':'left' if speaker in ['도망친 사람','포로','나무꾼','마을 사람','조만식'] else 'right','sfx':sfx,'effect':effect}
        # Merge quiet narrative paragraphs into screen-sized beats, preserving their wording.
        if beats and speaker=='독백' and not effect and not sfx and beats[-1]['speaker']=='독백' and all(beats[-1][k]==row[k] for k in ['background','music','ambience','effect','sfx']) and len(beats[-1]['text'])+len(p)<150:
            beats[-1]['text']+='\n'+p
        else: beats.append(row)
    assert d==len(speakers[n]),(n,d)
    filename=f'P{n:02d}_'+heading.split(' — ')[1].strip().replace('?','')+'.md'
    path=out/filename
    if path.exists(): raise RuntimeError('Refusing to overwrite '+str(path))
    lines=['# '+title,'','공통 루트 · 선택 분기 없음 · 원작: universe/09_웹소설형_시나리오.md','']
    for i,b in enumerate(beats,1):
        lines+=['### '+f'P{n:02d}-{i:03d}']
        for kr,en in [('화자','speaker'),('배경','background'),('인물','sprite'),('위치','side'),('음악','music'),('환경음','ambience'),('효과음','sfx'),('연출','effect')]: lines.append(kr+': '+b[en])
        lines+=['','대사:',b['text'],'']
    path.write_text('\n'.join(lines),encoding='utf-8')
    files.append(path.relative_to(R/'scenario').as_posix())
(R/'scenario/manifest.json').write_text(json.dumps({'chapters':files},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Prepared 11 chapters')
