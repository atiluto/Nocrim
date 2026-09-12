# 마젠타 PNG 배경 제거기

## 가장 쉬운 사용법

1. 배포 ZIP의 압축을 풀고 `MagentaCutoutTool.exe`를 더블클릭합니다. Windows 64비트용이며 Python 설치 없이 실행합니다.
2. `PNG 추가`를 눌러 마젠타 배경 이미지를 한 장 이상 고릅니다. 기본 제거 색상은 **#FF00FF / RGB(255, 0, 255)**입니다.
3. 오른쪽의 체크무늬 미리보기에서 투명 결과를 확인합니다.
4. `목록 전체 변환`을 누릅니다. 목록의 선택 표시는 미리보기·목록 삭제용이며, 변환은 목록 전체에 적용합니다.
5. 원본 옆에 `원본이름_alpha.png`가 생성됩니다. 원본 파일은 변경하지 않습니다.
6. 기본 파일명으로 바로 받고 싶으면 **원본과 다른 출력 폴더**를 선택하고 `별도 폴더에 원래 이름으로 저장`을 켭니다. 예: `결과/rio_attack.png`.

원본 파일은 덮어쓰기 옵션을 켜도 보호합니다. 이미 있는 결과만 `기존 결과 PNG 덮어쓰기` 옵션으로 교체할 수 있습니다. 원래 이름 저장을 켰다면 해당 이름의 기존 결과가 교체됩니다.

## 조절 항목

- `배경색 RGB`: 기본 #FF00FF. 다른 마젠타 값은 직접 입력하거나 색 선택 버튼을 씁니다. 이미지 모서리에서 흰색을 자동 추정하지 않습니다.
- `완전 제거 허용 범위`: 기본 8. 기준색과 아주 비슷한 부분을 완전히 투명하게 만듭니다.
- `가장자리 색 허용 범위`: 기본 80. 압축이나 경계 혼합으로 색이 조금 달라진 부분을 부드럽게 지웁니다. 완전 제거 값보다 커야 합니다.
- `테두리 부드러움`: 외곽선의 알파 전환을 부드럽게 합니다.
- `둘러싸인 마젠타 구멍도 제거`: 기본 켜짐. 머리카락·활시위·다리 사이에 갇힌 작은 마젠타 배경도 제거합니다. 끄면 외곽과 연결된 부분만 지웁니다.
- `가장자리 마젠타색 복원`: 기본 켜짐. 반투명 경계에 섞인 마젠타색을 보정합니다. 원래 색이 달라 보이면 끄고 비교합니다.
- `결과 미리보기 배경`: 체크무늬, 어두운 배경, 흰 배경. 저장 이미지에는 이 배경이 들어가지 않습니다.

흰 머리·흰 옷은 기본 마젠타 기준색과 다르므로 보존합니다. 다만 피사체에도 배경과 같은 마젠타색이 있으면 색상만으로 구분할 수 없어 같이 지워질 수 있습니다. 이 경우 구멍 제거를 끄거나 배경색을 바꿔 제작하세요.

## 이 방식이 잘 맞는 이미지

- 배경이 균일한 마젠타색인 PNG
- 캐릭터 외곽선이 배경과 어느 정도 구분되는 일러스트
- 흰 머리·흰 옷처럼 내부의 흰 부분을 보존해야 하는 이미지

배경의 그림자·그라데이션·진한 분홍색 테두리가 많으면 허용 범위를 조절하거나 마스크를 보정해야 할 수 있습니다. 기본 마젠타 모드로 흰 배경 사진을 열어도 흰색을 자동으로 지우지 않습니다.

이미지 생성 도구에 넣을 배경 지시 예:

> 배경 전체를 완전히 균일한 단색 마젠타 #FF00FF, RGB(255, 0, 255)로 만들어줘. 배경에 그림자, 질감, 그라데이션, 바닥, 광원 효과를 넣지 마. 인물과 장비에는 이 마젠타색을 사용하지 마. 머리카락과 무기 끝을 캔버스 안에 모두 넣어줘.

## 배포 파일 구성

- `MagentaCutoutTool.exe`: 설치 없이 실행하는 Windows 64비트 프로그램.
- `MAGENTA_CUTOUT_TOOL.bat`: 같은 폴더의 EXE를 실행하는 보조 실행 파일.
- `README.md`: 이 사용 안내.
- `tools/alpha_cutout_tool.py`: 수정하거나 다른 프로젝트에서 불러올 Python 소스. 예전 실행기와의 호환을 위해 이름을 유지했지만 기본 동작은 마젠타 제거입니다.
- `tools/alpha_cutout_requirements.txt`: Python 소스 실행용 패키지 목록.
- `tests/test_alpha_cutout_tool.py`: 색상 제거와 원본 보호 검증.
- `samples/magenta_sample.png`, `samples/magenta_sample_alpha.png`: 비교용 합성 샘플.
- `THIRD_PARTY_LICENSES/`: EXE에 포함된 주요 라이브러리의 라이선스 안내.

이 도구는 기존 게임 파일·Godot·게임 저장 데이터가 필요 없습니다. 출력은 원본 해상도를 유지한 RGBA PNG입니다. 고해상도 여러 장을 처리하는 동안 잠시 기다려 주세요.

## Python 소스로 실행할 때

Python이 설치되어 있다면 아래 패키지가 필요합니다.

```powershell
python -m pip install -r tools/alpha_cutout_requirements.txt
```

Python 3.10 이상에서 실행합니다. ZIP의 EXE만 쓸 때는 이 설치 과정이 필요 없습니다. 프로젝트 안에서는 `MAGENTA_CUTOUT_TOOL.bat` 또는 기존 `ALPHA_CUTOUT_TOOL.bat`으로도 Python 버전을 열 수 있습니다.

## 명령줄 사용법

```powershell
python tools/alpha_cutout_tool.py image1.png image2.png
```

출력 폴더를 지정하려면 다음과 같이 실행합니다.

```powershell
python tools/alpha_cutout_tool.py image1.png --output-dir converted
```

원래 파일명을 유지하려면:

```powershell
python tools/alpha_cutout_tool.py image1.png --output-dir converted --keep-name
```

색과 가장자리를 조정하려면:

```powershell
python tools/alpha_cutout_tool.py image1.png --key-color FF00FF --hard 8 --soft 80 --feather 0.35
```

`--keep-holes`는 닫힌 마젠타 영역을 보존하고, `--no-decontaminate`는 경계 색 복원을 끕니다. `--overwrite`는 결과 파일만 교체합니다. 소스에서 가져와 쓸 때는 `remove_border_background(image, key_color="#FF00FF")`를 호출하면 됩니다.

이 배포본은 합성 샘플로 흰색 보존·마젠타 제거·작은 구멍·반투명도·한글 파일명·원본 보호를 확인했습니다. 개별 캐릭터 그림은 미리보기에서 결과를 확인한 뒤 변환하세요.
