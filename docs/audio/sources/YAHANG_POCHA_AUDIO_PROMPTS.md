# 야행포차 BGM·SFX 재사용 프롬프트

이 문서는 야행포차 프롤로그의 최종 Ren'Py 스크립트에서 실제로 호출하는 음원을 다른 프로젝트에서도 재사용할 수 있도록 정리한 기록이다.

- BGM 제작: Suno, Instrumental On
- 환경음·효과음 제작: ElevenLabs Sound Effects
- BGM 위치: `game/audio/bgm/`
- 환경음·효과음 위치: `game/audio/sfx/`
- `01~04`는 같은 프롬프트로 4개를 생성한 변형 파일이다.
- 원문 확인: 당시 사용한 프롬프트가 대화 기록에 그대로 남아 있는 항목
- 재생성용 복원: 원문은 남지 않았으나 실제 파일명, 장면 배치와 당시 지정한 소리의 성격을 기준으로 다시 쓴 프롬프트

> BGM 4곡의 원래 Suno 프롬프트 문장은 보존되지 않았다. 아래 BGM 프롬프트는 선택한 완성곡의 제목과 실제 장면 용도에 맞춘 재생성용 복원본이다.

## 1. BGM

### `night_market_whispers.mp3`

- 제목: Night Market Whispers
- 기록 상태: 재생성용 복원
- 권장 길이: 90~120초, 자연스러운 반복
- 느낌: 따뜻한 무림 야시장, 조용한 일상, 등불 아래 포장마차. 편안하고 약간 능청스럽지만 경박하지 않다.
- 사용 장면: 현재 시점의 야행포차 영업, 포장마차 완성 공개, 첫 손님, 현재 복귀, 엔딩 직전의 일상 장면

```text
Warm nighttime wuxia food-stall instrumental for a Korean visual novel. Gentle plucked East Asian strings, soft xiao flute, low warm bowed strings, subtle wooden percussion and sparse hand drum. Around 82 BPM. A small food cart glowing under lanterns in a busy ancient Chinese night market, intimate daily life, quiet confidence and a faint playful charm. Cozy and human rather than grand or heroic. Keep the melody restrained under dialogue, no vocals, no choir, no modern electronic beat, no cinematic battle climax, seamless loop.
```

### `night_market_whispers_2.mp3`

- 제목: Night Market Whispers2
- 기록 상태: 재생성용 복원
- 권장 길이: 90~110초, 자연스러운 반복
- 느낌: 같은 야시장 세계관이지만 조금 더 경쾌하다. 손으로 수레를 고치고 가게를 준비하는 생활형 성장 몽타주에 어울린다.
- 사용 장면: 관도와 성내 이동, 대장간, 수레 수리, 장보기, 조리 연습, 첫 영업 준비

```text
Light and industrious wuxia market instrumental for a Korean visual novel, a brighter companion to Night Market Whispers. Rhythmic plucked strings, wooden blocks, light hand percussion, short dizi flute phrases and warm low strings. Around 100 BPM. A resourceful traveler repairs a wooden handcart, shops for ingredients and slowly builds a small night food stall. Practical progress, curiosity and modest satisfaction, not triumphant. No vocals, no comedy gimmicks, no heavy drums, no epic orchestra, dialogue-friendly and seamlessly loopable.
```

### `rain_on_the_wandering_cart.mp3`

- 제목: Rain on the Wandering Cart
- 기록 상태: 재생성용 복원
- 권장 길이: 80~110초, 자연스러운 반복
- 느낌: 비와 피로가 섞인 쓸쓸한 이동곡. 슬프기만 하기보다 혼자 버티며 하루를 넘기는 정서가 있다.
- 사용 장면: 현대의 비 오는 포장마차, 산길 이동, 객잔 회복, 부상 뒤 감정 정리, 수레를 끌고 가는 밤길과 강변

```text
Melancholic wandering-cart instrumental for a story-driven wuxia visual novel. Soft felt piano, muted acoustic guitar, breathy xiao flute, restrained low strings and very light brushed percussion, with a subtle rain-like texture. Around 72 BPM. A tired cook walks alone through rain and unfamiliar roads, carrying an unfinished dream and quietly deciding to keep living. Bittersweet, reflective and warm beneath the loneliness. No vocals, no dramatic crying strings, no heroic climax, no thunder effects, spacious under narration and naturally loopable.
```

