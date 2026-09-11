# 음원 넣기 · Suno / ElevenLabs

BAT로 실행하는 현재 프로젝트에서는 `godot/assets/audio/`를 사용한다. 음악은 `bgm`, 효과음은 `sfx` 폴더에 넣는다. 아래 파일명은 대소문자까지 유지한다. 파일을 교체한 뒤 BAT를 다시 실행한다.

현재 제공받은 음원은 없으므로 무음으로 실행된다. 실제 사용자 음원의 음량·루프·청취 검증은 아직 하지 않았다. 배경음은 같은 장면을 갱신해도 재시작하지 않고, 장면이 바뀌면 0.6초간 교차 전환한다. 효과음은 최대 8개까지 겹쳐 재생한다. 음소거는 ESC 메뉴에서 켜고 끈다.

## Suno BGM

공통 프롬프트: `Instrumental only, no vocals, Korean martial-arts fantasy, restrained gayageum and geomungo plucked strings, daegeum bamboo flute, organic janggu percussion, cinematic but intimate, no loud modern synth lead, no abrupt ending. Leave space for dialogue and interface sounds.`

각 곡은 아래 프롬프트를 공통 프롬프트 뒤에 붙인다. ‘루프’는 끝과 시작이 자연스럽게 이어지도록 제작하라는 뜻이다. MP3 파일 자체의 간극은 제공 후 실제 청취하며 다듬어야 한다.

| 정확한 경로 (`assets/audio/` 아래) | 재생 장면 | 길이 / 반복 | 추가 프롬프트 |
|---|---|---|---|
| `bgm/title_theme.mp3` | 산문 타이틀 | 90초 / 루프 | `Slow mountain mist opening, low geomungo drone, one lonely daegeum melody, dignified restrained resolve, 68 BPM.` |
| `bgm/story_theme.mp3` | 일상 도입, 조용한 동료 교류 | 120초 / 루프 | `Warm quiet conversation by a wooden kitchen, sparse gayageum motifs, soft room ambience, no dramatic crescendos, 62 BPM.` |
| `bgm/awakening_theme.mp3` | 첫 비술과 채주 취임 사건 | 75초 / 루프 | `A displaced modern traveler hears a mountain answer him, glassy bell over bamboo flute, uncertainty opening into wonder, 72 BPM.` |
| `bgm/companion_theme.mp3` | 포로·문객 등용 후 첫 대화 | 75초 / 루프 | `A wary alliance turning into trust, gentle plucked duet, grounded human warmth, avoid romance fanfare, 78 BPM.` |
| `bgm/hub_theme.mp3` | 지도와 산채 정비, 인연 목록 | 120초 / 루프 | `Busy humble mountain stronghold, workers and cooking smoke, light janggu pulse, patient planning, cheerful without comedy, 86 BPM.` |
| `bgm/departure_theme.mp3` | 출정 편성 | 60초 / 루프 | `Preparing packs and tightening sword belts at dawn, steady low drum heartbeat, anticipation without combat climax, 90 BPM.` |
| `bgm/exploration_theme.mp3` | 미확인 세 산길 | 100초 / 루프 | `Hidden mountain trails, damp pine forest, distant stone chimes, sparse pulses and suspended harmony, tense quiet, 74 BPM.` |
| `bgm/event_theme.mp3` | 점령 후 표국·가문·문파 사건, 인연 장면 | 120초 / 루프 | `An unfinished promise and careful negotiation, bittersweet flute with restrained strings, flexible emotional neutrality, 70 BPM.` |
| `bgm/battle_low_theme.mp3` | 달개울·안개재 등 전력 65 미만 | 100초 / 루프 | `Scrappy mountain skirmish, agile plucked ostinato, crisp janggu, readable steady rhythm, adventurous 118 BPM.` |
| `bgm/battle_mid_theme.mp3` | 전력 65~99 산채 | 100초 / 루프 | `Organized martial clash, interlocking drum patterns and urgent geomungo, tactical suspense, 126 BPM.` |
| `bgm/battle_high_theme.mp3` | 백운령 등 전력 100 이상 | 110초 / 루프 | `Dangerous ridge battle, relentless grounded percussion, sweeping but dark bamboo melody, high stakes, 134 BPM.` |
| `bgm/midboss_theme.mp3` | 철마산 | 110초 / 루프 | `An undefeated armored commander, heavy low drums, stern brass-like reed tone, overwhelming but conquerable, 124 BPM.` |
| `bgm/final_boss_theme.mp3` | 태백총채 | 130초 / 루프 | `Eight mountain banners meet, final duel against the old chief, transform the lonely title flute into decisive ensemble, 138 BPM.` |
| `bgm/reward_theme.mp3` | 승리 후 전리품 선택 | 50초 / 루프 | `Exhale after danger, sunlight on scattered weapons, brief earned triumph then calm sparse plucks, 82 BPM.` |
| `bgm/defeat_theme.mp3` | 패배·철수 보고 | 60초 / 루프 | `Wounded companions returning home, subdued low flute, tired footsteps implied by gentle drum, hope remains, 58 BPM.` |
| `bgm/ending_theme.mp3` | 본편 결말과 인물 후일담 | 130초 / 루프 | `A shared dinner after a long war, return of the main mountain melody, tender and earned, small ensemble rather than bombast, 66 BPM.` |

