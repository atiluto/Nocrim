# Godot에서 수정하기

`godot/project.godot`를 Godot 4.7.2 표준판으로 가져온다. 게임은 GDScript로 동작하며 Python 런타임과 C#/.NET은 사용하지 않는다. Python 파일은 개발 편의용이며 게임의 의존성이 아니다.

| 경로 | 역할 |
|---|---|
| `godot/data/world.json` | 8개 산, 인물, 사건·선택지, 본편 결말 |
| `godot/scripts/campaign.gd` | 원자적 명령 처리, 점령·내정·등용·인연·침공·카드 전투 |
| `godot/scripts/main.gd` | 타이틀·지도·편성·탐색·전투·대화·보상·결말 화면과 연출 |
| `godot/scripts/story.gd` | 현대 도입부, 개인 교류, 인연·우정 후일담 |
| `godot/scripts/assets.gd` | 외부 에셋 우선 로딩과 누락 시 대체 표시 |
| `godot/scripts/sound.gd` | 두 음악 채널 교차 전환, 효과음 8채널 |
| `godot/scripts/persistence.gd` | 진행 저장, 백업, 결말 수첩 |
| `godot/tests/test_campaign.gd` | 행동·저장·분기·결말 규칙 검사 |
| `godot/tests/ui_test.gd` | 실제 렌더링과 Godot 입력 이벤트를 통한 클릭 검사 |

원본 작업 폴더에서는 `python tools/bootstrap_godot.py`가 공식 바이너리와 Windows 템플릿을 `.tools/godot`에 내려받아 공식 체크섬과 대조한다. `python tools/godot_task.py --headless --editor --import --quit`로 가져오기, `python tools/godot_task.py --headless --script res://tests/test_campaign.gd`로 규칙 검사, `python tools/godot_task.py --audio-driver Dummy -- --ui-test`로 화면 검사를 실행한다. 테스트 저장은 `tests/godot-saves`에 분리된다.

일반 플레이는 루트의 `play.bat`을 더블클릭한다. 포함된 Godot가 리소스를 가져온 뒤 현재 프로젝트를 직접 실행한다. Python과 내보내기 과정은 필요 없다. BAT 파일만 다른 곳으로 옮기지 않는다.

BAT 플레이 저장은 `.local/play-saves`, 가져오기 기록은 `.local/import.log`, 실행 기록은 `.local/play.log`다. 자동 검사 저장인 `tests/godot-saves`와 분리된다. 짧은 시작 검사는 `play.bat --headless --quit-after 5`로 실행할 수 있다.

이야기는 `godot/data/world.json`에서 수정한다. `python tools/make_branch_reference.py`로 현재 사건 데이터에 맞춘 선택지 목록을 `docs/BRANCHES.md`에 갱신한다. 이전 엔진의 소스와 이전 도구는 제거했으며, 그림과 글꼴은 `godot/assets`에 독립적으로 들어 있다.

저장 파일의 버전은 2다. 앞으로 저장 필드를 바꾸면 `persistence.gd`에 명시적인 이전 코드를 추가하거나 버전을 올려야 한다. 저장 데이터는 객체 복원 없이 읽으며, 난수와 딕셔너리 순서를 보존하기 위해 Godot Variant 직렬화를 사용한다.
