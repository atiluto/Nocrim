# 철마산역 이벤트 시스템

2026-09-14 구현·검증 기록. 원문 설정을 대체하는 문서가 아니라 실제 실행 범위의 설명이다.

## 실행과 현재 범위

루트 `대사_적용.bat`으로 프롤로그와 지역 대본을 적용하고 `play.bat`으로 실행한다. 게임 시작 → 프롤로그 → 솔바람채 거점으로 이어진다. 지도에서 바둑알을 클릭해 이동하고, 도착하면 우선 사건 하나가 진행된다. 결과가 끝나면 그 장소의 상시 메뉴로 돌아간다. `이동`을 누르면 지도가 열린다. 현재 바둑알의 `주변 살피기`는 상시 메뉴를 연다. 조건 사건 재판정은 실제 장소 진입 시 한다.

원문 176개 개별 사건과 연쇄 설계 4개를 보존하고 전용 루트 사건/기능 20개를 추가했다. 총 **196개 중 기본 진행 157개, 부분 진행 23개, 미구현 16개**다. 기존 SJ-C04·DN-C02·CH-C02는 전용 루트 MD에서 실행 경로를 확장했다. 상세 목록·사유는 [EVENT_CATALOG.md](EVENT_CATALOG.md). `ready`는 현재 등록한 기본 실행 경로에 미해결 분기가 없다는 뜻이며, 원문의 모든 장기 확장·미술·대사를 완성했다는 뜻은 아니다. 부분 진행 사건은 가능한 선택만 실행하고 미구현 선택은 흐리게 표시한다.

- PHASE 1–2: 조건·결과·기한·저장·선택 UI·지도 표시·개발 조작 구현.
- PHASE 3: 전체 원문 등록, 기본 상시/무작위/조건 사건 연결. 미구현 개별 사건은 목록에 보존.
- PHASE 4: 마영란 첫 만남, 수레, 길찾기, 국수, 산채 방문 등 주 진행 대화 연결. 일부 변형 분기 미구현.
- PHASE 5: 733–737년 사건/지역별 연도 상태 등록. 세력 협상 전체 대화, 외부 지역, 일부 경제·전투 후속은 미완성.

2026-09-14 히로인 미술 반영: 마영란 전용 스프라이트 6종과 대사별 표정, 배경 3장, 붕대 CG, 비·눈 효과를 연결했다. 장소연·하령화는 각각 스프라이트 3종과 전용 대사/동행/연애·동료 루트를 연결했다. 추가로 Higgsfield 배경 3장을 연결했다. 모든 캐릭터 그림은 사용자 요청대로 흰 배경을 보존한다. 상세 파일과 편집 방법은 [HEROINE_ART.md](HEROINE_ART.md). 기존 프롤로그 캐스팅과 전투는 유지한다.

## 구조와 수정 파일

| 경로 | 역할 |
|---|---|
| `scenario/철마산역_전체이벤트설계.md` | 사용자 원문 설계, 보존 |
| `scenario/마영란_철마산역_히로인_이벤트_전체대본.md` | 사용자 전체 대본, 보존 |
| `scenario/events/source_registry.json` | 개별 사건/연쇄의 원문 블록 보관 |
| `scenario/events/catalog.json` | 실행 조건·선택·결과·후속·미구현 상태의 편집 원본 |
| `scenario/events/chapters/<사건 ID>/*.md` | 한 ID = 한 화면인 실제 대사, 102개 파일·1032개 화면 (원래 마영란 804개 유지) |
| `scenario/events/manifest.json` | 컴파일할 지역 MD 목록 |
| `scenario/events/staging.json` | 지역 대본 전용 인물·배치·움직임 |
| `scenario/events/presentation.json` | 지역 대본의 날짜·장소·시간대·전환 |
| `tools/compile_scenario.py` | 기존 문법 검증기를 프롤로그/지역 대본에 공용으로 사용 |
| `tools/compile_events.py` | 조건/그래프/선택/참조 ID 검증 및 지역 JSON 출력 |
| `godot/data/region_events.json`, `event_dialogue.json` | 생성물, 직접 편집하지 않음 |
| `godot/scripts/region_events.gd` | 범용 이벤트 관리자 |
| `godot/scripts/event_views.gd` | 지역 선택지·결과·장소 메뉴, 기존 VN 화면 연결 |
| `godot/scripts/campaign.gd` | 기존 행동 트랜잭션·날짜·이동에 관리자 연결 |
| `godot/scripts/calendar.gd`, `godot/data/calendar.json` | 일자 비교 및 중원력 표시 |
| `godot/scripts/persistence.gd` | 구세이브 기본값 보충 |
| `godot/scripts/prologue.gd` | 동일 VN 화면을 이벤트 대사에도 사용, 안정된 대사 ID 저장 |
| `godot/scripts/main.gd`, `map_views.gd`, `camp_views.gd` | 화면 전환·지도 알림·거점 진입 |
| `godot/scripts/chapter_map.gd`, `godot/data/chapter_01_map.json` | 점령 여부와 방문 가능 여부 분리 |
| `scenario/presentation.json` | 무림 프롤로그 경과를 3월 상·중·하순에 맞춤 |
| `대사_적용.bat` | 두 종류 대본을 함께 적용·검사 |

