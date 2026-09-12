# 천마객잔 BGM·SFX 파일별 프롬프트와 분위기

## 문서 목적

천마객잔에서 정의한 음원을 다른 비주얼노벨·게임 프로젝트에서도 재사용할 수 있도록 파일명, 생성 프롬프트, 청감, 활용 장면을 한곳에 정리했다.

현재 오디오 정의 기준:

- BGM 23곡
- 반복 환경음 7개
- 반복 상황용 SFX 11세트 × 4변형 = 44개
- 단발 SFX 12개
- 총 86개 파일

반복 SFX의 `01~04`는 동일한 프롬프트를 한 번 실행했을 때 나온 네 가지 결과를 변형본으로 저장한 것이다. 따라서 프롬프트는 세트별로 같고, 실제 파일마다 음높이·세기·길이·질감이 조금씩 다르다.

## 파일 형식

- BGM: `.mp3` 우선. 기존 6곡은 `.ogg`도 호환 가능
- 환경음·SFX: 편집용 원본은 `.wav` 권장
- 현재 게임 코드에서 환경음·SFX는 `.wav`를 참조
- 다른 엔진에서 용량을 줄일 때는 원본 WAV를 보관하고 배포본만 OGG로 변환

## 공통 생성 규칙

### Suno BGM

- Instrumental: On
- 권장 길이: 2분 10초~3분
- 시작 5초 안에 분위기가 드러나게 생성
- 대사 아래에서 쓰므로 중저역·타악기·주선율을 과도하게 키우지 않음
- 게임 적용 음량 권장: 약 `-18 LUFS`, 피크 `-1 dBTP` 이하
- 마지막 종지나 긴 페이드아웃보다 처음으로 자연스럽게 돌아가는 구조 선택

신규 17곡 공통 제외 문구:

```text
No vocals, no singing, no choir, no humming, no vocal chops, no spoken words, no lyrics, no cinematic trailer boom, no abrupt ending, no long silent intro, no excessive sub bass. Dialogue-friendly instrumental game BGM with a loopable ending.
```

### ElevenLabs 환경음·SFX

- 환경음: Duration 30초, Looping On, Prompt Influence 35~45%
- 반복 SFX: Looping Off, Prompt Influence 45~60%
- 단발 SFX: Looping Off, Prompt Influence 50~65%
- 효과음에 음악이나 음성이 섞이면 프롬프트 끝에 `No music, no voice`를 강조

---

# 1. BGM 23곡

## 1-1. `bgm_inn_warm.mp3` 또는 `bgm_inn_warm.ogg`

- 역할: 전통풍 찻집의 기본 일상 테마
- 느낌: 따뜻한 나무 실내, 잔잔한 오후, 소소한 유머. 졸리지는 않지만 대사를 방해하지 않는 편안함
- 활용: 가게 영업, 차 준비, 손님과의 일상 대화, 연구, 영업 종료 전 휴식
- 핵심 악기: 가야금 계열 현, 대금·피리 계열 목관, 펠트 피아노, 부드러운 타악기

```text
Instrumental Korean fantasy tea-house slice-of-life game BGM, 84 BPM, warm and intimate, gentle plucked zither resembling gayageum, soft bamboo flute, felt piano, brushed hand percussion, warm rounded bass and subtle modern ambient pads. Calm pentatonic melody, cozy afternoon atmosphere, light dry humor, unobtrusive under dialogue. Loop-friendly A-B-A form, restrained dynamics, no opening fanfare, no dramatic climax, ending texture should naturally reconnect to the opening.
```

Exclude:

```text
vocals, choir, spoken word, lyrics, aggressive drums, EDM drops, rock guitar, trailer music, heroic fanfare, loud mastering, abrupt ending, dramatic finale
```

## 1-2. `bgm_murim_ritual.mp3` 또는 `bgm_murim_ritual.ogg`

- 역할: 무협 세계의 의식·진법 기본 테마
- 느낌: 차갑고 넓은 석실, 오래된 의식의 무게. 사악한 공포보다 정교하고 엄숙한 준비 과정
- 활용: 지하전각, 봉인고, 의식 준비, 고대 장치 조사, 조용한 결심
- 핵심 악기: 거문고 계열 저현, 숨소리 섞인 피리, 낮은 북, 청동 종, 저음 현악

```text
Instrumental dark martial-arts fantasy ritual BGM, 66 BPM, solemn underground stone chamber, low geomungo-like plucked strings, breathy bamboo flute, restrained temple drum, distant bronze ritual bells, low bowed strings and a very subtle atmospheric drone. Ancient and mysterious but not evil, methodical preparation and quiet determination, spacious stone reverb, sparse melody, dialogue-friendly mix. Slow circular structure designed for looping, no large crescendo and no final cadence.
```

Exclude:

```text
vocals, chanting, choir, lyrics, horror screams, huge orchestra, taiko spectacle, heroic battle music, modern dance beat, guitar, abrupt ending, final cymbal crash
```

## 1-3. `bgm_portal_crisis.mp3` 또는 `bgm_portal_crisis.ogg`

- 역할: 차원 이상·게이트 위기의 기본 테마
- 느낌: 공간이 비틀리고 안정성이 무너지는 압박감. 긴급하지만 예고편처럼 과장되지 않음
- 활용: 차원문 가동, 게이트 사고, 공간 균열, 이동 실패, 위기 직전
- 핵심 악기: 저음 신스, 첼로 펄스, 역재생 현, 금속 타악, 불협화 종

```text
Instrumental Korean fantasy and modern sci-fi tension BGM, 96 BPM, unstable dimensional portal, pulsing low synth and cellos, reversed plucked zither textures, metallic ritual percussion, dissonant crystalline bells, restrained sub-bass heartbeat and spatial static. Urgent supernatural pressure without becoming a trailer anthem, continuous tension under dialogue, evolving layers but no explosive climax. Seamless loop-friendly form with no clean resolution, no intro hit and no final impact.
```

