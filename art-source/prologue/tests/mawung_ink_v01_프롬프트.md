# 마웅철 수묵풍 테스트 v01

- 제작일: 2026-09-13
- 상태: 비교·테스트용 새 이미지. 게임의 `godot/assets/prologue/mawung.png`는 교체하지 않았다.
- 결과: [mawung_ink_v01.png](mawung_ink_v01.png)
- 입력: 현재 mawung.png. 얼굴·체격·상투·갈색 무복·적갈색 띠·도·자세를 유지하는 스타일 변경.
- 방식: 내장 image_gen 편집. 흰 배경 원본 보존, 자동 배경 제거 없음.
- 육안 확인: 얼굴과 장비가 유지되며 어깨·소매·옷자락에 굵은 먹선과 수묵 음영이 강화되었다. 거친 붓 질감도 남아 있으므로 최종 공통 그림체 확정이 아닌 테스트안이다.

## 추가한 핵심 스타일 문구

> Rounder, slightly thicker charcoal-black brush contours with rounded stroke starts and endings, organic calligraphic pressure variation. Bold flowing curved outer silhouette and major folds, softer rounded connections instead of brittle angular outlines. Large readable charcoal ink-wash shadow masses, restrained diluted brown and rust pigments.

## 실제 생성 프롬프트

```text
Use case: style-transfer. Edit target: attached mawung.png, an original Korean wuxia visual novel character. Create ONE alternate test portrait of the SAME Ma Wungcheol. Preserve his recognizable stern square face, age about 40, broad powerful build, rough black topknot with loose hair, short stubble, scar/weathered face details, dark brown layered worn robes, dull iron forearm guards, rust-red sash, low-held broad single-edged dao, front three-quarter pose and overall composition. Face and ordinary hair remain visible; no hat, hood, face mask or new cloak concealing the face. Keep his identity rather than making him an anonymous extra.
CHANGE THE RENDERING: a noticeably more traditional Korean ink-and-light-color wuxia illustration. Rounder, slightly thicker charcoal-black brush contours with rounded stroke starts and endings, organic calligraphic pressure variation. Bold flowing curved outer silhouette and major folds, softer rounded connections instead of brittle angular outlines. Selective dry-brush breaks and gentle ink pooling confined WITHIN the figure. Large readable charcoal ink-wash shadow masses, restrained diluted brown and rust pigments, subtly shaded brow and face while eyes/nose/mouth remain recognizable. Simplify tiny scratches and noisy texture; prioritize broad cloth folds and hair locks. Keep mature proportions and serious rugged mood, not cute, chibi, pastel storybook or glossy gacha. This is a moderate ink restyle of the original, not fully abstract monochrome painting; retain controlled game-portrait readability.
Portrait canvas approximately 2:3. Keep hair, arms, sword and lateral clothing completely inside canvas with breathing room. Preserve original lower-thigh crop and standing presentation. Fully OPAQUE perfectly flat WHITE #FFFFFF background, no alpha transparency, no checkerboard, no paper tint/texture in background, no scenery, no floor or cast shadow, no ink splashes outside the silhouette, no text, watermark or panels. One character only.
```

## 이번 사용자 방향

일반 NPC도 반드시 모자나 망토로 얼굴을 가릴 필요는 없다. 머리카락과 얼굴 형태를 유지하고 얼굴에 그림자가 지는 방식으로 익명성을 표현할 수 있다. 이번 마웅철은 특정 인물이므로 원본 얼굴을 유지했다. 얼굴 가림 해제와 역할별 전용 이미지·사망 후 재사용 금지 규칙은 별개다.

