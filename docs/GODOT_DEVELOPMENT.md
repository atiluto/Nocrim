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

공유용 소스 ZIP은 로컬 SDK 경로를 비웠다. Godot 편집기에서 같은 버전의 Export Templates를 설치하고 Windows Desktop 내보내기를 사용한다. 원본 작업 폴더는 로컬 템플릿 경로가 지정되어 있어 `python tools/godot_task.py --headless --export-release 'Windows Desktop'`로 내보낼 수 있다. 결과는 `releases/Nocrim-Godot-0.2.0-win`에 나온다.

리소스 팩과 실행 파일만으로 동작하는지 확인할 때는 `python tools/godot_task.py release --audio-driver Dummy -- --ui-test`를 사용한다. 이 경로는 소스 프로젝트를 실행 경로로 지정하지 않는다. 결과 확인 후 `python tools/package_godot.py`로 배포본·소스 ZIP을 만든다.

기존 Ren’Py 자료는 `game`과 이전 `docs`에 남겨 두었다. `tools/export_godot_content.py`는 최초 이전에 사용한 도구다. Godot 데이터를 수정한 뒤 이 도구를 무심코 다시 실행하면 이전 Ren’Py 원문으로 덮어쓰므로, 현재 게임의 이야기 수정은 `godot/data/world.json`에서 한다.

저장 파일의 버전은 2다. 앞으로 저장 필드를 바꾸면 `persistence.gd`에 명시적인 이전 코드를 추가하거나 버전을 올려야 한다. 저장 데이터는 객체 복원 없이 읽으며, 난수와 딕셔너리 순서를 보존하기 위해 Godot Variant 직렬화를 사용한다.