Exclude:

```text
vocals, choir, lyrics, dubstep drop, heroic brass, cinematic braam, huge explosion, rock drums, horror shrieks, triumphant resolution, fadeout, final hit
```

## 1-4. `bgm_modern_discovery.mp3` 또는 `bgm_modern_discovery.ogg`

- 역할: 현대 문물을 처음 접하는 장면의 기본 테마
- 느낌: 호기심, 산뜻한 도시감, 약한 코미디. 어린아이 같은 귀여움보다 유능한 어른의 낯선 적응
- 활용: 도시 탐색, 스마트폰·편의점·게임·음식 체험, 새로운 일상 발견
- 핵심 악기: 펠트 피아노, 마림바 계열 플럭, 가야금 포인트, 림클릭, 가벼운 신스

```text
Instrumental modern urban slice-of-life game BGM with a subtle Korean fantasy accent, 104 BPM, curious and lightly comedic. Bright felt piano, marimba-like plucks, gentle gayageum accents, clean bass, soft rim clicks and small electronic percussion, airy synth pads. A capable martial artist discovering ordinary modern technology, amused rather than childish, energetic but comfortable under dialogue. Repeating four-bar motifs, smooth loopable structure, restrained dynamics, no big chorus and no final cadence.
```

Exclude:

```text
vocals, lyrics, cute anime vocals, slapstick cartoon sounds, hyperpop, EDM drop, heavy drums, rock guitar, orchestral climax, dramatic ending, fadeout
```

## 1-5. `bgm_bureau_investigation.mp3` 또는 `bgm_bureau_investigation.ogg`

- 역할: 기관 조사·잠입의 기본 테마
- 느낌: 형광등 아래의 건조한 긴장, 조용한 두뇌전, 약간의 행정적 유머
- 활용: 관리기관, 기록실, 비공식 검사, 신분 조사, 야간 잠입
- 핵심 악기: 뮤트 피아노, 아날로그 신스 펄스, 틱 타악, 유리질 말렛

```text
Instrumental understated supernatural investigation game BGM, 76 BPM, modern government bureau at night. Muted felt piano, low analog synth pulses, soft ticking percussion, restrained electronic bass, glassy mallet accents and distant air-conditioning-like pads. Intelligent stealth and quiet problem solving with a trace of dry comedy, not horror and not action. Minimal melody, spacious clean mix for dialogue, subtle evolving texture, seamless loop-friendly form with no reveal sting or final resolution.
```

Exclude:

```text
vocals, lyrics, choir, detective jazz saxophone, horror drones, action drums, trailer hits, heroic orchestra, EDM, bright pop chorus, abrupt ending, final sting
```

## 1-6. `bgm_seoyun.mp3` 또는 `bgm_seoyun.ogg`

- 역할: 편안한 성인 로맨스의 기본 테마
- 느낌: 차를 사이에 둔 조용한 호감, 따뜻함, 낯가림이 조금씩 풀리는 분위기
- 활용: 첫 만남, 회복, 단골이 되는 과정, 평범한 대화 속의 호감
- 핵심 악기: 펠트 피아노, 부드러운 피리, 가야금 플럭, 실내악 현, 브러시

```text
Instrumental gentle slow-burn romance game BGM, 80 BPM, warm and quietly hopeful. Delicate felt piano, soft bamboo flute, light gayageum plucks, intimate chamber strings, brushed percussion and a faint modern ambient pad. Two adults becoming comfortable through tea and ordinary conversation, shy chemistry without melodrama, tender but still playful. Sparse memorable motif, warm close production, unobtrusive under dialogue, smooth A-B-A loop with restrained emotion and no grand romantic climax.
```

Exclude:

```text
vocals, lyrics, choir, sentimental power ballad, sweeping orchestra, dramatic violin solo, wedding music, heavy drums, pop chorus, sad breakup mood, abrupt ending, fadeout
```

## 1-7. `bgm_inn_morning.mp3`

- 역할: 밝은 개점·출근 테마
- 느낌: 햇빛이 드는 아침, 아직 바쁘기 전의 산뜻함, 능숙하게 하루를 여는 기분
- 활용: 기상, 출근, 개점 준비, 첫 손님 전

```text
Warm morning slice-of-life instrumental for a modern Korean urban-fantasy visual novel. Light acoustic guitar, soft upright piano, brushed percussion, subtle wooden flute and delicate tea-cup-like mallet accents. Relaxed but awake, a capable shop owner preparing a traditional tea house across from a busy government bureau. 92 BPM, gentle four-note main motif, clean arrangement, cozy daylight, mild dry humor, no sentimentality. Seamless loop feeling.
```

## 1-8. `bgm_inn_busy.mp3`

- 역할: 손님이 몰리는 영업 테마
- 느낌: 분주하지만 통제되는 활기, 손님 응대의 빠른 템포, 짧은 코미디 타이밍
- 활용: 주문 러시, 여러 손님의 반응, 영업 몽타주

```text
Playful busy tea-house instrumental for a Korean urban-fantasy visual novel. Pizzicato strings, muted acoustic guitar, light hand percussion, marimba and short woodwind replies. 112 BPM, nimble customer-service rhythm, friendly controlled bustle rather than chaos, small comedic pauses, same four-note motif as the calm tea-house theme but faster. Dialogue-friendly, no big climax, loopable.
```

## 1-9. `bgm_inn_afterhours.mp3`

- 역할: 영업 종료 후의 밤 테마
- 느낌: 가게에 혼자 남은 편안함과 희미한 그리움. 슬픔보다 긴 하루 뒤의 안정
- 활용: 마감, 야간 연구, 간식·요리, 조용한 회상

