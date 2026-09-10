# 그림과 글꼴 기록

## 생성 그림

두 그림은 내장 imagegen 도구로 이 프로젝트를 위해 새로 생성했습니다. 기존 작품의 그림을 가져오지 않았으며, CLI/API fallback은 사용하지 않았습니다. 원본을 변경하지 않고 프로젝트에 복사했습니다. 네 인물 초상은 Ren’Py의 화면 표시 단계에서만 각 인물 영역을 잘라 보여 줍니다.

| 파일 | 크기 | 용도 |
|---|---|---|
| [mountains.png](../game/images/mountains.png) | 1672 × 941 | 제목·지도·이벤트 공통 배경 |
| [cast.png](../game/images/cast.png) | 1774 × 887 | 왼쪽부터 담연화·서하린·윤서령·백소하 |

작업 폴더 원본 위치:

- `C:\Users\HyunPC\.codex\.chatgpt-projects\Nocrim\game\images\mountains.png`
- `C:\Users\HyunPC\.codex\.chatgpt-projects\Nocrim\game\images\cast.png`

## 실제 사용한 생성 프롬프트

### mountains

```text
Use case: stylized-concept. Create one finished 16:9 landscape visual novel background illustration, 1536x864 or 1920x1080. Original Korean martial arts fantasy, an isolated greenwood bandit mountain fortress on a granite ridge in a fictional Korean peninsula. Dramatic layers of steep misty mountains, pine forests, narrow mountain passes, small traditional Korean tiled-roof watchtower and timber palisades on right midground, warm distant lanterns. Twilight moonlit jade blue green with ivory fog, quiet immense scale, painterly ink-wash texture with refined hand-painted Korean game concept art detail. Strong negative space in left third and center for a game menu overlay, no people, no typography, no lettering, no symbols, no logos. A beautiful standalone background plate, not a screenshot or interface.
```

### cast

```text
Use case: stylized-concept. Create a clean character portrait atlas for an original Korean martial arts visual novel, landscape 2048x1024, divided precisely into FOUR equal vertical portrait panels, each exactly one quarter width, no gaps, no borders. Four distinct ADULT Korean women ages 25 to 32, shown waist-up with heads fully inside their own panel and not touching edges. Each panel simple deep charcoal jade solid background. From LEFT TO RIGHT: 1) 27-year-old greenwood bandit deputy, dark long hair tied in high ponytail, dark green hanbok-inspired martial jacket with leather wrist guards, frank half-smile, practical sabre; 2) 25-year-old courier guild heiress, dark brown hair half-up with small red cord, muted red outer jacket over cream traditional Korean clothing, composed sharp gaze, folded travel document; 3) 29-year-old noble swordswoman, sleek black hair in elegant low bun with simple silver hairpin, indigo and ivory hanbok-inspired sword attire, upright reserved expression, sheathed sword; 4) 31-year-old mysterious apothecary, white/silver long hair tied loosely, dark teal traditional robes with pale lapels, subtle knowing smile, small ceramic medicine bottle. Refined hand-painted Korean webtoon / premium visual novel illustration with painterly shading and detailed attractive faces, elegant clothed non-sexual designs, consistent lighting and consistent scale in all four panels. Not chibi, not photorealistic. No text, no labels, no watermarks, no overlapping across panel boundaries. Exact four equal panels.
```

## 글꼴과 엔진

- SourceHanSansLite.ttf: Ren’Py SDK에 포함된 Source Han Sans 축약 글꼴. 한글·한자 표시. SIL Open Font License 1.1. `FONT-LICENSE.txt`를 함께 포함합니다.
- DejaVuSans.ttf: Ren’Py 런타임에 포함된 글꼴. 영문·숫자·화살표·기호의 누락을 보완합니다. Ren’Py 배포 라이선스에 해당 고지문이 포함됩니다.
- Ren’Py 엔진 고지는 `RENPY-LICENSE.txt` 및 배포본의 `renpy/LICENSE.txt`를 참고하세요.

