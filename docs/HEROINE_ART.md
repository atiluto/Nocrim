# 히로인 이미지와 표정 — 2026-09-14

설정 기준은 `universe/07_녹림_캐릭터시트.md`. 사용자 선택은 마영란·장소연·하령화 총 3명, **흰 배경만 생성하고 배경 제거는 직접 수행**이다.

## 제작 및 적용 범위

| 인물 | staging 인물 ID | 표정 키 | 적용 |
|---|---|---|---|
| 마영란 | `ma_yeongran` | `neutral`, `smile`, `surprised`, `angry`, `worried`, `shy` | 기존 지역 대화에 등장·표정·이동 연결 |
| 장소연 | `jang_soyeon` | `neutral`, `smile`, `serious` | 전용 루트 대사별 표정 연결 |
| 하령화 | `ha_ryeonghwa` | `neutral`, `smile`, `worried` | 전용 루트 대사별 표정 연결 |

총 **캐릭터 원화 12장 + 배경 6장 + 사건 CG 1장**. 추가 배경 3장은 Higgsfield로 제작했다. 캐릭터는 1024×1536의 동일 캔버스이며 아래쪽이 화면 밖으로 이어지는 입상이다. 발끝까지 보이는 전신 시트는 아니다. 표정 교체 시 무대 노드를 다시 만들지 않으며, Y=48·높이=728과 원본 비율을 유지한다. AI 생성 차분의 미세한 그림 차이까지 픽셀 단위로 동일하다고 보장하지는 않는다.

| 배경/CG 키 | 실제 연결 |
|---|---|
| `bg_solbaram_noodles` | MY-SJ-01 국수 대화 |
| `bg_mountain_shelter` | MY-R-08 좁은 비 피하기 대화 |
| `bg_cheonghak_clearing` | MY-CH-01/02 청학산 대화와 분기 |
| `cg_ma_bandage` | MY-BU-03-COMMON-026~037 상처 확인·붕대 대화. 별도 인물 스프라이트 숨김 |

MY-BU-04는 원문에 맞게 **bg_rock_overhang** 바위틈 배경으로 연결했다. Higgsfield로 약방 **bg_herbal_room**, 육지에서 보는 나루 **bg_ferry_landing**도 생성해 새 루트에 연결했다. [추가 생성 기록](../art-source/heroines-routes-20260914/제작기록.md)에 원본·프롬프트·작업 ID를 저장했다.

마영란 첫 만남에서는 COMMON-012에 모습을 드러내고 TAIL-005에서 퇴장한다. 구조 전 수색, 등에 업힌 뒤, 마영란이 없는 총채 보고 장면에도 입상을 억지로 표시하지 않는다. 매복 경고는 중앙으로 이동하며 반응하고, 부상은 흔들림, 음식 경고는 놀람을 사용한다. 일반 대화는 상하로 움직이지 않는다.

장소연·하령화 전용 대본·동행·연애/동료·결별 분기를 추가했고 SJ-C04·DN-C02·CH-C02도 실행된다. 상세 조건은 [전용 루트 안내](../scenario/events/routes/README.md). 두 사람을 그린 별도 사건 CG는 추가 제작하지 않았으며 배경과 기존 표정 스프라이트를 조합한다.

## 흰 배경을 직접 제거한 뒤 적용하기

1. 원본은 `art-source/heroines-20260914/`에 보관되어 있다. 보관 원본을 유지하고 복사본을 편집한다.
2. 인물별 `<인물 ID>_<표정>.png`의 흰 배경을 직접 제거한다. **1024×1536 캔버스, 인물 위치와 크기를 그대로 유지**하고 가장자리만 다듬는다. 표정마다 자동 자르기를 적용하면 전환 시 흔들릴 수 있다.
3. 완성된 PNG를 **동일한 이름**으로 `godot/assets/prologue/`의 해당 파일에 덮어쓴다. 예: `ma_yeongran_smile.png`.
4. 게임을 종료한 뒤 `play.bat`으로 다시 시작한다. PNG만 바꾼 경우 대사 적용 BAT는 필요 없다. 대사나 JSON도 바꿨다면 `대사_적용.bat`을 실행한다.

자동 배경 제거·투명 버전·마젠타 색키는 이번 작업에서 만들지 않았다. **직접 제거하기 전에는 실제 게임에도 흰 사각 배경이 표시된다.** 배경 CG와 사건 CG는 완성된 장면이므로 흰 배경 제거 대상이 아니다.

## 대사별 표정과 이동