```text
Quiet after-hours tea-house instrumental at night. Felt piano, warm nylon guitar harmonics, soft electric piano, sparse brushed percussion and a distant low city hum translated into music. 72 BPM, intimate and restful, wooden interior lit by streetlight, a man quietly enjoying ordinary modern life after twenty violent years. Slightly wistful but not sad, restrained four-note tea-house motif, loopable ending.
```

## 1-10. `bgm_gate_history.mp3`

- 역할: 과거 게이트 사태를 설명하는 기록·몽타주 테마
- 느낌: 재난 기록물처럼 진중하며, 혼란에서 대응 체계가 잡혀 가는 흐름
- 활용: 역사 설명, 군 대응, 각성자 등장, 뉴스·기록 컷씬

```text
Documentary-like historical montage score for a Korean hunter-world visual novel. Measured low strings, restrained military snare, muted brass, glassy synth pulses and a slowly rising piano ostinato. 88 BPM. Move from public confusion to organized resistance and cautious victory without becoming a heroic trailer. Serious textbook-history atmosphere, clear space for spoken explanation, modular sections that can loop.
```

## 1-11. `bgm_childhood_departure.mp3`

- 역할: 어린 시절의 출발과 불안 테마
- 느낌: 평범한 낮 풍경에 자존심과 열등감, 작은 불길함이 서서히 스며듦
- 활용: 어린 시절 회상, 이동, 사고 직전, 가족과의 이별

```text
Introspective childhood departure music for a visual novel. Soft piano, muted acoustic guitar, distant vibraphone and a gentle bus-like rhythmic pulse. 76 BPM. A proud eight-year-old boy hides insecurity and repeats that he will return home after becoming first in class. Ordinary daylight with unease slowly entering at the edges. Vulnerable but not melodramatic, no horror stinger, loopable.
```

## 1-12. `bgm_murim_survival.mp3`

- 역할: 낯선 무협 세계의 생존 테마
- 느낌: 거친 숲, 추격의 공포, 경계심이 결의로 바뀌는 과정
- 활용: 이계 도착, 도주, 추적, 초기 생존, 힘의 공명

```text
Dark martial-arts survival instrumental. Sparse guqin plucks, low xiao flute breaths, hand drum heartbeat, bowed low strings and subtle black-red ambient drones. 84 BPM. A stranded child learns that the world's qi resonates with his power while being hunted by impossibly fast human martial artists. Fear gradually turns into alert determination. Raw wilderness, no triumphant melody, dialogue-friendly loop.
```

## 1-13. `bgm_murim_ascension.mp3`

- 역할: 무림에서의 성장·제패 몽타주 테마
- 느낌: 검고 강한 전진감, 승리의 도취를 절제한 위엄, 위험한 자신감
- 활용: 세력 재건, 장기 수련, 결전 몽타주, 강자로 자리 잡는 과정

```text
Grand but restrained dark-wuxia ascension theme. Deep frame drums, guqin, xiao, low strings and controlled distorted bass texture. 96 BPM. A wandering survivor becomes the Heavenly Demon after years of battle, with dangerous exhilaration hidden beneath calm confidence. Powerful forward motion without choir or bombastic trailer hits. Include a memorable descending four-note martial motif and a loopable cadence.
```

## 1-14. `bgm_return_ritual.mp3`

- 역할: 반복된 귀환 실험과 의식 테마
- 느낌: 지친 연구자의 익숙한 손놀림, 정밀한 기하학, 이번에는 성공할지도 모른다는 기대
- 활용: 진법 배치, 재료 점검, 반복 실험, 의식 개시

```text
Occult research-and-ritual instrumental for a dimensional return attempt. Metallic bowl resonance, low plucked strings, ticking wooden percussion, glass harmonics and restrained dark synth. 80 BPM. Methodical preparation after twenty failed attempts, mild tired humor turning into genuine anticipation. Ancient martial ritual with precise mechanical geometry. No explosive climax; tension must sustain under dialogue and loop naturally.
```

## 1-15. `bgm_modern_comedy.mp3`

- 역할: 현대 적응 코미디 전용 테마
- 느낌: 유능한 강자가 사소한 현대 기계 앞에서 고생하는 건조하고 따뜻한 웃음
- 활용: 미용실, 스마트폰, 전자레인지, 에스컬레이터, 오락실

```text
Light modern fish-out-of-water comedy instrumental for a Korean visual novel. Clean electric piano, muted funk guitar, soft synth plucks, compact drums and occasional marimba answers. 104 BPM. A terrifying martial master quietly struggles with touchscreens, envelopes, microwaves and moving stairs, then becomes competitive over arcade games. Clever and warm, never slapstick or childish, loopable.
```

## 1-16. `bgm_research_night.mp3`

- 역할: 심야 연구·검색 테마
- 느낌: 값싼 방 안에서 이어지는 조용한 집중, 작은 실패와 희망의 반복
- 활용: 자료 검색, 진법 재현, 분석, 잠 못 드는 연구

```text
Late-night dimensional research instrumental. Felt piano ostinato, soft analog synth arpeggio, glass taps, low cello and a faint clock-like pulse. 78 BPM. Quiet concentration in a cheap motel room, repeated experiments, small flashes of hope and frustration. Mysterious but not frightening, modern science meeting ancient formation diagrams, lots of room for narration, seamless loop.
```

## 1-17. `bgm_broker_deal.mp3`

- 역할: 회색지대 중개인·거래 테마
- 느낌: 서로를 재는 공손한 대화, 고급스러운 긴장, 차갑지만 악하지 않은 분위기
- 활용: 비공식 거래, 계약, 신분 마련, 희귀품 감정

```text
Stylish underground broker instrumental for an urban-fantasy visual novel. Dry bass guitar, brushed jazz drums, muted piano chords, subtle synth pulses and a faint plucked-string accent. 94 BPM. Polite conversation where both men are quietly evaluating each other, expensive minerals behind glass, legal gray areas, confident dry humor. Cool rather than sinister, no noir saxophone solo, loopable.
```