상점 방은 이번 버전에 없다. 향후 상점 장면을 추가할 때 사용할 예비 파일은 `bgm/shop_theme.mp3`이다. 90초 루프, `Small roadside trader, playful restrained geomungo and wooden taps, shrewd friendly bargaining, 92 BPM.` 현재는 자동 재생되지 않는다.

## ElevenLabs SFX

공통 프롬프트: `Isolated game sound effect, no speech, no music, clean transient, short natural decay, no clipping, centered stereo.` WAV로 내보낸다. 아래 표의 파일을 `assets/audio/sfx/`에 넣는다. 효과음은 모두 1회 재생한다.

| 파일명 | 현재 트리거 | 권장 길이 | 추가 프롬프트 |
|---|---|---|---|
| `ui_confirm.wav` | 버튼 확인 | 0.12초 | `A soft wooden seal tap on folded paper, crisp but not bright.` |
| `ui_denied.wav` | 자원 부족 등 명령 실패 | 0.2초 | `Two low muted wooden ticks, gentle rejection without an alarm.` |
| `card_use.wav` | 선택한 무공 카드가 나감 | 0.25초 | `One stiff parchment card whisked quickly across a wooden table.` |
| `card_draw.wav` | 첫 손패와 매 합 드로우 | 0.5초 | `Five stiff paper cards fanning into a hand, sequential dry flutters.` |
| `card_discard.wav` | 턴 종료 후 남은 패를 버림 | 0.35초 | `A small group of parchment cards sliding together into a discard pile.` |
| `deck_shuffle.wav` | 버린 카드 재섞기 | 0.65초 | `A compact flutter of thick parchment cards being shuffled, clean rapid sequence.` |
| `enemy_attack.wav` | 적 행동 | 0.6초 | `Heavy polearm accelerating through air with a leather armor creak, weighty controlled attack.` |
| `enemy_hit.wav` | 참격 명중 | 0.35초 | `A sword striking lamellar armor and heavy cloth, metallic edge with a blunt body impact, no gore.` |
| `enemy_defeat.wav` | 적 소멸 | 0.9초 | `Armor settling onto earth, weapon lowering and a short gust dispersing, no voice.` |
| `shield.wav` | 호신·지휘 | 0.5초 | `Low resonant wooden gong with a short protective airy ring, subtle martial energy.` |
| `heal.wav` | 의술·회복약 | 0.6초 | `Small ceramic vial opening followed by a warm gentle bell shimmer.` |
| `reward.wav` | 전리품 화면 | 0.7초 | `A folded scroll unfurls with a small jade chime, modest earned success.` |
| `you_attack.wav` | 강현 일반 공격 | 0.4초 | `A novice short sword swipe, cloth sleeve and a quick gust.` |
| `you_strong_attack.wav` | 강현 파산격 | 0.7초 | `Paper talisman snap, quick compressed wind pulse and decisive short blade impact.` |
| `yeon_attack.wav` | 담연화 일반 공격 | 0.45초 | `Single-edged saber cutting the air, leather wrist guard creak, firm grounded slash.` |
| `yeon_strong_attack.wav` | 담연화 파산격 | 0.8초 | `Weighty saber overhead preparation and a forceful diagonal cut, short low impact tail.` |
| `seo_attack.wav` | 서하린 일반 공격 | 0.35초 | `Fast courier short sword thrust, light travel cloth flutter, precise sharp finish.` |
| `seo_strong_attack.wav` | 서하린 파산격 | 0.65초 | `Two rapid rushing steps and a decisive short sword lunge, nimble whoosh.` |
| `yun_attack.wav` | 윤서령 일반 공격 | 0.45초 | `A refined straight sword draws a thin clear arc, polished metal whisper.` |
| `yun_strong_attack.wav` | 윤서령 파산격 | 0.8초 | `Focused breath-like air compression, ringing straight blade stroke with elegant force.` |
| `so_attack.wav` | 백소하 일반 공격 | 0.4초 | `A tiny concealed needle flick and silk sleeve flutter, dry precise tick.` |
| `so_strong_attack.wav` | 백소하 파산격 | 0.7초 | `A folded fan snaps open and releases a cluster of fine needles through air, subtle herbal hiss.` |

추가 등용 인물도 동일하게 `gil_attack.wav`, `beom_attack.wav`, `ha_attack.wav`, `ryu_attack.wav`와 각 `_strong_attack.wav`를 넣을 수 있다. 창은 긴 바람 가르기, 중병기는 낮은 금속 충격, 책사는 얇은 암기음을 권장한다.

예비 확장 파일: `system_window_open.wav`, `system_window_close.wav`, `battle_start.wav`, `boss_clear.wav`. 이후 연출을 확장할 때 연결한다. 현재 호출하지 않는 예비 파일을 연결 완료라고 간주하지 않는다.
