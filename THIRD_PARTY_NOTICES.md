# 第三方资源来源

## 中文字体：SIL Open Font License 1.1

中文字体由 Noto Sans SC Regular 的开放字体子集构建。源字体的 name 表明确包含 SIL Open Font License 1.1 声明，版权为 © 2014–2021 Adobe，保留名称为 Source。

本项目将字体实例化为字重 400，仅保留应用所需字符，重命名为 Cubic Clock CJK；源子集为 assets/fonts/CubicClockCJK.ttf，设备二进制为 package/chinese12.bin、chinese13.bin、chinese16.bin。原始源文件的版本、SHA-256、内嵌版权和许可记录在 assets/fonts/source.json。完整许可与版权声明见 licenses/OFL-NotoSansCJK.txt。

这批字体替换了早期从天气应用复制、未确认对应来源的中文字体。新字体不适用项目 MIT 许可，而依 OFL 分发。

## 农历数据：MIT

package/lunar_data.lua 由 lunar-javascript 1.7.7 生成，作者 6tail，Copyright (c) 2018 6tail，许可全文见 licenses/lunar-javascript-MIT.txt。原项目：https://github.com/6tail/lunar-javascript 。设备只使用日期月表，不包含库中命理、黄历等其他功能。

香港天文台的年度公农历表仅下载到 _temp 用作独立测试，不打入应用。官方参考入口：https://www.hko.gov.hk/tc/gts/time/conversion.htm 。

## 数字图片

package/*.rgb 以及 package/skins/ 下的压缩数字图片由本项目使用 Windows 本机 Arial Bold 绘制，不包含或分发 Arial TTF/OTF 文件。黑白普通帧保留已验收外观；重新构建需要合法可用的本机字体。Arial 字体本身不适用本项目 MIT 许可。

## API 参考

接口参考 Clocteck holocubic-apps 仓库。项目并非官方产品；第三方商标归各自权利人所有。