## 1-18. `bgm_inn_rebuild.mp3`

- 역할: 가게 공사·창업 진행 테마
- 느낌: 하나씩 자기 공간이 완성되는 희망, 손으로 만드는 성취감, 약한 자부심
- 활용: 공사, 가구 선택, 메뉴 시험, 간판·가게 이름 결정

```text
Hopeful workshop-and-rebuilding instrumental for a modern tea-house visual novel. Acoustic guitar, upright piano, light hand percussion, wooden mallets and restrained flute. 98 BPM. Selecting dark wood, testing tea leaves, arguing over design details and slowly creating a place that feels like home. Warm progress with a small proud comedic streak. Develop the tea-house four-note motif into a fuller melody, loopable ending.
```

## 1-19. `bgm_seoyun_first.mp3`

- 역할: 히로인 첫 주문·첫인상 테마
- 느낌: 피곤한 성인 두 사람의 자연스러운 말장난, 밝은 호기심, 아직 작고 가벼운 호감
- 활용: 첫 만남, 첫 주문, 예상 밖 대화, 첫 관심

```text
Bright first-meeting romance instrumental for an adult Korean office-worker heroine. Clean piano, gentle acoustic guitar, soft bass, brushed drums and tiny glockenspiel accents. 96 BPM. Friendly tired woman enters expecting iced coffee and meets an oddly confident tea-house owner; quick natural banter, curiosity, and the first hint of attraction. Warm and mature, not sugary, no dramatic romance swell, loopable.
```

## 1-20. `bgm_seoyun_comfort.mp3`

- 역할: 단골이 된 뒤의 편안한 관계 테마
- 느낌: 말을 하지 않아도 어색하지 않은 사이, 직접 말하지 않는 걱정, 잔잔한 정서적 무게
- 활용: 재방문, 조용한 대화, 출근 전 차, 사고 후 안부

```text
Comfortable slow-burn relationship instrumental. Felt piano, nylon guitar, soft electric piano pad, light brushes and a small clarinet counterline. 80 BPM. Two adults have become comfortable enough to share silence, tease each other about tea, and worry without saying it directly. Reuse the first-meeting melody in a calmer, warmer arrangement. Gentle emotional weight, no confession climax, seamless loop.
```

## 1-21. `bgm_gate_expedition.mp3`

- 역할: 전문적인 던전 탐색 테마
- 느낌: 대형 액션보다 절제된 긴장, 거리와 진형을 확인하며 전진하는 숙련된 팀
- 활용: 게이트 진입, 폐허 탐색, 부산물 회수, 전투 전 경계

```text
Methodical dungeon-expedition instrumental for a modern hunter team. Tight low percussion, muted strings, pulsing synth bass, sparse piano notes and radio-like high texture. 102 BPM. Professionals advance through a ruined gray city, checking distance, communications and formation. Competence first, tension underneath, no constant action bombast. Maintainable loop for a long exploration scene.
```

## 1-22. `bgm_gate_mutation.mp3`

- 역할: 변칙 게이트·상위 개체 전투 테마
- 느낌: 안정되던 공간이 갑자기 붉게 중첩되는 고강도 위기, 전문팀조차 밀리는 압박
- 활용: 공간 변이, 난입, 상위 마물 전투, 은밀한 구출

```text
Escalating dimensional-mutation battle instrumental. Irregular low drums, aggressive cello ostinato, fractured glass synth, red-black bass pulses and short metallic impacts. 126 BPM. A stable C-rank gate suddenly overlaps with a hostile red world; the team fights professionally but is overwhelmed, then an unseen master intervenes with terrifyingly precise control. Urgent and dangerous without choir or trailer clichés, strong rhythm under dialogue, loopable high-tension ending.
```

## 1-23. `bgm_clue_afterglow.mp3`

- 역할: 전투 후 단서 발견 테마
- 느낌: 위기는 끝났지만 흔적은 남아 있는 상태. 희망, 불안, 지적 흥분이 동시에 존재
- 활용: 사고 현장 조사, 차원흔 발견, 과거 기록 검색, 귀환 가능성 확인

```text
Quiet mystery-afterglow instrumental for discovering a dimensional clue. Felt piano, glass harmonics, very soft cello, slow analog pulse and thin blue-red ambient textures. 70 BPM. The battle is over; a hand touches an old scar between worlds and realizes that a path never disappears completely. Hope, unease and intellectual excitement coexist. Subtle unresolved four-note motif, no horror, no final resolution, seamless loop.
```

---

# 2. 반복 환경음 7개

모든 환경음은 30초, Looping On으로 생성한다. 눈에 띄는 단발 사건이 섞인 결과보다 시작과 끝을 알아채기 어려운 결과를 고른다.

## 2-1. `amb_inn_room.wav`

- 느낌: 작은 나무 찻집의 따뜻하고 조용한 실내. 주전자와 환기음이 아주 낮게 깔림
- 활용: 객잔·찻집·카페의 평상시 실내
- 주의: 가까운 발걸음이나 문종이 들어가면 별도 SFX와 충돌함

```text
Seamless quiet ambience inside a small modern Korean tea house decorated like a traditional martial-arts inn. Faint kettle simmer, soft ventilation, subtle wood room tone, occasional very distant porcelain handling, muffled city movement through closed windows. Warm, calm, intimate and unobtrusive. No intelligible speech, no footsteps in the foreground, no door bell, no music, no dramatic events, no obvious beginning or ending.
```

## 2-2. `amb_city.wav`

- 느낌: 서울 도심의 지속적인 생활 소음. 활기차지만 혼잡하거나 공격적이지 않음
- 활용: 인도, 도심 이동, 건물 앞, 낮의 외부 장면
- 주의: 경적·사이렌처럼 반복할 때 티 나는 소리가 없는 결과 선택