### `beneath_the_wet_soil.mp3`

- 제목: Beneath the Wet Soil
- 기록 상태: 재생성용 복원
- 권장 길이: 60~90초, 자연스러운 반복
- 느낌: 젖은 흙 아래에 갇힌 압박감, 불규칙한 심장, 기억과 빙의의 불길함. 공포 영화처럼 과장하지 않고 낮고 답답하다.
- 사용 장면: 생매장 직후 각성, 낙뢰와 빙의, 기억 유입, 흑도패에게 당한 뒤의 무력감, 위기 회상

```text
Claustrophobic dark ambient instrumental for a wuxia visual novel. Deep soil-like drone, irregular muted heartbeat, bowed metal resonance, low cello pressure, faint reversed breath textures and sparse sub-bass pulses. Almost no melody. A buried man wakes beneath rain-soaked earth as another life and its memories force their way into him. Oppressive, disoriented and intimate rather than supernatural spectacle. No vocals, no screams, no percussion groove, no horror stinger, no large cinematic boom, seamless low-volume loop under narration.
```

## 2. 환경음 루프

공통 권장 설정:

- Duration: 15초
- Looping: On
- Prompt Influence: 30~40%
- 각 세트는 `_01`부터 `_04`까지 4개 생성
- 시작과 끝의 공간 톤이 같고 큰 돌발음이 없는 결과를 선택

### 비 내리는 산과 무덤

- 파일명:
  - `amb_rain_mountain_loop_01.mp3`
  - `amb_rain_mountain_loop_02.mp3`
  - `amb_rain_mountain_loop_03.mp3`
  - `amb_rain_mountain_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 깊은 산의 차갑고 거센 비. 무덤 밖의 폭우와 폐사당 주변에 사용하며, 번개는 별도 효과음으로 분리한다.

```text
Seamless 15-second ambience loop on a remote rain-soaked mountain at night in historical East Asia. Dense rain striking wet soil, leaves and old stone, cold gusts moving through trees, and distant low storm rumble. Dark, exposed and lonely, with stable matching ambience at the beginning and end. No close lightning strike, no footsteps, no animals, no voices, no music, no modern traffic.
```

### 비가 그친 산의 아침

- 파일명:
  - `amb_mountain_morning_loop_01.mp3`
  - `amb_mountain_morning_loop_02.mp3`
  - `amb_mountain_morning_loop_03.mp3`
  - `amb_mountain_morning_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 비가 그친 뒤 젖은 산길. 맑지만 주인공의 부상 때문에 완전히 평화롭지는 않다.

```text
Seamless 15-second ambience loop on a wet mountain path in early morning after rain. Soft wind through dense leaves, occasional water drops falling from branches, two or three distant small birds and a faint stream far below. Fresh, cool and quiet with long natural gaps. No footsteps, no people, no insects dominating, no music, no modern sounds.
```

### 산자락 마을의 낮

- 파일명:
  - `amb_foothill_village_day_loop_01.mp3`
  - `amb_foothill_village_day_loop_02.mp3`
  - `amb_foothill_village_day_loop_03.mp3`
  - `amb_foothill_village_day_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 작고 가난한 산촌의 생활음. 도시보다 한산하며, 말소리는 알아들을 수 없어야 한다.

```text
Seamless 15-second daytime ambience loop in a small historical East Asian foothill village. Light wind, distant indistinct villagers, one soft wooden bucket movement, a far chicken and occasional cloth or basket handling. Sparse rural life, modest and calm. No clear words, no market crowd, no carts passing close, no music, no modern machinery.
```

### 관도의 낮

- 파일명:
  - `amb_official_road_day_loop_01.mp3`
  - `amb_official_road_day_loop_02.mp3`
  - `amb_official_road_day_loop_03.mp3`
  - `amb_official_road_day_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 상인과 여행자가 드문드문 지나는 넓은 관도. 이동감은 있지만 붐비는 시장처럼 들리지 않는다.

```text
Seamless 15-second ambience loop beside a historical East Asian official road in daytime. Distant wooden cart wheels, occasional horse hooves far away, soft wind across dry grass, leather harness creaks and indistinct travelers passing at a distance. Open-road movement with plenty of quiet space. No close footsteps, no galloping, no battle, no clear speech, no music, no modern vehicles.
```

