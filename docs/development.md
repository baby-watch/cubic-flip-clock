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

`tools/test_preferences.lua` 覆盖旧设置迁移、七种皮肤、三种翻页模式以及存储失败。

诊断时在应用目录创建 diagnostics.flag，可每十秒写入 status.json；删除后重新打开应用即可停用。诊断不自动截图。不要把用户设置、诊断开关和运行日志放入安装包。

## 官方参考

- [Lua API 与生命周期](https://github.com/clocteck/holocubic-apps/blob/main/README_LUA.md)
- [LVGL 绘图 API](https://github.com/clocteck/holocubic-apps/blob/main/README_LVGL.md)
- [官方应用示例](https://github.com/clocteck/holocubic-apps)

holocubic-nes-esp32 是 NES 动态模块项目，不是完整系统固件源码。
