# Godot판 그림 기록

## 생성과 현재 상태

주인공과 네 히로인의 후면 대기 그림, 적장의 정면 그림을 Higgsfield의 GPT Image 2로 생성했다. 1360×2048 PNG다. 6장의 배경 분리 수정도 Higgsfield에서 시도했지만, 이 모델의 `remove_bg` 매개변수는 지원되지 않아 생략되었고 결과는 RGB였다. 별도 내장 이미지 편집으로 배경 분리를 시도한 결과도 RGB였다.

**현재 전투용 6장에는 체크무늬 배경이 남아 있다.** 투명하게 보이는 체크무늬는 실제 투명 채널이 아니며, 투명 PNG 제작이 완료되었다고 보고하지 않는다. 로컬 배경 제거 도구로 처리하는 선택은 사용자 확인을 기다리고 있다. 게임에서 임의로 흰 픽셀을 지우는 코드는 넣지 않았다.

기존 배경과 대화용 인물 합본은 이전 녹림전생 시제품에서 사용한 원본을 재사용했다. 모든 인물은 성인 설정이며, 레퍼런스 게임의 캐릭터·대사·그래픽을 복제하지 않았다.

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

공통: `Refined painterly Korean wuxia visual novel illustration, natural adult proportions, detailed layered hanbok fabric, soft edge lighting, muted jade, ink and gold palette. Full body including shoes and all weapon tips within frame, generous clear margin, no lettering or UI. Rear three-quarter view, camera behind the character; back and back of head visible, only a small side profile. Face toward the upper-right at one o'clock. Use the accepted idle image as the reference and preserve identity, outfit, camera and canvas alignment.`

- 강현: `28-year-old Korean man, tousled short black hair, sand-colored durumagi over charcoal travel clothes, teal belt, worn leather boots, paper talisman in right hand, sheathed short sword at left hip.`
- 담연화: `27-year-old Korean woman, black high ponytail, forest-green short jeogori, charcoal divided riding skirt, leather forearm guards, single-edged saber held low toward the upper-right.`
- 서하린: `25-year-old Korean woman, chestnut pinned updo with red cord, brick-red outer jacket, cream long divided skirt, small leather courier satchel and short straight sword.`
- 윤서령: `29-year-old Korean woman, black low bun and silver pin, ivory and indigo layered riding robes, thin straight sword angled toward the upper-right.`
- 백소하: `31-year-old Korean woman, silver-white hair tied loosely, deep-teal and ivory flowing robe, herb pouch, folded fan and medicine satchel.`
- 적장: `51-year-old Korean man, salt-and-pepper beard and topknot, charcoal lamellar armor over russet robe, heavy glaive. Front three-quarter view facing down-left toward the heroes.`

동작 블록: 준비는 `Shift weight backward and prepare the weapon without turning to face the viewer.` 일반 공격은 `Extend the weapon toward the upper-right in one controlled attack, retain the rear view.` 피격은 `Recoil slightly backward, preserve the camera and costume silhouette.` 강공격은 `Deeper wind-up with a decisive upper-right strike, all weapon tips inside the canvas.`

생성 도구에 투명 배경을 요청했다는 사실만으로 파일이 투명하다고 판단하지 않는다. 실제 알파 채널과 어두운 배경 위의 흰 옷·흰 머리·무기 가장자리를 별도로 검사해야 한다.