### 구강부 성문

- 파일명:
  - `amb_city_gate_day_loop_01.mp3`
  - `amb_city_gate_day_loop_02.mp3`
  - `amb_city_gate_day_loop_03.mp3`
  - `amb_city_gate_day_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 검문과 통행이 이어지는 성문. 군중·수레·말이 섞이지만 대사를 덮지 않는 중간 밀도다.

```text
Seamless 15-second daytime ambience loop at the gate of a busy historical East Asian walled city. Indistinct travelers waiting, wooden carts rolling slowly, occasional horse hooves, cloth bundles shifting and guards' spear shafts touching stone. Ordered public movement, moderately busy but dialogue-friendly. No intelligible speech, no shouting, no battle, no music, no modern sounds.
```

### 구강부 대로와 시장

- 파일명:
  - `amb_city_main_street_day_loop_01.mp3`
  - `amb_city_main_street_day_loop_02.mp3`
  - `amb_city_main_street_day_loop_03.mp3`
  - `amb_city_main_street_day_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 구강부의 활기찬 대로와 낮 시장. 장보기·수레 작업·첫 영업에 넓게 재사용한다.

```text
Seamless 15-second ambience loop on a lively historical East Asian city main street and market in daytime. Layered but indistinct merchant voices, soft footsteps, baskets and cloth bundles moving, occasional wooden cart wheels, one distant animal and light shop activity. Busy and colorful without any understandable words. No foreground shout, no music, no combat, no modern objects or vehicles.
```

### 객잔 홀

