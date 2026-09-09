"""从应用已有数字资源生成桌面图标，不额外引入字体。"""
from pathlib import Path
from PIL import Image, ImageDraw
import struct

package=Path(__file__).resolve().parents[1]/'package'
image=Image.new('RGB',(128,128),'#08090a')
draw=ImageDraw.Draw(image)
draw.rounded_rectangle((1,1,126,126),radius=23,fill='#151619',outline='#393a3c',width=2)
for n,x in [(12,9),(34,68)]:
    raw=(package/'small-dark.rgb').read_bytes()[n*18800:(n+1)*18800]
    pixels=[]
    for (v,) in struct.iter_unpack('<H',raw):
        pixels.append(((v>>11)*255//31,((v>>5)&63)*255//63,(v&31)*255//31))
    card=Image.new('RGB',(94,100));card.putdata(pixels)
    card=card.resize((51,57),Image.Resampling.LANCZOS)
    mask=Image.new('L',card.size);ImageDraw.Draw(mask).rounded_rectangle((0,0,50,56),radius=5,fill=255)
    image.paste(card,(x,35),mask)
    draw.line((x,63,x+50,63),fill='#050505',width=1)
draw.ellipse((57,107,61,111),fill='#eeeeee')
draw.ellipse((66,107,70,111),fill='#777777')
image.save(package/'main.png')
print('main.png: 128x128')