지역 대본은 재방문과 선택 분기가 있어 선형 프롤로그에 붙이지 않았다. 별도 데이터이지만 실제 화면·타이핑·기록·암전·회상·스프라이트·음향 코드는 기존 VN을 재사용한다. 기존 `P01-...` ID는 변경하지 않는다.

`import_region_sources.py`, `configure_region_events.py`, `extend_region_events.py`는 초기 등록 이력을 위한 일회성 도구이다. **재실행해서 편집본을 덮어쓰지 않는다.** 일상적인 수정은 MD/JSON 원본과 컴파일러만 사용한다. 설계 문서의 산문을 바꾸는 것만으로 런타임 조건이 자동 변경되지는 않는다.

## 날짜와 기존 세이브

- 시작: 중원력 732년 3월 상순. 현대 프롤로그: 2026년 6월 상순.
- 프롤로그 마지막 하순 밤 뒤, 전략 모드는 **732년 3월 22일 아침**에 시작한다.
- 행동 1 = 시간대 1. 아침 → 낮 → 밤 → 다음 날 아침. 10일 = 1순, 3순 = 1개월, 12개월 = 1년. 모든 달을 30일로 계산한다.
- 기존 “3행동 = 다음 순” 규칙은 1–3일 구조/산불 기한을 구현하기 위해 일 단위를 추가했다. 경제 수입·유지비·기존 전략 `turn`은 계속 **순 단위**로 정산한다. 기존 부상/침공 등 `turn` 기반 기능도 순 단위다.
- 화면 상단은 기존 연·월·순 및 시간대 스타일을 유지한다. 저장 목록/상세 날짜 문자열에는 월 내 일자도 표시한다.
- 상태의 `calendar_day`는 순 안에서 0–9. `calendar_cycle_offset + turn - 1`은 시작 이후 순 수. 이벤트의 비교 시각은 `순×30 + calendar_day×3 + 시간대`이다.
- 기존 세이브는 리셋하지 않는다. 새 필드만 기본값을 채우며 기존 연·월·순과 AP를 유지한다. 구세이브의 일자는 해당 순 첫날로 보충한다. 이미 완료한 프롤로그를 불러오면 날짜를 되돌리지 않는다.
- 저장 후 로드는 그 저장 시점의 세계 전체를 복원한다. 현실 시계가 지나서 이벤트가 만료되는 방식은 아니다. 게임 내 시간 변경 때만 만료한다.

## 데이터 스키마

실제 등록 예시는 `catalog.json`의 `BU-R01`, `MY-AG-01`, `MY-JS-03`을 참고한다.