- 파일명:
  - `amb_inn_hall_loop_01.mp3`
  - `amb_inn_hall_loop_02.mp3`
  - `amb_inn_hall_loop_03.mp3`
  - `amb_inn_hall_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 목조 객잔 1층의 잔잔한 식사와 대화. 조리 연습 장면에도 낮은 볼륨으로 사용한다.

```text
Seamless 15-second interior ambience loop in a modest historical East Asian inn hall. Low indistinct guest murmur, sparse ceramic bowl and wooden chopstick sounds, one chair shifting softly, old floorboards and a distant kitchen pot. Warm, worn and lived-in, kept subtle beneath dialogue. No intelligible words, no laughter burst, no music, no modern cutlery.
```

### 객잔의 좁은 방

- 파일명:
  - `amb_inn_room_night_loop_01.mp3`
  - `amb_inn_room_night_loop_02.mp3`
  - `amb_inn_room_night_loop_03.mp3`
  - `amb_inn_room_night_loop_04.mp3`
- 기록 상태: 재생성용 복원
- 느낌: 낡은 목조 객잔 방의 밤. 회복 기간과 날짜 전환을 연결하는 조용하고 약간 쓸쓸한 실내음이다.

```text
Seamless 15-second nighttime room-tone loop inside a small old wooden inn room in historical East Asia. Very soft continuous air and low wood resonance, occasional restrained building creak, faint wind at a paper window and distant unrecognizable life from downstairs. Quiet, enclosed and slightly lonely. No foreground footsteps, no voices, no insects close to the listener, no fire, no music.
```

### 무림 포장마차 식기 생활음

- 파일명:
  - `amb_pocha_tableware_loop_01.mp3`
  - `amb_pocha_tableware_loop_02.mp3`
  - `amb_pocha_tableware_loop_03.mp3`
  - `amb_pocha_tableware_loop_04.mp3`
- 기록 상태: 원문 확인
- Duration: 15초
- Looping: On
- Prompt Influence: 약 30%
- 느낌: 손님 바로 옆에서 들리는 그릇·젓가락·국자·행주 소리. 시장 환경음 위에 14~16% 정도로 아주 낮게 겹친다.

```text
Seamless 15-second close ambience loop inside a small historical East Asian night food cart. Sparse, irregular ceramic bowl clinks, wooden chopsticks touching bowls, a wooden ladle lightly tapping an iron pot, and an occasional damp cloth wiping a wooden counter. Leave long quiet gaps so it stays subtle beneath visual novel dialogue. Natural intimate food-stall Foley with matching room tone at the beginning and end. No voices, crowd, footsteps, music, cooking sizzle, or modern metal cutlery.
```

## 3. 이동 반복음

### 다친 상태의 진흙길 발걸음

- 파일명:
  - `sfx_injured_mud_steps_01.wav`
  - `sfx_injured_mud_steps_02.wav`
  - `sfx_injured_mud_steps_03.wav`
  - `sfx_injured_mud_steps_04.wav`
- 기록 상태: 재생성용 복원
- 권장 길이: 8~12초
- Looping: On 또는 반복 연결 가능한 결과
- 느낌: 갈비뼈를 다친 사람이 젖은 산길을 절뚝이며 걷는 가까운 발소리. 영웅적인 행군음이 아니다.

```text
Seamless close Foley loop of one injured adult walking slowly through wet mud and uneven dirt in simple cloth shoes. Uneven limping rhythm, cautious weight shifts, soft mud suction, damp fabric movement and occasional strained pause. Realistic and restrained. No voice, no groan, no rain, no crowd, no horse, no music.
```

### 나무 손수레 이동

- 파일명:
  - `sfx_wooden_handcart_roll_01.wav`
  - `sfx_wooden_handcart_roll_02.wav`
  - `sfx_wooden_handcart_roll_03.wav`
  - `sfx_wooden_handcart_roll_04.wav`
- 기록 상태: 원문 확인. 원래는 2.5초 단발로 제작해 간격 재생하도록 정했으며, 이후 이동 채널에서도 반복 사용한다.
- Duration: 2.5초
- Looping: Off
- Prompt Influence: 45%
- 느낌: 가벼운 수제 포장마차 수레가 흙길이나 청석길을 천천히 굴러가는 소리. 낡았지만 부서질 듯 과장되지 않는다.

```text
Close-up realistic Foley of a small handmade wooden handcart beginning to roll slowly over packed earth. Wooden wheels make a low rumble and the axle gives one soft worn squeak. Light cart with no animal attached. No footsteps, no horse, no cargo rattling, no voice, no music.
```

## 4. 단발 효과음

### `sfx_ceramic_bowl_counter_01.wav`

- 기록 상태: 원문 확인
- 설정: 1초, Looping Off, Prompt Influence 55%
- 느낌·용도: 빈 도자기 그릇을 나무 조리대에 놓는 맑고 절제된 달그락. 프롤로그의 시작과 현재 복귀를 연결한다.

```text
A single small ceramic soup bowl is gently placed onto a solid wooden food stall counter. One clear restrained ceramic clink with a very short wooden resonance. Close-up realistic Foley. No cutlery, no coins, no voice, no music, no room ambience.
```

### `sfx_charcoal_grill_sizzle_01.wav`

- 기록 상태: 원문 확인
- 설정: 2초, Looping Off, Prompt Influence 50%
- 느낌·용도: 닭꼬치를 작은 숯불 화로에 올리는 순간의 먹음직스럽고 짧은 지글거림.

```text
Close-up realistic cooking Foley: a marinated chicken skewer is placed onto a small hot charcoal grill, producing an immediate rich sizzle with a few tiny fat crackles. Appetizing but restrained. No voice, no utensils, no roaring fire, no music, no kitchen ambience.
```

### `sfx_glass_bottle_smash_01.wav`

- 기록 상태: 원문 확인
- 설정: 1.5초, Looping Off, Prompt Influence 55%
- 느낌·용도: 취객이 녹색 술병을 탁자 모서리에 내리쳐 병 아랫부분을 깨는 날카로운 사고음.

```text
A single green glass liquor bottle is violently smashed against the hard edge of a wooden table. The lower bottle shatters instantly, sharp glass fragments scatter onto the floor, while the broken neck remains intact. Close-up realistic Foley. No voice, no scream, no music, no cinematic impact.
```

### `sfx_fall_glass_stab_01.wav`

- 기록 상태: 원문 확인
- 설정: 1.5초, Looping Off, Prompt Influence 50%
- 느낌·용도: 두 사람이 함께 넘어지며 깨진 병목이 옆구리에 박히는 순간. 잔혹함보다 갑작스러운 사고에 가깝다.

```text
Close-up realistic Foley of two clothed adults slipping and falling together, ending with a broken glass bottle neck puncturing through a jacket into the side of the body. A short fabric tear, dull body impact and subtle glass contact. Sudden but restrained, not graphic. No scream, no voice, no blood splatter, no music.
```

### `sfx_lightning_strike_close_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 2초, Looping Off, Prompt Influence 55%
- 느낌·용도: 무덤 바로 옆에 떨어지는 낙뢰. 번개와 빙의의 전환점이지만 영화식 폭발음은 피한다.

