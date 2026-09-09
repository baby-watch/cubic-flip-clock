"""逐卡压缩七种皮肤及余辉，保留原黑白数字的像素数据。"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import re,struct,zlib,json
root=Path(__file__).resolve().parents[1]
out=root/'package/skins';out.mkdir(exist_ok=True)
def rgb(v):return ((v>>16)&255,(v>>8)&255,v&255)
def raw(image):return b''.join(struct.pack('<H',((r>>3)<<11)|((g>>2)<<5)|(b>>3)) for r,g,b in image.getdata())
skins=[]
for line in (root/'package/skins.lua').read_text(encoding='utf-8').splitlines():
    m=re.search(r"id='(\w+)'.*top=(0x[\da-f]+),bottom=(0x[\da-f]+),ink=(0x[\da-f]+|0),",line)
    if m:skins.append((m[1],*[int(v,0) for v in m.groups()[1:]]))
assert len(skins)==7
manifest={}
for size,w,h,fs in [('small',94,100,68),('large',140,116,85)]:
    font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',fs*3)
    masks=[]
    for n in range(60):
        mask=Image.new('L',(w*3,h*3));d=ImageDraw.Draw(mask)
        advance=font.getlength('0')-9;x=(w*3-advance-font.getlength('0'))/2
        for digit in f'{n:02d}':d.text((x,h*3/2),digit,font=font,fill=255,anchor='lm');x+=advance
        masks.append(mask.resize((w,h),Image.Resampling.LANCZOS))
    for name,top,bottom,ink in skins:
        stem=f'{size}-{name}';index=bytearray();archive=bytearray()
        old=(root/f'package/{stem}.rgb').read_bytes() if name in ['dark','light'] else None
        for n,mask in enumerate(masks):
            bg=Image.new('RGB',(w,h),rgb(top));ImageDraw.Draw(bg).rectangle((0,h//2,w,h),fill=rgb(bottom))
            normal=Image.composite(Image.new('RGB',(w,h),rgb(ink)),bg,mask)
            normal_raw=old[n*w*h*2:(n+1)*w*h*2] if old else raw(normal)
            # 亮色数字加轻微光晕，白底黑字则保留底色，仅使笔画略微变浅。
            bright=tuple(min(255,int(v+(255-v)*.35)) for v in rgb(ink))
            halo=mask.filter(ImageFilter.GaussianBlur(1.25)).point(lambda x:int(x*.45))
            glow=Image.composite(Image.new('RGB',(w,h),bright),bg,ImageChops.lighter(mask,halo))
            for data in [normal_raw,raw(glow)]:
                packed=zlib.compress(data,6)
                assert zlib.decompress(packed)==data
                index.extend(struct.pack('<II',len(archive),len(packed)));archive.extend(packed)
        (out/f'{stem}.idx').write_bytes(index);(out/f'{stem}.dat').write_bytes(archive)
        manifest[stem]={'bytes':len(archive),'width':w,'height':h}
(root/'_temp/skin-assets.json').write_text(json.dumps(manifest,indent=2))
print('Verified 1680 compressed card images; bytes:',sum(x['bytes'] for x in manifest.values()))