```json
{
  "id": "REGION-C01",
  "title": "사건 제목",
  "locations": ["white"],
  "type": "CONDITIONAL",
  "status": "ready",
  "visibility": "condition",
  "category": "general",
  "priority": 60,
  "repeatable": false,
  "cooldown_days": 20,
  "from": {"year":732,"month":4,"day":1},
  "until": {"year":732,"month":4,"day":30,"period":2},
  "conditions": {"all":[
    {"path":"flags.prologue_complete","op":"eq","value":true},
    {"any":[
      {"path":"regional.items.herb","op":"gte","value":1},
      {"path":"regional.vars.my_companion","op":"eq","value":true}
    ]}
  ]},
  "start":"entry",
  "nodes": {
    "entry":{"type":"choice","text":"쓰러진 사람을 발견했다.","choices":[
      {"id":"help","text":"도와준다.","next":"result","cost":{"ap":1},
       "effects":[{"op":"add","path":"mercy","value":6}]},
      {"id":"pass","text":"지나간다.","next":"DEFER","effects":[]}
    ]},
    "result":{"type":"result","text":"도와주었다.\n선량 평판 +6","next":"END"}
  },
  "complete":[{"op":"set","path":"flags.region_helped","value":true}],
  "expire":[{"op":"set","path":"flags.region_missed","value":true}],
  "expire_text":"기한을 놓쳤다."
}
```

예시의 새 ID는 문법 설명용이며 실제 등록된 사건이 아니다.

| 항목 | 동작 |
|---|---|
| `type` | `STATIC` 상시 메뉴, `RANDOM` 방문 추첨, `CONDITIONAL` 조건 사건. `FOLLOWUP`은 명시적 직결 전용 |
| `locations` | 기존 지도 노드 ID 목록. `*`는 모든 장소 |
| `visibility` | `hidden`은 지도 표시 없음. 공개 조건은 `condition` |
| `status` | `ready` 기본 진행, `partial` 일부 진행, `pending` 실행 제외 |
| `category` | `main` → `npc` → `special` → `general`. 긴급과 만료 임박이 먼저 |
| `priority` | 100 이상은 긴급. 같은 분류에서 높은 값 우선, 동률은 ID 순 |
| `from/until` | 포함 범위. `period` 0 아침, 1 낮, 2 밤. 생략 시 0 |
| `duration_days` | 조건이 성립하면 방문 여부와 무관하게 제한 시간 시작. 날짜 상한과 짧은 제한 중 먼저 끝나는 쪽 사용 |
| `repeatable/cooldown_days` | 완료 후 재발 여부·실제 게임 일 단위 쿨다운 |
| `yearly/annual_anchor_month` | 다음 연간 계절에 재개. 과거 만료 이력은 보존 |
| `settle_after_completion` | 선택 완료 뒤에도 달력 상한에서 월동/회의 정산 실행 |
| `weight/weight_modifiers` | 무작위 후보 간 가중치·상황별 배율 |
| `immediate` | 완료 후 바로 실행할 후속 사건 ID. 조건 충족 시에만 연결 |
| `complete/expire` | 정상 완료/기한 만료 시 효과 목록 |
| `unimplemented` | 남은 기능의 명시적 기록 |

`nodes`는 `choice`, `dialogue`, `result` 세 종류다. `dialogue.beats`에는 MD 대사 ID를 순서대로 적는다. `next`는 같은 사건의 노드 이름, `END`(완료), `DEFER`(미완료 보류)이다. `choice`의 `conditions`를 만족하지 못하면 숨긴다. 자원이 부족하면 비활성화한다. `pending:true`는 미구현 선택을 비활성화한다. 선택 ID나 완료 상태를 검사하므로 같은 보상을 두 번 받을 수 없다.

`result.texts`는 `{when:조건,text:문장}` 목록이며 첫 성립 문장을 출력한다. 결과 문구를 조건에 따라 바꾸되 대사 속에 명령을 끼워 넣지 않는다.

## 조건과 결과

조건 배열은 AND다. `{all:[...]}`, `{any:[...]}`, `{not:...}`를 중첩할 수 있다.

| 조건 op | 의미 |
|---|---|
| `eq`, `ne` | 값 같음/다름. 없는 플래그는 null이며 false와 별개 |
| `truthy` | true·0이 아닌 수·비어 있지 않은 문자열/목록/사전. 문자열 선택 결과 플래그 확인에도 사용 |
| `gte`, `lte` | 관계·자원·호감 등 수치 비교 |
| `contains` | `owned`, `roster` 등 목록 포함 |
| `count_gte` | 목록/사전의 개수 이상 |
| `date_gte`, `date_lte` | `value`에 날짜 객체를 지정 |
| `month_in`, `period_in` | 월 목록 / `아침·낮·밤` 목록 |
| `since` | 경과 일수. `path`에 `stamp`로 저장했던 시각, `value`에 일수 |