```text
A violent lightning strike hits wet ground extremely close in a mountain graveyard. One instantaneous electrical crack, heavy thunder snap, brief earth resonance and a short rain-soaked tail. Natural and frighteningly close. No explosion, no magical whoosh, no music, no voice, no long rolling thunder.
```

### `sfx_mud_escape_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 2초, Looping Off, Prompt Influence 55%
- 느낌·용도: 손과 상체가 젖은 무덤 흙을 뚫고 올라오는 무겁고 숨 막히는 탈출음.

```text
Close-up realistic Foley of a human hand and upper body forcing through a shallow layer of heavy rain-soaked grave soil. Wet earth tears open, mud collapses to both sides and soaked cloth drags against the ground. Desperate and physical but not graphic. No voice, no scream, no shovel, no music.
```

### `sfx_body_fall_mud_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1.5초, Looping Off, Prompt Influence 55%
- 느낌·용도: 탈출 직후 힘이 풀려 진흙탕에 쓰러지는 둔하고 젖은 충격.

```text
Close-up realistic Foley of one exhausted clothed adult collapsing sideways into wet mud. A dull body impact, thick mud splash and soaked fabric settling, compact and restrained. No voice, no groan, no gore, no rain ambience, no music.
```

### `sfx_memory_surge_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 3초, Looping Off, Prompt Influence 45%
- 느낌·용도: 제갈유현의 기억이 한꺼번에 밀려드는 비현실적인 상승음. 알아들을 수 있는 속삭임은 넣지 않는다.

```text
A short supernatural memory-surge sound for a visual novel: thin reversed breaths, layered paper-like whispers with no intelligible words, rising glass resonance, low heartbeat pressure and a sudden inward pull that fades quickly. Disorienting and intimate, not explosive. No spoken language, no scream, no melody, no cinematic boom.
```

### `sfx_wooden_mechanism_smash_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1.5초, Looping Off, Prompt Influence 55%
- 느낌·용도: 제갈가의 목제 기관이 강제로 파손되는 짧고 복잡한 기계음.

```text
A compact historical wooden locking mechanism is violently broken apart. Interlocking hardwood pieces crack, one small gear snaps, a wooden pin shoots loose and a little metal fitting rattles onto the floor. Close-up realistic mechanism Foley. No explosion, no large door crash, no voice, no music.
```

### `sfx_ceramic_cup_shatter_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1초, Looping Off, Prompt Influence 55%
- 느낌·용도: 기억 속 독이 든 작은 술잔이 바닥에서 깨지는 날카롭고 짧은 소리.

```text
A single small ceramic drinking cup drops onto a hard stone floor and shatters into several pieces. One dry sharp ceramic crack with a few tiny fragments settling. Close-up realistic Foley. No glass, no table impact, no voice, no music, no room ambience.
```

### `sfx_body_punch_ribs_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1초, Looping Off, Prompt Influence 55%
- 느낌·용도: 흑도패가 이미 다친 갈비뼈를 가격하는 둔한 타격. 과장된 액션 펀치가 아니다.

```text
Close-up realistic Foley of one hard fist striking the ribs through layered cloth clothing. A compact dull body thud, brief fabric snap and restrained low impact, painful but not cinematic. No voice, no grunt, no bone break, no blood, no music.
```

### `sfx_grave_soil_drop_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1.5초, Looping Off, Prompt Influence 50%
- 느낌·용도: 생매장 기억에서 젖은 흙이 몸과 얼굴 위로 삽 한 번 분량 떨어지는 소리.

```text
A single heavy shovel-load of damp grave soil drops onto cloth-covered human body and packed earth at close range. Thick dirt impact, loose clumps breaking and a short gritty settling tail. Restrained and realistic. No shovel scrape, no voice, no breathing, no music.
```

### `sfx_hidden_cache_unearth_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 2초, Looping Off, Prompt Influence 50%
- 느낌·용도: 폐사당의 돌여우상 아래에서 숨겨둔 꾸러미를 파내는 소리.

```text
Close-up realistic Foley of two hands quickly uncovering a small oilcloth-wrapped cache from damp soil beneath an old stone shrine ornament. Soft scraping dirt, small stones shifting and waxed cloth being exposed. No shovel, no opening the bundle, no coins, no voice, no music.
```