```text
Seamless daytime ambience on a busy Seoul city sidewalk. Layered distant cars and buses, soft tire wash on dry asphalt, pedestrian presence as indistinct murmur, subtle building ventilation and occasional faraway crosswalk electronics. Modern and active but not crowded or harsh. No intelligible words, no close horn, no siren, no music, no prominent single event, no obvious start or end.
```

## 2-3. `amb_murim_hall.wav`

- 느낌: 넓고 차가운 지하 석실. 고요하지만 완전히 죽어 있지는 않은 오래된 공간
- 활용: 지하전각, 고대 유적, 의식실, 봉인된 회랑
- 주의: 공포 비명이나 마법 발동음이 없는 순수 공간음으로 선택

```text
Seamless ambience inside a vast underground stone ritual hall in a martial-arts fantasy fortress. Cold slow air moving through old corridors, faint torch flicker, deep stone room tone, occasional subtle settling dust and distant low resonance. Ancient, solemn and spacious, not overtly frightening. No voices, no chanting, no footsteps, no magic activation, no music, no thunder, no obvious beginning or ending.
```

## 2-4. `amb_bureau.wav`

- 느낌: 심야의 관공서·보안 사무실. 형광등과 서버, 공조기의 무기질적인 정적
- 활용: 관리기관, 기록실, 연구실, 야간 사무실
- 주의: 키보드나 엘리베이터처럼 자주 반복되면 눈에 띄는 소리를 피함

```text
Seamless ambience inside a modern government office and secure archive late at night. Soft HVAC hum, fluorescent electrical room tone, faint server ventilation, a very distant elevator mechanism and occasional subtle building creak. Sterile, controlled and quiet. No intelligible voices, no close footsteps, no alarm, no keyboard typing, no music, no prominent event, no noticeable start or finish.
```

## 2-5. `amb_motel_room.wav`

- 느낌: 오래된 소형 모텔방의 피곤하고 사적인 밤. 안전하지만 낡은 생활감이 있음
- 활용: 임시 거처, 여관, 값싼 방, 밤샘 연구
- 주의: 공포 장면이 아니라면 배관음과 냉장고 소리가 지나치게 음산한 결과는 피함

```text
Seamless nighttime ambience inside an older small Seoul motel room. Low air-conditioner fan, faint refrigerator hum, muted traffic through a closed window, subtle plumbing ticks and quiet room tone. Safe, tired and private rather than creepy. No television, no voices, no door knock, no phone, no music, no loud traffic, no distinct beginning or ending.
```

## 2-6. `amb_dungeon.wav`

- 느낌: 차갑고 비어 있는 암석 던전. 아직 적이 보이지 않지만 무엇인가 있을 듯한 절제된 위험
- 활용: 동굴, 던전, 게이트 내부, 지하 탐색
- 주의: 마물 울음과 전투음은 별도 SFX로 두고 환경음에는 넣지 않음

```text
Seamless ambience in a cold rocky dungeon beyond a dimensional gate. Slow cave airflow, distant water drips with natural stone reverb, low subterranean rumble and faint debris movement far away. Empty but potentially dangerous, spacious and restrained. No monster vocalization, no combat, no footsteps, no magic spell, no music, no jump scare, no obvious beginning or ending.
```

## 2-7. `amb_construction.wav`

- 느낌: 작은 상업 공간을 고치는 생산적인 공사음. 시끄러운 철거가 아니라 대화 가능한 실내 작업
- 활용: 인테리어 공사, 작업실, 가구 설치, 수리 몽타주
- 주의: 드릴이 계속 이어지는 결과는 대사를 덮으므로 피함

```text
Seamless indoor renovation ambience in a small commercial space. Distant measured hammering, occasional wood pieces being moved, light metal tool handling and a brief power drill far in the background, with natural empty-room reflections. Productive but not loud, suitable under dialogue. No workers speaking, no close impact, no continuous drill, no music, no abrupt event, no obvious beginning or ending.
```

---

# 3. 반복 상황용 SFX 44개

각 세트의 4개 파일은 아래 프롬프트를 한 번 생성해 나온 네 결과를 순서대로 저장한다. 같은 장면 안에서는 한 번호만 반복하지 말고 상황마다 01~04를 돌려 쓰면 기계적인 느낌이 줄어든다.

## 3-1. `door_chime_01.wav`, `door_chime_02.wav`, `door_chime_03.wav`, `door_chime_04.wav`

- 길이: 1.5초
- 느낌: 작고 따뜻한 황동 문종. 마법 효과가 아니라 실제 나무문이 움직이며 울리는 환영의 소리
- 활용: 찻집·여관·소형 상점의 입장
- 변형 차이: 음높이, 흔들린 세기, 잔향

```text
Isolated small brass bell mounted above the wooden entrance of a cozy traditional-style tea house. One natural door movement creates two or three light warm chimes with a short indoor wooden-room decay. Gentle and welcoming, not magical. Create natural variation in bell pitch, swing strength and decay. No door slam, no footsteps, no crowd, no voice, no music, clean game Foley one-shot.
```

## 3-2. `tea_pour_01.wav`, `tea_pour_02.wav`, `tea_pour_03.wav`, `tea_pour_04.wav`

- 길이: 1.8초
- 느낌: 작은 도자기 다관에서 찻잔으로 따르는 섬세하고 가까운 물소리
- 활용: 차·약탕·따뜻한 음료를 따르는 장면
- 변형 차이: 물줄기 속도, 작은 꿀렁임, 찻잔 공명

