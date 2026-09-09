"""下载香港天文台对照表到临时目录，用于独立农历测试。"""
from pathlib import Path
from urllib.request import urlopen
root=Path(__file__).resolve().parents[1]
(root/'_temp').mkdir(exist_ok=True)
for year in range(2024,2031):
    url=f'https://www.hko.gov.hk/tc/gts/time/calendar/text/files/T{year}c.txt'
    with urlopen(url,timeout=20) as response: data=response.read()
    (root/f'_temp/T{year}c.txt').write_bytes(data)
    print(year,'OK')
