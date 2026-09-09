"""从内嵌 OFL 授权的 Noto Sans SC 构建命名独立、可分发的中文子集。"""
from pathlib import Path
import argparse, hashlib, json, subprocess
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset

root=Path(__file__).resolve().parents[1]
symbols='北京时间等待系统校时年月日星期一二三四五六七八九十农历闰正冬腊初廿三超出范围0123456789 /-'
parser=argparse.ArgumentParser()
parser.add_argument('--source',type=Path)
args=parser.parse_args()
target=root/'assets/fonts/CubicClockCJK.ttf'
target.parent.mkdir(parents=True,exist_ok=True)
if args.source:
    font=TTFont(args.source)
    def name(i):
        values=[x.toUnicode() for x in font['name'].names if x.nameID==i]
        return values[0] if values else ''
    assert 'Open Font License' in name(13),'源字体必须带有明确的 OFL 许可声明'
    meta={'source_filename':args.source.name,'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest(),
          'family':name(1),'version':name(5),'copyright':name(0),'license':name(13),'license_url':name(14),
          'weight':400,'symbols':''.join(sorted(set(symbols)))}
    if 'fvar' in font: font=instantiateVariableFont(font,{'wght':400},inplace=False)
    options=subset.Options();options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*']
    engine=subset.Subsetter(options=options);engine.populate(text=symbols);engine.subset(font)
    for record in font['name'].names:
        if record.nameID in (1,4,6,16,17,2):
            value={1:'Cubic Clock CJK',4:'Cubic Clock CJK Regular',6:'CubicClockCJK-Regular',16:'Cubic Clock CJK',17:'Regular',2:'Regular'}[record.nameID]
            record.string=value.encode(record.getEncoding(),errors='replace')
    font.save(target)
    (root/'assets/fonts/source.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
assert target.is_file(),'先提供 --source 生成字体子集，或使用仓库中的已授权子集'
converter=root/'node_modules/lv_font_conv/lv_font_conv.js'
if not converter.exists(): converter=root/'_temp/build/node_modules/lv_font_conv/lv_font_conv.js'
for size in (12,13,16):
    subprocess.run(['node',str(converter),'--font',str(target),'--symbols',symbols,'--size',str(size),
      '--bpp','4','--format','bin','--no-compress','-o',str(root/f'package/chinese{size}.bin')],check=True)
print('font subsets: 12 / 13 / 16 px')