```text
Close-up game Foley of hot tea poured from a small ceramic teapot into a porcelain teacup. Delicate steady liquid stream, tiny natural glug, subtle ceramic resonance, then the stream stops cleanly. Create four realistic variations with slightly different pour speed and cup resonance. No kettle whistle, no cup placement, no hands or cloth noise, no voice, no music, isolated clean one-shot.
```

## 3-3. `cup_set_01.wav`, `cup_set_02.wav`, `cup_set_03.wav`, `cup_set_04.wav`

- 길이: 0.8초
- 느낌: 도자기 찻잔을 나무 카운터에 조심스럽게 놓는 맑고 작은 접촉음
- 활용: 차 서빙, 대화의 쉼표, 중요한 말을 하기 전 잔을 내려놓는 순간
- 변형 차이: 놓는 힘, 잔의 음높이, 나무 울림

```text
Close-up game Foley of a small porcelain teacup gently placed on a polished wooden tea-house counter. Crisp ceramic contact, a tiny secondary rattle and short warm room decay. Careful and refined, never a smash. Create four natural variations in placement force, cup pitch and wood resonance. No liquid pour, no saucer scraping, no voice, no music, isolated one-shot.
```

## 3-4. `device_beep_01.wav`, `device_beep_02.wav`, `device_beep_03.wav`, `device_beep_04.wav`

- 길이: 0.6초
- 느낌: 카드 단말기나 전자 도어록의 짧고 실용적인 승인음
- 활용: 결제, 출입 승인, 교통 게이트, 소형 단말기 성공
- 변형 차이: 음높이와 1~2회 비프의 리듬

```text
Short modern Korean electronic confirmation sound for a card reader, hotel door lock, transit gate or small terminal. One or two clean friendly utilitarian beeps, concise and clearly successful, with slight variations in pitch and rhythm. Not a smartphone notification and not an alarm. No voice, no mechanical door, no ambience, no music, isolated dry game UI one-shot.
```

## 3-5. `footsteps_01.wav`, `footsteps_02.wav`, `footsteps_03.wav`, `footsteps_04.wav`

- 길이: 1.2초
- 느낌: 단단한 구두를 신은 성인의 절제된 두 걸음. 무게감은 있지만 달리지는 않음
- 활용: 실내 접근, 복도 이동, 석실·콘크리트·어두운 나무 바닥
- 변형 차이: 신발 질감, 바닥 경도, 보폭 간격

```text
Two controlled adult footsteps in firm hard-soled shoes on a hard indoor surface, suitable for stone, polished concrete or dark wood. Measured stealthy pace, realistic weight, subtle room reflection. Create four variations with slightly different shoe tone, surface hardness and spacing while remaining consistent as one character. No running, no gravel, no clothing, no voice, no music, isolated game Foley.
```

## 3-6. `magic_pulse_01.wav`, `magic_pulse_02.wav`, `magic_pulse_03.wav`, `magic_pulse_04.wav`

- 길이: 1.4초
- 느낌: 낮은 공기 팽창 뒤 맑은 결정음이 붙는 절제된 내공·기 발동
- 활용: 내공 운용, 법기 점화, 치유·감지 능력, 작은 술식
- 변형 차이: 펄스 음높이, 반짝임, 에너지 꼬리

```text
Compact martial-arts qi activation for a fantasy game: a restrained low airy swell rising into a clear crystalline shimmer, then a soft energy tail. Ancient internal energy rather than a wizard spell, powerful but controlled. Create four variations in pulse pitch, shimmer and tail. No spoken incantation, no explosion, no lightning, no weapon, no music, isolated cinematic game one-shot.
```

## 3-7. `portal_crackle_01.wav`, `portal_crackle_02.wav`, `portal_crackle_03.wav`, `portal_crackle_04.wav`

- 길이: 2.2초
- 느낌: 작은 차원 균열이 가늘게 찢어지고 흔들리는 불안정한 공간음
- 활용: 게이트 전조, 균열 확대, 공간 왜곡, 잔류 차원흔
- 변형 차이: 균열 패턴, 음높이, 좌우 이동

```text
Small unstable dimensional rift crackling in a modern fantasy game. Low spatial hum, thin electric tearing, crystalline particles and subtle reality-warping flutter, building briefly and then settling without fully closing. Create four variations in crackle pattern, pitch and stereo motion. No giant explosion, no monster, no alarm, no voice, no music, isolated portal sound design.
```

## 3-8. `impact_01.wav`, `impact_02.wav`, `impact_03.wav`, `impact_04.wav`

- 길이: 0.9초
- 느낌: 초인의 손바닥이나 주먹이 큰 마물 몸체에 박히는 짧고 무거운 타격
- 활용: 무공 타격, 괴력 펀치, 갑각·뼈가 있는 적 공격
- 변형 차이: 몸통 공명, 짧은 균열 질감

```text
Fast superhuman martial-arts palm or hand strike hitting a large monster body. Heavy compact low thump, short air displacement and a brief bone-or-armor crack, extremely strong but not a cinematic explosion. Create four variations in body resonance and crack texture. No gore, no monster cry, no weapon slash, no debris, no voice, no music, isolated dry combat game one-shot.
```

## 3-9. `paper_01.wav`, `paper_02.wav`, `paper_03.wav`, `paper_04.wav`

- 길이: 0.9초
- 느낌: 계약서·영수증·현금 뭉치를 집어 들거나 책상 위로 미는 가까운 종이음
- 활용: 계약, 정산, 서류 조사, 현금 전달
- 변형 차이: 종이 두께, 바스락거림, 책상 접촉

```text
Close-up paper Foley for a visual novel: a contract sheet, receipt or small stack of banknotes is picked up, lightly brushed, then placed or slid across a desk. Clean realistic texture with one concise movement. Create four variations in paper thickness, rustle and desk contact. No page turning sequence, no pen writing, no stapler, no voice, no music, isolated game one-shot.
```

## 3-10. `metal_01.wav`, `metal_02.wav`, `metal_03.wav`, `metal_04.wav`