지역 대화는 `scenario/events/staging.json`, 프롤로그는 `scenario/staging.json`을 쓴다. 히로인은 현재 지역 staging에 등록되어 있다. 프롤로그에서 쓰려면 해당 cast/역할/전용 이미지 등록도 함께 복사해야 한다.

아래는 `cues` 안의 **한 항목**이다. 전체 staging 파일을 덮어쓰지 않는다.

```json
"MY-SJ-04-COMMON-012": {
  "stage": [{"actor":"ma_yeongran","slot":"right"}],
  "expressions": {"ma_yeongran":"shy"}
}
```

`stage`는 그 화면에 남길 인물 전체 목록이다. 생략하면 기존 배치가 유지되고 `[]`면 모두 퇴장한다. `expressions`는 무대에 있는 인물만 대상으로 하며 등록된 표정 키만 허용한다. 표정만 적으면 다음 명시 변경까지 유지된다. `stage`를 새로 쓰면 기본 그림으로 재구성되므로 원하는 `expressions`도 함께 적는다. 이번 등록본은 대사별 cue에 표정을 명시했으므로 다음 cue도 확인한다.

중앙으로 이동하며 놀라게 하려면 실제 기존 키를 사용한다.

```json
"MY-BU-03-COMMON-009": {
  "stage": [{"actor":"ma_yeongran","slot":"center"}],
  "expressions": {"ma_yeongran":"surprised"},
  "motions": [{"actor":"ma_yeongran","motion":"approach"}]
}
```

`jump`는 짧게 위로 반응한 뒤 복귀, `shake`는 좌우 흔들림, `approach`는 슬롯 이동 후 짧은 반응이다. 일상 이동은 `slot`만 바꾼다. 무대 Y/크기 값이나 임의 motion 이름은 추가하지 않는다. 다른 인물이 함께 있다면 stage 목록에 함께 남긴다. 각 히로인 그림은 그 인물 전용으로 다른 NPC 역할에 쓰지 않는다.

## 배경·날씨

새 배경은 해당 `presentation.json`의 최상위 `backgrounds` 배열에 확장자 없는 PNG 이름을 등록하고 MD에 `배경: bg_solbaram_noodles`처럼 적는다. 파일은 `godot/assets/prologue/`에 실제로 있어야 한다. 배경 변화는 기존 암전 전환을 사용한다. CG에 인물이 그려져 있으면 그 구간의 `stage: []`로 입상 중복을 피한다.

날씨는 presentation의 최상위 `weather` 객체로 조작한다. 아래는 일부 항목 예시다.

```json
"weather": {
  "MY-BU-04-COMMON-001": "rain",
  "MY-BU-04-COMMON-010": "",
  "MY-SB-03-COMMON-001": "snow"
}
```

`rain`은 비, `snow`는 눈, 빈 문자열은 끄기다. 같은 MD에서는 다음 변경까지 유지하며 새 MD에서는 기본적으로 꺼진다. 독립적으로 진입하는 분기 MD에도 필요하면 첫 ID에 명시한다. 효과는 인물·대화창 뒤에서 그려지고 클릭을 가로채지 않는다. 게임 난수를 소비하지 않으므로 사건 추첨 결과에 영향을 주지 않는다. 일시정지 메뉴나 앱 비활성 상태에서는 입자 시간이 멈춘다. 날씨 자체는 날짜를 진행시키거나 암전을 발생시키지 않는다.

날씨와 소리는 별도다. 빗소리를 유지할 각 MD 대사에는 실제 제공 음원 `환경음: sfx/amb_rain_mountain_loop_01.mp3`를 반복한다.

## 확인 결과

- 프롤로그 492개·지역 804개 대사 컴파일 및 일치 검사 통과. 기존 대사 텍스트·ID와 사건 조건/보상/저장 구조 보존.
- Python 검사 7개: 표정 키·역할·배경·날씨 검증 및 첫 등장/퇴장/CG 구간 확인.
- Godot headless 검사 63개: 12종 이미지 로드, 같은 노드에서 교체, 위치/크기 유지, 좌우 이동·반응 복귀, 배경 로드, 효과 층과 종료.
- 기존 지역 UI 흐름 headless 검사 25개 통과. 이번에는 창을 띄운 화면 검수와 전체 대본 재플레이는 하지 않았다.
- 엔진 시작 시 인증서 저장소 경고와 종료 시 ObjectDB 2개 경고가 남는다. 이 검사들의 실패 수는 0이며 경고를 해결했다고 주장하지 않는다.

실행: `python tools/test_heroine_art.py`, `python tools/godot_task.py --headless --script res://tests/test_heroine_art.gd`. 테스트는 별도 저장 경로를 사용한다. 기존 사용자 저장을 초기화할 필요가 없다.