아이템은 `regional.items.<ID>`, 마영란 관계는 `regional.vars.my_trust` 등, 세력은 `regional.factions.<ID>`, 평판/악명은 기존 `mercy/fear`, 능력은 `flags.gigam_unlocked`, 보유 지역은 `owned`를 사용한다. 없는 플래그 검사에는 `{"not":{"path":"flags.example","value":true}}`를 사용한다.

효과 op: `set` 대입, `add` 증감, `max` 최소 진행 단계 유지, `stamp` 현재 시각 저장, `append` 목록 추가, `random` 효과 목록 중 하나 선택, `home` 보유 지역 추가, `schedule` 특정 사건 기한 예약. 효과의 `when`으로 조건부 결과를 만들 수 있다. `cost`는 효과와 별개이며 모든 자원이 충분한지 먼저 검사한 다음 한꺼번에 차감한다. 실패한 행동은 원래 상태로 되돌린다.

문서에 숫자가 없는 가격·효과·쿨다운은 초도 조정값이다. 원문 확정 수치는 그대로 두고 조정값은 catalog에서 바꾼다. 수레 도움 후 장시 재회는 원문의 “몇 주 뒤”를 **14일**로 설정했다. 따라서 TEST B는 도움 직후 즉시 재회가 아니라 14일 경과 후 활성화된다.

## 저장 데이터

기존 `nocrim-godot-2` 저장을 유지하며 `calendar_day`와 `regional`을 추가한다.

`regional` 내부:

- `active`: 사건 ID, 현재 노드, 대사 cursor/beat ID, 시작 시각, 방문 장소.
- `completed`, `counts`, `cooldowns`: 완료 시각, 실행 횟수, 다음 실행 가능 시각.
- `pending`: 보지 않았더라도 시작한 기간 사건의 시작/종료 시각.
- `expired`, `expiration_history`: 현재 만료 상태와 누적 자동 결과 이력.
- `selections`: 사건/노드/선택 ID 및 시각. 선택으로 바뀐 자원도 함께 저장.
- `last_random`, `visits`: 연속 반복 방지와 장소 방문 횟수.
- `vars`: `my_met`, `my_route_stage`, `my_trust`, `my_affection`, `my_suspicion`, `my_debt`, `my_secret_known`, `my_kept_secret`, `my_companion`, `my_romance`, `my_route_failed` 및 진행 보조 변수.
- `items`, `factions`, `locations`: 소지품·세력 관계·지역 상태. `locations.world_stage`는 연도별 상황 설명이며 모든 상황에 별도 시뮬레이션을 붙인 것은 아니다.
- `menu`, `last_tick`, `followups`: 현재 메뉴, 마지막 검사 시각, 확장용 후속 목록. 실제 직결은 `immediate`, 보통 후속은 플래그 조건으로 처리한다.

마영란 연애 선택은 높은 신뢰/호감, 비밀 유지, 핵심 구조, 민간인 가해 성향을 모두 검사한다. 동행은 13개 장소에서 물리적 흔적 정보를 기록하고 장소별 하루 한 번 정보 보너스를 준다. 솔바람채는 경비 보너스도 적용한다. 일부 사건에는 동행 전용 선택지가 있다. 순찰 회피·샛길 등 모든 보너스가 독립적인 이동 규칙으로 완성된 것은 아니며 지역 `tracking` 정보와 전용 선택으로 구현된 범위를 구분한다. 강산 기감 선택은 별도의 능력 플래그를 검사한다.

## 개발 테스트와 디버그

`python tools/test_events.py`는 컴파일 일치 검사와 관련 Godot 테스트를 순서대로 실행하고 `tests/events/`에 로그를 보존한다. 게임 화면 검사는 `--render`를 추가한다. 실제 사용자 저장 `.local/play-saves`는 건드리지 않고 `tests/godot-saves`를 사용한다.

