"""生成独立数字图集：每次只读取一个数字卡片，不整包加载到设备内存。"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import struct

out = Path(__file__).resolve().parents[1] / 'package'
out.mkdir(exist_ok=True)
for large, width, height, size in [(False,94,100,68),(True,140,116,85)]:
    font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', size * 3)
    for light in [False,True]:
        path = out / ('%s-%s.rgb' % ('large' if large else 'small', 'light' if light else 'dark'))
        with path.open('wb') as stream:
            for number in range(60):
                ink = '#000000' if light else '#ffffff'
                image = Image.new('RGB', (width*3,height*3), '#ffffff' if light else '#111111')
                draw = ImageDraw.Draw(image)
                draw.rectangle((0,height*3//2,width*3,height*3), fill='#f3f3f3' if light else '#181818')
                text = f'{number:02d}'
                # 与浏览器的负字间距一致，两个数字分别定位，避免字形过宽。
                advance = font.getlength('0') - 9
                full = advance + font.getlength('0')
                x = (width*3-full)/2
                for digit in text:
                    draw.text((x,height*3/2),digit,font=font,fill=ink,anchor='lm')
                    x += advance
                image = image.resize((width,height),Image.Resampling.LANCZOS)
                for r,g,b in image.getdata():
                    stream.write(struct.pack('<H', ((r>>3)<<11)|((g>>2)<<5)|(b>>3)))
                if number == 12:
                    image.save(out / ('sample-%s-%s.png' % ('large' if large else 'small','light' if light else 'dark')))
print('图集已生成')
