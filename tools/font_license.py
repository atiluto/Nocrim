from pathlib import Path
import urllib.request
root = Path(__file__).resolve().parents[1]
url = "https://raw.githubusercontent.com/adobe-fonts/source-han-sans/master/LICENSE.txt"
data = urllib.request.urlopen(url, timeout=30).read()
if b"SIL OPEN FONT LICENSE" not in data.upper():
    raise SystemExit("Unexpected font license content")
(root / "docs" / "FONT-LICENSE.txt").write_bytes(data)
print("Official Source Han Sans font license included.")
