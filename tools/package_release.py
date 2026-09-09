"""检查发布文件并打包；不上传网络，不包含测试日志和设备状态。"""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parents[1]
package = root / 'package'
metadata = dict(line.split('=',1) for line in (package/'app.info').read_text(encoding='utf-8').splitlines() if '=' in line)
metadata = {k.strip():v.strip() for k,v in metadata.items()}
assert metadata['kind']=='app' and metadata['category']=='clock' and metadata['catalog_scope']=='community'
required = ['app.info',metadata['entry'],metadata['icon'],'info.html','chinese12.bin','chinese13.bin','chinese16.bin','calendar.lua','lunar_data.lua','preferences.lua','small-dark.rgb','small-light.rgb','large-dark.rgb','large-light.rgb']
sizes = {'small-dark.rgb':1128000,'small-light.rgb':1128000,'large-dark.rgb':1948800,'large-light.rgb':1948800}
for name in required:
    path = package/name
    assert path.is_file() and path.stat().st_size>0,name
    if name in sizes: assert path.stat().st_size==sizes[name],name
assert (package/'main.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
release = root/'releases'
release.mkdir(exist_ok=True)
target = release/f"flip-clock-{metadata['version']}-candidate.zip"
hashes = {}
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as archive:
    for name in required:
        data=(package/name).read_bytes()
        archive.writestr(name,data)
        hashes[name]=hashlib.sha256(data).hexdigest()
    for source,dest in [('LICENSE','LICENSE'),('THIRD_PARTY_NOTICES.md','THIRD_PARTY_NOTICES.md'),('licenses/OFL-NotoSansCJK.txt','licenses/OFL-NotoSansCJK.txt'),('licenses/lunar-javascript-MIT.txt','licenses/lunar-javascript-MIT.txt')]:
        archive.write(root/source,dest)
(release/'checksums.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
print(f'已验证 {len(required)} 个部署文件，生成 {target.name}；候选包尚非社区审核通过版本。')
