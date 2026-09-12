# Godot판 그림 기록

## 현재 제작 기준 — 2026-09-12 확정

캐릭터 소스는 **불투명 단색 마젠타 `#FF00FF` 배경**을 기본으로 생성한다. 캐릭터의 머리·옷·장식에 마젠타 계열이 들어가면 **불투명 흰색 `#FFFFFF` 배경**을 사용한다. 투명 알파·자동 배경 제거·체크무늬 배경을 요청하지 않는다. 사용자가 소스를 직접 수정해 배경을 제거한다. 이 기준은 인물 컷아웃용이며 산·건물 등 장면 배경 그림에는 적용하지 않는다.

배경에 그라데이션·바닥·그림자·광륜·입자·색 번짐을 넣지 않는다. 인물 가장자리에 마젠타 반사광을 넣지 않는다. 무기 끝·머리·신발을 모두 포함하고 가장자리 여백을 확보한다. PNG로 보관한다. 생성 결과의 실제 단색 여부는 별도로 확인하며, 요청만으로 정확한 색의 배경이 완성되었다고 판단하지 않는다.

그림체 참고: [사용자 제공 이미지](../art-source/references/character-style-reference.webp). 가늘고 또렷한 선화, 정돈된 셀 명암과 제한적인 부드러운 그라데이션, 섬세한 머리카락 가닥, 선명한 눈, 길고 균형 잡힌 성인 비례, 겹쳐진 옷자락·금속·매듭 장식의 질감 차이를 따른다. 기존의 회화적인 붓 질감보다 선과 색면이 명확한 애니메이션 게임 캐릭터 일러스트를 지향한다. 얼굴·헤어·의상·무기는 녹림전생의 인물 설정으로 구성한다. 참고 이미지의 정면 자세를 아군 후면 전투 자세에 그대로 적용하지 않는다.

원본은 `art-source/`에 보관하고 실제 게임 그림은 `godot/assets/characters/`의 기존 파일명을 사용한다. 사용자가 배경을 제거한 PNG로 교체한 뒤 `play.bat`을 다시 실행하면 가져오기가 진행된다. 게임에서 마젠타나 흰색을 자동으로 지우지 않는다.

## 생성과 현재 상태

주인공과 네 히로인의 후면 대기 그림, 적장의 정면 그림을 Higgsfield의 GPT Image 2로 생성했다. 1360×2048 PNG다. 6장의 배경 분리 수정도 Higgsfield에서 시도했지만, 이 모델의 `remove_bg` 매개변수는 지원되지 않아 생략되었고 결과는 RGB였다. 별도 내장 이미지 편집으로 배경 분리를 시도한 결과도 RGB였다.

**담연화의 후면 대기 그림은 2026-09-12 GPT Image 2.5 Sunburst로 교체했다.** 1360×2048 RGB PNG, 선화·셀 채색과 불투명 마젠타 배경이다. 배경색에 미세한 편차가 있어 정확히 균일한 #FF00FF는 아니다. 나머지 전투 그림 5장은 이전 체크무늬 배경이 남아 있다. 원본·이전 그림·생성 기록은 `art-source/yeon-sunburst/`에 보관했다. BAT의 자료 가져오기와 시작 검사를 통과했다. 과거의 알파 제거 시도는 이전 기록이며 더 이상 사용자 확인을 기다리는 작업이 아니다. 이후 배경 제거는 사용자가 직접 처리한다.

기존 배경과 대화용 인물 합본은 이전 녹림전생 시제품에서 사용한 원본을 재사용했다. 모든 인물은 성인 설정이며, 레퍼런스 게임의 캐릭터·대사·그래픽을 복제하지 않았다.

2026-09-12 담연화 대화용 `godot/assets/characters/yeon_portrait.png`도 Sunburst로 재제작했다. 1744×2336 RGB, 무릎 위 정면 3/4 구도이며 머리카락·팔·옷자락의 좌우 여백을 확인했다. 불투명 마젠타 배경은 미세한 색 편차가 있고 자동 제거하지 않았다. 원본과 생성 기록은 `art-source/yeon-sunburst/yeon_portrait.png`, `portrait_generation.json`. 기존 4인 합본보다 이 개별 초상화를 우선 사용한다. BAT 가져오기·시작 검사 통과.

## 기본 파일

| 파일 | 인물 / 방향 |
|---|---|
| `assets/characters/you_idle.png` | 강현 28세 / 후면, 오른쪽 위를 봄 |
| `assets/characters/yeon_idle.png` | 담연화 27세 / 후면 |
| `assets/characters/seo_idle.png` | 서하린 25세 / 후면 |
| `assets/characters/yun_idle.png` | 윤서령 29세 / 후면 |
| `assets/characters/so_idle.png` | 백소하 31세 / 후면 |
| `assets/characters/enemy_idle.png` | 공통 적장 / 정면 3/4 |
| `assets/characters/cast.png` | 기존 네 인물의 대화 초상 합본 |
| `assets/backgrounds/mountains.png` | 기존 산문·산하 배경 |