### `sfx_coin_pouch_small_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1초, Looping Off, Prompt Influence 55%
- 느낌·용도: 적은 수의 동전과 은전이 든 작은 천 주머니. 소지금 확인과 돈을 빼앗기는 장면에 재사용한다.

```text
A small cloth coin pouch containing only a modest handful of old metal coins is lifted and gently shaken once. Soft dry coin clinks muffled by fabric, close-up realistic Foley. No pouring coins, no large treasure, no modern currency, no voice, no music.
```

### `sfx_herbal_dye_mix_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 2초, Looping Off, Prompt Influence 50%
- 느낌·용도: 폐사당에서 머리와 피부를 바꿀 약초 염료를 작은 그릇에 섞는 조용한 소리.

```text
Close-up realistic historical Foley of a small wooden spoon mixing thick herbal dye paste in a shallow ceramic bowl. Damp gritty stirring, one light ceramic tap and a soft cloth packet movement. No liquid pouring, no voice, no music, no modern laboratory sounds.
```

### `sfx_qinggong_rooftop_leap_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1.5초, Looping Off, Prompt Influence 50%
- 느낌·용도: 젊은 무인이 경공으로 기와지붕을 두 번 가볍게 밟고 지나가는 소리.

```text
Two rapid light foot contacts across an old clay-tile roof as a skilled martial artist performs qinggong. Soft cloth rush, quick tile taps, one slight tile shift and a short airy pass. Agile and physical, not magical. No voice, no sword, no heavy landing, no cinematic whoosh, no music.
```

### `sfx_guard_spear_tap_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1초, Looping Off, Prompt Influence 55%
- 느낌·용도: 성문 수비가 통행을 막기 위해 창 자루 끝을 돌바닥에 한 번 치는 경고음.

```text
A historical city guard firmly taps the wooden butt of a long spear once against a stone gate floor. One dry wooden impact with a faint metal spearhead vibration. Authoritative but restrained. No voice, no marching, no weapon swing, no music, no crowd ambience.
```

### `sfx_wooden_door_bolt_lock_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1.5초, Looping Off, Prompt Influence 55%
- 느낌·용도: 객잔 방의 낡은 문을 안에서 잠그는 나무 빗장 소리.

```text
Close-up realistic Foley of a worn wooden sliding bolt being pushed firmly into place on an old inn-room door. Dry wood scrape, one solid stop and a tiny door-frame creak. No key, no metal lock, no footsteps, no voice, no music.
```

### `sfx_herbal_ointment_apply_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 2초, Looping Off, Prompt Influence 50%
- 느낌·용도: 객잔에서 갈비뼈와 멍에 끈적한 약고를 바르고 천으로 감는 치료음.

```text
Close-up realistic historical medical Foley: thick herbal ointment is scooped from a small ceramic jar, spread over bruised skin, then covered with one short pull of linen bandage. Soft sticky paste, cloth friction and a faint jar tap. No voice, no pain groan, no liquid, no music.
```

### `sfx_blacksmith_anvil_strike_01.wav`

- 기록 상태: 재생성용 복원
- 권장 설정: 1.5초, Looping Off, Prompt Influence 55%
- 느낌·용도: 대장간에서 작은 철제 부품을 모루에 두세 번 두드리는 공용 제작음.

```text
Close-up realistic historical blacksmith Foley: a hand hammer delivers three measured strikes onto a small iron fitting resting on an anvil. Clear compact metal impacts with a short forge-room tail. Skilled controlled work, not weapon forging spectacle. No voice, no bellows, no roaring fire, no music.
```

### `sfx_mechanism_misfire_01.wav`

- 기록 상태: 원문 확인
- 설정: 2초, Looping Off, Prompt Influence 50%
- 느낌·용도: 수제 호신 기관이 제대로 작동하지 않고 용수철과 덮개가 튕겨 나가는 실패음. 세 번의 시제품 실패에 같은 파일을 재사용한다.

```text
A small handmade wooden and metal spring mechanism suddenly misfires. A tight spring twang, brief wooden crack, loose metal parts rattling, and one small cover piece skittering across the floor. Mechanical failure, compact and realistic. No gunshot, no explosion, no voice, no music.
```

