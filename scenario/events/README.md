# 철마산역 실제 대본 편집

이 폴더는 지역 사건의 **실행 원본**이다. 사용자 전체 대본·설계는 상위 scenario 폴더에 그대로 보존되어 있다. 전체 문서를 다시 고쳤다면 변경된 사건을 비교해서 이 폴더에 반영해야 한다. 자동으로 산문을 재해석하여 덮어쓰지 않는다.

- 대사: `chapters/<사건 ID>/*.md`. 기존 ID를 유지하며 `대사:` 아래를 편집한다. 한 ID = 한 화면. 줄바꿈은 그대로 표시한다.
- 사건 순서/선택/보상/조건: `catalog.json`. `nodes`에서 MD 대사 ID 목록과 다음 노드를 연결한다.
- 인물 배치/움직임: 이 폴더의 `staging.json`.
- 장소/날짜/시간 전환: 이 폴더의 `presentation.json`. `live:true`는 현재 게임 날짜·시간대다.
- 새 MD: `manifest.json` 목록에도 추가한다.
- 적용: 루트 `대사_적용.bat`. 프롤로그와 지역 대본을 함께 검사한다.

다른 Chat에는 수정할 MD와 catalog의 해당 사건, staging/presentation의 관련 부분, 상위 `시나리오_대본과_연출_편집매뉴얼.md` 및 [EVENT_SYSTEM.md](../../docs/EVENT_SYSTEM.md)를 전달한다.

현재 마영란 그림은 등록되어 있지 않다. 이미지를 새로 등록하기 전까지 빈 인물 배치를 유지한다. 기존 NPC를 다른 역할로 재활용하지 않는다. 미구현 선택은 `pending:true`로 남아 있으며 대사 몇 줄만 바꾼다고 그 기능까지 생기지는 않는다.

초기 등록용 import/configure/extend 스크립트는 다시 실행하지 않는다. `source_registry.json`은 원문 보관용이며 런타임의 편집 원본은 catalog와 MD다.