지금은 기본 대기 그림만 있다. 공격과 피격 포즈 파일을 넣으면 같은 방향과 캔버스 비율로 교체된다. 파일이 없을 때는 대기 그림에 움직임·색·참격을 적용한다. 말풍선마다 다양한 표정을 새로 생성한 상태는 아니다.

## 후속 제작 프롬프트

공통 그림체: `Original Korean wuxia game character illustration. Use the supplied style reference for thin clean controlled linework, crisp cel-shaded forms with restrained soft gradients, finely separated hair strands, expressive eyes, elegant adult proportions, layered flowing garments and precise metal, knot and fabric details. Preserve this character's established identity, hair, weapon and costume colors. Full body including shoes and all weapon tips, clear margin on every side. No lettering, watermark or UI.`

기본 배경: `Fully opaque, flat solid magenta background, exactly #FF00FF. Uniform color across the entire background. No transparency, alpha cutout, checkerboard, floor, cast shadow, gradient, glow, particles, background texture or magenta color spill on the character. Clean unobstructed silhouette for manual background removal later.`

흰색 대체 배경: 위 배경 블록의 `magenta`, `#FF00FF`, `magenta color spill`을 각각 `white`, `#FFFFFF`, `white halo`로 바꾼다. 마젠타색 인물 장식이 없으면 기본 배경을 쓴다. 흰 머리·흰 옷이 많은 백소하·윤서령은 마젠타가 기본이다.

아군 전투 방향: `Rear three-quarter view, camera behind the character; back and back of head visible, only a small side profile. Face toward the upper-right at one o'clock. Preserve camera, scale, costume and canvas alignment across pose variants.`

대화용 방향: `Front three-quarter standing character, face clearly visible, calm expressive pose. Preserve the same identity and costume as the combat reference.`

적장은 아군 방향 블록 대신 아래 적장 방향을 사용한다. 단색 배경은 동작·표정 파생 이미지에도 동일하게 유지한다.

- 강현: `28-year-old Korean man, tousled short black hair, sand-colored durumagi over charcoal travel clothes, teal belt, worn leather boots, paper talisman in right hand, sheathed short sword at left hip.`
- 담연화: `27-year-old Korean woman, black high ponytail, forest-green short jeogori, charcoal divided riding skirt, leather forearm guards, single-edged saber held low toward the upper-right.`
- 서하린: `25-year-old Korean woman, chestnut pinned updo with red cord, brick-red outer jacket, cream long divided skirt, small leather courier satchel and short straight sword.`
- 윤서령: `29-year-old Korean woman, black low bun and silver pin, ivory and indigo layered riding robes, thin straight sword angled toward the upper-right.`
- 백소하: `31-year-old Korean woman, silver-white hair tied loosely, deep-teal and ivory flowing robe, herb pouch, folded fan and medicine satchel.`
- 적장: `51-year-old Korean man, salt-and-pepper beard and topknot, charcoal lamellar armor over russet robe, heavy glaive. Front three-quarter view facing down-left toward the heroes.`

동작 블록: 준비는 `Shift weight backward and prepare the weapon without turning to face the viewer.` 일반 공격은 `Extend the weapon toward the upper-right in one controlled attack, retain the rear view.` 피격은 `Recoil slightly backward, preserve the camera and costume silhouette.` 강공격은 `Deeper wind-up with a decisive upper-right strike, all weapon tips inside the canvas.`

검수는 선화·동일 인물 여부·시선 방향·잘림·배경 단색 여부를 확인한다. 사용자가 나중에 투명 처리한 파일을 제공하면 그때 흰 머리·흰 옷·무기 가장자리가 손상되지 않았는지 확인한다.

## 거점·산길 배경 (2026-09-12)

Higgsfield GPT Image 2.5 Sunburst로 만든 `backgrounds/base_camp.png`, `backgrounds/road.png` 사용. 원본·생성 기록은 `art-source/camp-life/`. 사물 위치에 맞춘 클릭 영역과 산길 두 번 흔들기를 연결했다. 장면 배경에는 캐릭터용 마젠타 규칙을 적용하지 않는다. 이미지 확인 완료, 게임 실행은 생략.

## 그림 지도·종이 UI (2026-09-12)

내장 image_gen으로 `backgrounds/chapter_01_painted.png`, `ui/paper_panel.png`를 새로 생성했다. 지도는 원화를 전체 화면에 표시하며 노드·길·지명은 코드로 겹친다. 종이 이미지는 크기에 따라 늘어나는 패널 재질이다. `ui/icons/`는 글꼴에 의존하지 않는 SVG 픽토그램. 최종 프롬프트·디자인 참고 출처는 `art-source/map-redesign/제작기록.md`.