- 길이: 1.2초
- 느낌: 검집, 청동 거울, 열쇠, 금속 장식품을 조심스럽게 놓는 절제된 금속음
- 활용: 검·열쇠·법기·귀금속 전달과 배치
- 변형 차이: 물체 크기와 금속 음높이

```text
Close-up small metal-object game Foley: a sheathed sword placed on a wooden rack, a bronze ritual mirror handled, keys handed over, or a dense gold ornament set on a counter. Clear restrained metal clink with a short natural ring. Create four related variations covering slightly different metal size and pitch. No sword unsheathing, no weapon clash, no coins, no voice, no music, isolated one-shot.
```

## 3-11. `scan_01.wav`, `scan_02.wav`, `scan_03.wav`, `scan_04.wav`

- 길이: 1초
- 느낌: 약간 낡은 현대 판타지 측정기가 대상을 훑고 중립적인 결과를 내는 소리
- 활용: 각성 검사, 물품 감정, 휴대용 스캐너, 보안 검색
- 변형 차이: 스캔 음높이, 훑는 속도, 결과음

```text
Compact modern-fantasy handheld scanner sweeping across an object or a person's hand. Soft rising electronic whir, faint energy shimmer, then one concise neutral result beep. Create four variations in scan pitch, sweep speed and result tone. Technical and slightly worn, not futuristic military equipment. No voice announcement, no alarm, no machinery ambience, no music, isolated game UI one-shot.
```

---

# 4. 단발 SFX 12개

단발 SFX는 프롬프트를 실행한 뒤 나온 결과 중 장면과 가장 정확히 맞는 하나만 선택한다.

## 4-1. `gate_alarm.wav`

- 길이: 1.8초
- 느낌: 공공기관에서 사용하는 통제된 차원 게이트 경보. 급하지만 귀를 찢는 사이렌은 아님
- 활용: 게이트 경보, 시설 비상 알림, 위험 등급 상승

```text
Short modern public-safety alert for a dimensional gate warning system: three urgent clean electronic pulses with a controlled institutional tone, immediately recognizable but not deafening. No spoken announcement, no siren sweep, no explosion, no radio static, no ambience, no music, isolated game alert one-shot.
```

## 4-2. `car_horn.wav`

- 길이: 0.9초
- 느낌: 가까운 승용차가 놀라서 한 번 세게 누르는 날카로운 경적
- 활용: 도로 돌발 상황, 차량 접근, 보행자 위험

```text
One sharp close-range horn blast from a modern midsize sedan on a city street, startled and impatient, natural exterior reflection, ending cleanly. No tire squeal, no crash, no engine rev, no traffic ambience, no voice, no music, isolated realistic game Foley one-shot.
```

## 4-3. `brake_squeal.wav`

- 길이: 1.3초
- 느낌: 마른 아스팔트에서 중형 승용차가 충돌 직전 급정거하는 현실적인 마찰음
- 활용: 교통사고 직전, 추격, 위험 회피

```text
A modern sedan brakes hard on dry city asphalt from moderate speed, brief realistic tire squeal and suspension weight shift, stopping just before impact. Tense but not exaggerated. No collision, no horn, no engine roar, no pedestrians, no voice, no music, isolated exterior game Foley one-shot.
```

## 4-4. `glass_crash.wav`

- 길이: 1.8초
- 느낌: 큰 마물이 카페 전면 안전유리를 뚫고 들어오며 유리와 프레임이 쏟아지는 묵직한 파손음
- 활용: 상점 습격, 대형 창문 파괴, 괴물 난입

```text
A heavy creature crashes through a large cafe storefront window from outside to inside. One forceful impact followed by a dense cascade of safety-glass fragments, light wood and metal frame debris settling on the floor. Realistic modern interior acoustics. No monster roar, no human scream, no alarm, no music, isolated cinematic game one-shot.
```

## 4-5. `water_splash.wav`

- 길이: 0.9초
- 느낌: 깨끗한 물줄기가 갑자기 위로 솟아 얼굴에 튀는 짧고 현실적인 생활 코미디음
- 활용: 비데 사고, 수도 실수, 작은 물벼락 개그

```text
Sudden close-up burst of clean bidet water spraying directly upward and splashing a person's face, short and comical but realistic, followed by a few droplets. No vocal reaction, no toilet flush, no bathroom fan, no plumbing ambience, no music, isolated game Foley one-shot.
```

## 4-6. `microwave_ding.wav`

- 길이: 1초
- 느낌: 편의점 전자레인지의 실용적이고 친숙한 완료 알림
- 활용: 편의점 음식, 조리 완료, 현대 생활 적응

```text
Compact convenience-store microwave finishing signal, two or three clean practical electronic chimes, friendly and unmistakable, with a very short indoor appliance resonance. No door opening, no button press, no appliance hum, no store ambience, no voice, no music, isolated game one-shot.
```

## 4-7. `scissors.wav`

- 길이: 0.8초
- 느낌: 미용사가 긴 머리를 빠르고 정확하게 세 번 자르는 전문적인 가위음
- 활용: 미용실, 머리 손질, 천·실의 정밀 절단 장면

```text
Close-up salon Foley of three quick precise haircut scissor snips through long hair, clean stainless-steel blades with subtle hair texture, controlled professional rhythm. No electric clipper, no hair dryer, no salon ambience, no conversation, no music, isolated realistic game one-shot.
```

## 4-8. `door_open.wav`

- 길이: 1.2초
- 느낌: 오래된 모텔방의 전자 잠금이 풀리고 문이 안쪽으로 열리는 작은 기계음
- 활용: 모텔·낡은 숙소·전자 잠금문 입장

```text
An older motel-room door electronically unlatches and opens inward: a small latch click, handle movement, light hinge motion and soft door weight, ending before it closes. No keycard confirmation beep, no knock, no footsteps, no hallway voices, no music, isolated indoor game Foley one-shot.
```