별도 JSON 요청 파일을 만들고 다음처럼 실행한다.

```powershell
python tools/godot_task.py --headless --script res://tests/event_debug.gd -- --request=tests/event-debug-request.json
```

요청 예: `{"command":"date","args":{"year":732,"month":7,"day":1,"period":0},"save":true}`. `new_game:true`는 테스트 저장에서 새 상태를 만든다. `save` 생략 시 메모리에서만 조작한다.

| command | args |
|---|---|
| `date` | year, month, day, period |
| `move` | `{"id":"mist"}` — 강제 이동·진입 판정 |
| `event` | `{"id":"BU-R01"}` — 실행 가능한 사건 강제 시작 |
| `flag` | `{"key":"merchant_cart_helped","value":true}` |
| `variable` | `{"key":"my_trust","value":30}`; affection/suspicion/companion도 같은 방식 |
| `cooldowns` | `{}` — 쿨다운·직전 무작위 사건 초기화 |
| `list` | `{}` — 현재/기간/활성 가능한 사건 조회 |

기존 지역 시스템 구축 시점(전용 루트 추가 전)의 테스트 기록:

| 검사 | 결과 |
|---|---|
| 지역 시스템 TEST A–D, 만료·구세이브·연애·계절·회의 | 57개 통과 |
| 전체 선택 노드/조건/결과 및 무작위 분포 | 306개 통과, 1,000회 중 아무 일 없음 646회, 연속 중복 0 |
| 일자·시간·순·연도·프롤로그 연결 | 79개 통과 |
| 기존 전략/전투 | 195개 통과 |
| 도착·군사 메뉴·구조 사건 회귀 | 60개 통과 |
| 지도 목각 말/경로 | 347개 통과 |
| 실제 렌더링 및 마우스 입력 UI | 25개 통과 |
| 프롤로그/이벤트 컴파일 | 11장 492화면 / 176사건 804화면 일치 |

UI 검사는 새 게임 프롤로그 시작과 마지막 대사의 거점 인계를 확인하며, 변경하지 않은 492개 프롤로그 전체를 사람이 다시 읽은 검사는 아니다. 마영란 첫 만남의 선택→공통 대화 전체→선택 분기 전체→뒷대화 전체는 실제 VN으로 실행했다. 테스트 저장 후 불러오기, 수레 도움 결과, 지도 긴급 표식을 확인했다. 이미지 기록: `tests/region-map.png`, `tests/region-choice.png`.

테스트에서 수정한 문제: JSON 월 숫자의 형식 차이로 계절 조건이 빠지던 문제, 짧은 구조 기한이 월말로 덮이던 문제, 문자열 플래그와 boolean 비교 오류, 대본의 설명 문장을 화자로 오인한 항목, 상반된 두 선택 효과의 중복 적용. 초기 글꼴 가져오기는 첫 실행이 중단되어 다시 가져온 뒤 렌더링 검사를 통과했다. Windows 인증서 저장소 경고는 엔진 시작 때 남지만 로컬 게임/테스트에는 영향이 없었다.

## 다른 지역 추가 순서

1. 실제 지도에 장소 ID를 등록한다. 예시 이름으로 없는 장소/그림을 참조하지 않는다.
2. catalog에 안정된 사건 ID와 위치·타입·조건·노드·결과를 추가한다. 마영란 전용 관리자를 따로 만들 필요 없다.
3. 대화가 있으면 `chapters/<ID>/` MD를 작성하고 manifest에 등록한다. 한 ID는 한 화면이다. BGM/환경음은 유지할 화면마다 실제 경로를 반복한다.
4. staging에 역할별 인물/배치, presentation에 화면별 장소/시간을 등록한다. `live:true`는 실제 방문 날짜·시간을 사용한다. 기존 문법을 그대로 쓰며 미지원 motion을 추가하지 않는다.
5. 컴파일과 해당 조건/선택/저장·만료 테스트를 실행한다. 설계만 있는 부분은 `pending` 또는 `unimplemented`에 남긴다.
6. 대사 변경은 MD 수정 후 BAT로 적용한다. 구조 변경은 catalog 및 연관 연출 파일을 함께 검토한다.
