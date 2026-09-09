"""检查发布文件并打包；不上传网络，不包含测试日志和设备状态。"""
from pathlib import Path
import hashlib
import json
import zipfile
import struct
import zlib

root = Path(__file__).resolve().parents[1]
package = root / 'package'
metadata = dict(line.split('=',1) for line in (package/'app.info').read_text(encoding='utf-8').splitlines() if '=' in line)
metadata = {k.strip():v.strip() for k,v in metadata.items()}
assert metadata['kind']=='app' and metadata['category']=='clock' and metadata['catalog_scope']=='community'
required = ['app.info',metadata['entry'],metadata['icon'],'info.html','chinese12.bin','chinese13.bin','chinese16.bin','calendar.lua','lunar_data.lua','preferences.lua','skins.lua','motion.lua']
for size in ('small','large'):
    for theme in ('dark','light','amber','ice','violet','cream','blood'):
        required.extend([f'skins/{size}-{theme}.idx',f'skins/{size}-{theme}.dat'])
for name in required:
    path = package/name
    assert path.is_file() and path.stat().st_size>0,name
    if name.endswith('.idx'):
        index=path.read_bytes();assert len(index)==960,name
        data=path.with_suffix('.dat').read_bytes()
        expected=94*100*2 if path.name.startswith('small-') else 140*116*2
        end=0
        for offset,length in struct.iter_unpack('<II',index):
            assert offset==end and length>0 and offset+length<=len(data),name
            assert len(zlib.decompress(data[offset:offset+length]))==expected,name
            end=offset+length
        assert end==len(data),name
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