## 4-9. `monster_growl.wav`

- 길이: 1.5초
- 느낌: 소만 한 늑대형 마물이 공격 직전 짧게 으르렁거리며 몸을 내미는 위협음
- 활용: 마물 출현, 공격 전조, 전투 개시

```text
Short aggressive growl and forward lunge from a cow-sized wolf-like dungeon monster. Deep animal throat, rough supernatural edge, one concise threatening burst suitable just before an attack. No human quality, no long cinematic roar, no footsteps, no impact, no cave ambience, no music, isolated creature game one-shot.
```

## 4-10. `crystal_break.wav`

- 길이: 1.2초
- 느낌: 주먹만 한 에너지 결정에 금이 가고 밝은 파편과 작은 마력이 터지는 압축된 파손음
- 활용: 마석·영석 파괴, 코어 손상, 마법 장치 고장

```text
A fist-sized magical energy crystal suddenly develops cracks and bursts. Sharp crystalline snap, several bright mineral shards, a brief contained energy fizzle and tiny fragments settling. Dangerous but compact, not a bomb. No portal ambience, no explosion boom, no voice, no music, isolated fantasy game one-shot.
```

## 4-11. `portal_whoosh.wav`

- 길이: 2.5초
- 느낌: 사람의 몸이 공간에 빨려 들어갔다가 반대편으로 튕겨 나오는 넓고 어지러운 차원이동음
- 활용: 차원이동, 강제 전이, 게이트 통과, 공간 방출

```text
A human body is pulled through an unstable dimensional portal: deep spatial suction, rapidly rising pressure, wide stereo reality-warping whoosh, then an abrupt release as the traveler is thrown out. Powerful and disorienting, with a faint crystalline tail. No scream, no explosion, no impact landing, no music, isolated cinematic game transition sound.
```

## 4-12. `success_sting.wav`

- 길이: 1초
- 느낌: 따뜻한 현 한 음에 작은 종이 답하는 짧고 품위 있는 성공 강조음. 영웅적 승리보다 자신감 있는 소소한 완성
- 활용: 신분증 획득, 거래 성사, 가게 이름 공개, 작은 목표 완료

```text
Very short elegant success cue for a modern martial-arts visual novel: one warm plucked zither note answered by a small clear bell, confident and lightly humorous rather than triumphant. Clean tonal ending, suitable for receiving an identity card or revealing the inn name. No orchestra, no drums, no voice, no full melody, no ambience, isolated musical game UI sting.
```

---

# 5. 다른 프로젝트에서 고르는 방법

## 분위기별 빠른 선택표

| 필요한 분위기 | 추천 파일 |
|---|---|
| 따뜻한 가게 일상 | `bgm_inn_warm`, `bgm_inn_morning` |
| 손님이 몰리는 코미디 | `bgm_inn_busy` |
| 밤의 휴식과 회상 | `bgm_inn_afterhours` |
| 전통 의식과 유적 | `bgm_murim_ritual`, `bgm_return_ritual` |
| 무협 생존과 추격 | `bgm_murim_survival` |
| 강자의 성장 몽타주 | `bgm_murim_ascension` |
| 현대 적응 코미디 | `bgm_modern_discovery`, `bgm_modern_comedy` |
| 기관 조사와 잠입 | `bgm_bureau_investigation`, `bgm_research_night` |
| 회색지대 거래 | `bgm_broker_deal` |
| 가게·기지 건설 | `bgm_inn_rebuild` |
| 첫 만남 로맨스 | `bgm_seoyun_first` |
| 편안해진 관계 | `bgm_seoyun`, `bgm_seoyun_comfort` |
| 설명용 역사 몽타주 | `bgm_gate_history` |
| 던전 탐색 | `bgm_gate_expedition` |
| 차원 위기 | `bgm_portal_crisis`, `bgm_gate_mutation` |
| 사고 뒤 미스터리 | `bgm_clue_afterglow` |

## 재사용 시 이름 변경 권장

다른 프로젝트에서 사용할 때는 등장인물 이름이 들어간 슬롯명을 기능형 이름으로 복사해 두면 관리하기 쉽다.

| 기존 슬롯 | 범용 복사 이름 예시 |
|---|---|
| `bgm_seoyun` | `bgm_romance_slowburn` |
| `bgm_seoyun_first` | `bgm_romance_first_meeting` |
| `bgm_seoyun_comfort` | `bgm_romance_comfort` |
| `bgm_inn_warm` | `bgm_shop_warm` |
| `bgm_bureau_investigation` | `bgm_agency_investigation` |
| `bgm_murim_ascension` | `bgm_dark_wuxia_growth` |

원본 파일 자체를 덮어쓰기보다 복사본의 파일명만 바꾸는 편이 안전하다. 같은 음원을 여러 프로젝트에서 편집할 경우에는 원본 WAV·MP3와 게임용 변환본을 분리해서 보관한다.

## 루프 점검

1. 처음과 끝의 음량 차이가 크지 않은지 확인한다.
2. 끝에 강한 종지·심벌·충격음이 있는 결과는 피한다.
3. BGM을 두 번 연달아 붙여 경계가 들리는지 확인한다.
4. 환경음은 경적, 드릴, 발걸음처럼 반복 위치가 드러나는 사건음을 제거한다.
5. 대사가 시작될 때 음악의 주선율과 타악기가 목소리를 덮지 않는지 확인한다.

## 권리 확인

생성 음원을 다른 작품이나 상업 프로젝트에 재사용하기 전에는 음원을 만들 당시 사용한 서비스 계정과 요금제의 이용 조건을 확인한다. 이 문서는 생성·연출용 기록이며 음원 자체의 사용권을 대신 증명하지 않는다.
