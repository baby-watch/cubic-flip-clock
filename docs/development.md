# 开发与资源构建

普通安装不需要运行本页命令。字体、农历表和数字资源已经随应用提供。

## 构建

安装 requirements-build.txt 中的 Python 依赖和 package.json 中的开发依赖。

- `python tools/build_text_fonts.py`：从仓库的开放字体子集生成设备字体。
- `npm run build:lunar`：生成农历月份表。
- `python tools/build_skin_assets.py`：生成七种皮肤的逐卡压缩图片，需要本机 Arial Bold；黑白普通帧沿用已有 RGB565 数据。
- `python tools/package_release.py`：检查部署文件并生成 ZIP 和校验清单，仅打包不需要 Pillow。

更改数字资源后需要重新进行实机视觉验收。普通安装只需复制 package 内的文件。

## 验证

运行 `python tools/fetch_calendar_references.py` 获取香港天文台对照表，再运行 `npm run test:calendar`。日期测试直接执行设备所用的 Lua 模块。

`tools/test_preferences.lua` 覆盖旧设置迁移、七种皮肤、两种翻页模式以及存储失败。

`tools/test_motion.lua` 检查回弹高度范围、两次回弹幅度和最终落稳。

`tools/test_renderer.lua` 用画布模拟器执行正式 renderer.lua，与旧算法逐像素对照，包含定时跳帧、重复帧和新动画覆盖未完成画面。

`tools/test_prefetch.lua` 检查预读窗口、跨日进位、隐藏秒、动画避让和校时后失效缓存释放。时、分图片仅在进位前三秒预读，秒图片保持原策略；每次定时回调最多预读一张。

长时只读观察：`python tools/observe_device.py --url http://设备当前IP --hours 24 --output _temp/endurance`。电脑需保持运行与设备网络可达；设备需已开启 diagnostics.flag。输出 samples.jsonl 和 summary.json，完成后仍需人工区分用户退出、网络中断与真实故障，不自动给出无泄漏结论。

诊断时在应用目录创建 diagnostics.flag，可每十秒写入 status.json；删除后重新打开应用即可停用。诊断不自动截图。不要把用户设置、诊断开关和运行日志放入安装包。

## 官方参考

- [Lua API 与生命周期](https://github.com/clocteck/holocubic-apps/blob/main/README_LUA.md)
- [LVGL 绘图 API](https://github.com/clocteck/holocubic-apps/blob/main/README_LVGL.md)
- [官方应用示例](https://github.com/clocteck/holocubic-apps)

holocubic-nes-esp32 是 NES 动态模块项目，不是完整系统固件源码。