### `sfx_handsaw_wood_short_01.wav`

- 기록 상태: 원문 확인
- 설정: 2초, Looping Off, Prompt Influence 50%
- 느낌·용도: 썩은 수레 판자를 잘라내고 새 판자를 맞추는 짧은 수동 톱질.

```text
Close-up realistic historical woodworking Foley: a manual hand saw makes two firm strokes through a dry wooden plank. Crisp wood fibers scraping and a small amount of sawdust falling. Short and clean, suitable for repeated use. No voice, no hammer, no power tools, no music, no workshop ambience.
```

### `sfx_charcoal_fire_extinguish_01.wav`

- 기록 상태: 원문 확인
- 설정: 1.5초, Looping Off, Prompt Influence 50%
- 느낌·용도: 영업을 마치며 작은 화로 위에 금속 덮개를 씌워 불씨를 죽이는 소리.

```text
Close-up realistic Foley of a small charcoal brazier being extinguished by placing a fitted metal lid over the glowing coals. A brief soft hiss, tiny charcoal crackles, and one muted metal contact. Compact historical cooking stove. No water pouring, no large fire, no voice, no music.
```

### `sfx_title_reveal_chime_01.wav`

- 기록 상태: 원문 확인
- 설정: 2초, Looping Off, Prompt Influence 45%
- 느낌·용도: 강변 독백 뒤 타이틀 로고가 나타나는 순간의 작고 맑은 전통 종소리.

```text
A single soft strike on a small traditional bronze temple bell, followed by a short warm resonance and one faint wooden wind chime accent. Calm, elegant and East Asian, suitable for a wuxia visual novel title reveal. No melody, no drums, no voice, no large gong, no cinematic boom.
```

### `sfx_ui_confirm_01.wav`

- 기록 상태: 원문 확인
- 설정: 1초, Looping Off, Prompt Influence 55%
- 느낌·용도: 메뉴, 선택지, 저장·불러오기, 설정, 확인과 닫기에 공용으로 쓰는 절제된 UI 확인음.

```text
A single subtle polished bamboo tap against a small wooden surface, with a faint soft paper flick. Clean, short and elegant user interface confirmation sound for a historical East Asian visual novel. No bell, no voice, no music, no echo, no additional impacts.
```

## 5. 빠른 분위기별 재사용표

| 필요한 장면 | 우선 재사용할 음원 |
|---|---|
| 따뜻한 야시장·가게 일상 | `night_market_whispers.mp3`, `amb_city_main_street_day_loop_01~04`, `amb_pocha_tableware_loop_01~04` |
| 제작·장보기·가게 성장 | `night_market_whispers_2.mp3`, `sfx_handsaw_wood_short_01.wav`, `sfx_blacksmith_anvil_strike_01.wav` |
| 쓸쓸한 이동·감정 정리 | `rain_on_the_wandering_cart.mp3`, `sfx_wooden_handcart_roll_01~04.wav` |
| 매장·빙의·기억 침투 | `beneath_the_wet_soil.mp3`, `amb_rain_mountain_loop_01~04`, `sfx_memory_surge_01.wav` |
| 객잔에서 회복 | `rain_on_the_wandering_cart.mp3`, `amb_inn_room_night_loop_01~04` |
| 낯선 도시 진입 | `night_market_whispers_2.mp3`, `amb_city_gate_day_loop_01~04` |
| 타이틀·장 전환 | `sfx_title_reveal_chime_01.wav` |
| 공용 UI | `sfx_ui_confirm_01.wav` |

## 6. 재사용 시 주의

- 환경음과 포차 식기음은 서로 다른 채널에서 겹쳐야 한다. 포차 식기음은 시장 환경음보다 훨씬 작게 둔다.
- BGM은 대사보다 6~10dB 낮게 시작한다.
- `beneath_the_wet_soil.mp3`는 긴 공포곡이 아니라 짧은 위기와 기억 장면용이다.
- `sfx_body_punch_ribs_01.wav`, `sfx_fall_glass_stab_01.wav`는 잔혹함을 강조하지 않는다.
- 현대적 금속 식기, 자동차, 전자음, 총성처럼 시대를 깨는 결과는 제외한다.
- 같은 세트의 `_01~04`는 피치만 바꾼 복제보다 실제 타이밍과 작은 소리 구성이 다른 결과가 좋다.
