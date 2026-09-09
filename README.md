# Cubic 翻页时钟

为 Clocteck Cubic / Holocubic 的 320×240 显示屏制作的 Lua 翻页时钟。

![早期开发版设备截图（尚未包含年份和农历）](docs/device-preview.png)

## 功能与操作

- 默认显示时、分、秒，数字变化时执行上下半页翻动动画。
- 左倾并保持至触发：切换黑底白字、白底黑字。
- 右倾并保持至触发：切换时分秒、仅时分；隐藏秒后放大时分卡片。
- 每次 `LONG_START` 操作一次，忽略持续倾斜的重复事件。
- 配色与秒显示在切换时保存到应用目录的 `settings.json`，退出重开时恢复；首次启动默认黑底白字、显示秒。升级请保留此文件。网页预览单独保存在浏览器中，与设备不互通。
- 公历按 yyyy年M月d日 显示，日期和星期采用 16 像素白字；农历独占第二行，采用 13 像素白字；“北京时间”保持白字，右上角显示秒模式图标。
- 应用面板透明；底层屏幕以黑色清屏，防止局部刷新残影。透明不代表设备支持任意背景合成。

## 安装

使用支持 SD 应用和 DevTools 的 Cubic 固件。在设备开发工具中，将 `package/` 的内容上传至 `/sd/apps/flip-clock/`，然后重新扫描应用并打开 Flip Clock。

不要多套一层 `package` 目录，不要只上传 `main.lua`。数字图集和中文字体均为运行必需资源。不要上传整个开发仓库。

## 版本与验证

- 发布包元数据版本：1.0.0。
- 已测试固件：1.210，屏幕 320×240。
- 已由设备使用者确认：左右倾斜、两种配色、秒显示切换、翻页效果符合预期。
- 清屏修订后的实机效果已验收；短时负载测量不等于长期稳定性证明。
- 1.0.0 增加年份、放大日期和农历，替换为来源可追溯的 Noto 中文子集；保持已验收的数字卡片和清屏方案。
- 农历范围为 1900—2100 年，超出范围明确提示；已与香港天文台 2024—2030 年 2,557 天对照表逐日核验。
- 应用退出和重新进入可用；生命周期通过官方 app-lifecycle IPC 通道检查。固件不承诺调用 app.on("exit")，应用不依赖此钩子。详见 [生命周期与验证](docs/validation.md)。

应用读取系统当地时间，不自行修改 NTP 或时区。界面写有“北京时间”，请在设备设置中使用北京时间（UTC+8）；系统时间未同步时显示等待提示。

## 仓库内容

| 路径 | 内容 |
| --- | --- |
| `package/` | 直接部署到设备的完整应用 |
| `tools/build_assets.py` | 使用本机字体重新生成数字图集 |
| `tools/package_release.py` | 检查文件并生成发布 ZIP 与校验清单 |
| `docs/validation.md` | 已验证范围和剩余问题 |
| `docs/community-submission.md` | 社区上架流程和邮件草稿 |
| `THIRD_PARTY_NOTICES.md` | 字体与其他资源来源 |

打包：`python tools/package_release.py`。重新生成数字图集需要 Python、Pillow 和本机 Arial Bold 字体；它会改变资源文件，发布前应重新进行实机视觉验收。仅打包不需要 Pillow。

## 许可与社区状态

本项目原创代码采用 MIT 许可；第三方资源单独说明，不受项目 MIT 许可覆盖。

1.0.0 已上传公开仓库 [baby-watch/cubic](https://github.com/baby-watch/cubic)，尚未发送审核邮件或获得社区上架批准。字体内嵌 OFL 授权、源文件哈希、命名独立的子集和版权声明已保存；农历生成工具的 MIT 许可已保留。

## 重建日期资源

先安装 requirements-build.txt 和 package.json 的开发依赖。运行 `python tools/build_text_fonts.py` 从仓库自带开放字体子集生成设备字体；运行 `npm run build:lunar` 生成农历表。

运行 `python tools/fetch_calendar_references.py` 获取官方对照表，再运行 `npm run test:calendar`，测试直接执行设备使用的 Lua 查询函数。测试资源位于被 Git 忽略的 `_temp/`。

正式运行默认不写入周期日志、不自动截图；仅验证时创建应用目录下的 diagnostics.flag，验证后删除。
