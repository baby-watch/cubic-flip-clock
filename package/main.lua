-- 正式翻页钟：数字图集按卡片流式读取；左右倾斜使用已验证的 LONG_START。
local DIR, NAME = "/sd/apps/flip-clock/", "CUBIC_FLIP_CLOCK"
local prior = rawget(_G, NAME)
if prior and prior.stop then pcall(prior.stop, "reload") end
local A = {running=true, light=false, seconds=true, cards={}, timers={}, fonts={}, tick=0, flips=0}
local diagnostics=file.exists(DIR.."diagnostics.flag")
_G[NAME] = A
local S = LV_PART_MAIN | LV_STATE_DEFAULT
local status = {version="1.1.0", state="starting", cleanup_errors={}, started=tmr.now()}
local function nowms() return tmr.now()/1000 end
local function report()
  if not diagnostics then return end
  status.theme=A.theme;status.motion=A.motion;status.light=A.light; status.seconds=A.seconds; status.flips=A.flips; status.ticks=A.tick
  status.usage=sys.usage()
  file.putcontents(DIR.."status.json",sjson.encode(status))
end
local function safe(name, fn)
  local ok,e=pcall(fn)
  if not ok then status.cleanup_errors[#status.cleanup_errors+1]=name..":"..tostring(e) end
end
function A.stop(reason)
  if not A.running then return end
  A.running=false
  safe("left",function() key.off(key.LEFT) end)
  safe("right",function() key.off(key.RIGHT) end)
  for _,t in ipairs(A.timers) do safe("timer",function() t:stop(); t:unregister() end) end
  A.timers={}
  if A.panel then safe("panel",function() lv_obj_del(A.panel) end); A.panel=nil end
  for _,f in ipairs(A.fonts) do safe("font",function() lv_font_free(f) end) end
  A.fonts={}; A.cards={}
  status.state="stopped"; status.reason=tostring(reason or "stop")
  pcall(report)
  if rawget(_G,NAME)==A then _G[NAME]=nil end
end
A.shutdown=A.stop
local function reset(o)
  lv_obj_remove_style_all(o)
  lv_obj_clear_flag(o,LV_OBJ_FLAG_SCROLLABLE)
end
local function box(parent,x,y,w,h,color,radius)
  local o=lv_obj_create(parent); reset(o)
  lv_obj_set_pos(o,x,y); lv_obj_set_size(o,w,h)
  lv_obj_set_style_bg_color(o,color,S); lv_obj_set_style_bg_opa(o,255,S)
  lv_obj_set_style_radius(o,radius or 0,S)
  return o
end
local function label(text,x,y,w,font,align)
  local o=lv_label_create(A.panel); reset(o)
  lv_label_set_text(o,text); lv_obj_set_pos(o,x,y); lv_obj_set_width(o,w)
  lv_obj_set_style_text_color(o,0xffffff,S)
  lv_obj_set_style_text_font(o,font,S)
  lv_obj_set_style_text_align(o,align or LV_TEXT_ALIGN_LEFT,S)
  return o
end
local function timeparts()
  -- 只读取系统时钟，不修改其他应用共享的时区和 NTP 配置。
  local t=time.getlocal()
  if type(t)~="table" or not t.year or t.year<2024 then return nil end
  return t
end
local calendar,lunarData,preferences,skins,motion
local function skin() return skins[A.skinIndex] end
local function weekday(y,m,d)
  local offsets={0,3,2,5,0,3,5,1,4,6,2,4}
  if m<3 then y=y-1 end
  return (y+math.floor(y/4)-math.floor(y/100)+math.floor(y/400)+offsets[m]+d)%7+1
end
local function readcard(n,w,h)
  local slot=n*(#A.assetIndex/60)+1
  local offset,length=string.unpack("<I4I4",A.assetIndex,slot)
  local f=assert(file.open(DIR..A.assetStem..".dat","r"),"Cannot open digit asset")
  local ok,data=pcall(function() f:seek("set",offset);return f:read(length) end)
  f:close();if not ok then error(data) end
  local decoded,err=zlib.inflate(data)
  assert(type(decoded)=="string" and #decoded==w*h*2,err or "Incomplete digit asset")
  return decoded
end
local function blit(c,pixels,x,y,w,h)
  lv_canvas_blit_rgb565(c.canvas,x or 0,y or 0,w or c.w,h or c.h,pixels)
end
local function squeeze(data,w,source_y,source_h,target_h)
  -- 只重采样行，避免 Lua 逐像素运算；垂直压缩产生翻页折叠效果。
  local rows={}; local stride=w*2
  for row=0,target_h-1 do
    local source=source_y+math.min(source_h-1,math.floor(row*source_h/target_h))
    rows[#rows+1]=data:sub(source*stride+1,(source+1)*stride)
  end
  return table.concat(rows)
end
local function frame(c,stamp)
  if not c.started then return end
  local elapsed=(stamp-c.started)%4294967.296
  local duration=A.motion=="rebound" and 760 or 320
  local p=math.min(1,elapsed/320)
  local half=c.h/2; local split=c.w*half*2
  if elapsed>=duration then
    if diagnostics and A.motion=="rebound" then
      status.rebound_completed=(status.rebound_completed or 0)+1
      if (c.reboundFrames or 0)==0 then status.rebound_missed=(status.rebound_missed or 0)+1 end
    end
    blit(c,c.pixels);c.old=nil;c.started=nil;return
  end
  lv_canvas_frame_begin(c.canvas)
  blit(c,elapsed>=320 and c.pixels or (c.pixels:sub(1,split)..c.old:sub(split+1)))
  if A.motion=="rebound" and elapsed>=320 then
    if diagnostics then c.reboundFrames=(c.reboundFrames or 0)+1 end
    -- 回弹露出的区域必须是底色，否则完整数字会覆盖缩回的半页。
    lv_canvas_draw_rect(c.canvas,0,half,c.w,half,skin().bottom)
  end
  if p<0.5 then
    local h=math.max(1,math.floor(half*math.cos(p*math.pi)))
    blit(c,squeeze(c.old,c.w,0,half,h),0,half-h,c.w,h)
  else
    local ratio=A.motion=="rebound" and motion.rebound(elapsed-160) or math.sin((p-0.5)*math.pi)
    local h=math.max(1,math.floor(half*ratio))
    blit(c,squeeze(c.pixels,c.w,half,half,h),0,half,c.w,h)
  end
  lv_canvas_frame_end(c.canvas)
end
local function rebuild()
  A.cards={}
  A.assetStem="skins/"..(A.seconds and "small" or "large").."-"..A.theme
  A.assetIndex=assert(file.getcontents(DIR..A.assetStem..".idx"))
  if A.cardRoot then lv_obj_del(A.cardRoot) end
  A.cardRoot=lv_obj_create(A.panel); reset(A.cardRoot)
  lv_obj_set_size(A.cardRoot,320,130); lv_obj_set_pos(A.cardRoot,0,58)
  lv_obj_set_style_bg_opa(A.cardRoot,0,S)
  local count=A.seconds and 3 or 2
  local w,h,gap=A.seconds and 94 or 140,A.seconds and 100 or 116,A.seconds and 6 or 10
  local x=math.floor((320-count*w-(count-1)*gap)/2)
  for i=1,count do
    local panel=box(A.cardRoot,x+(i-1)*(w+gap),0,w,h,skin().top,7)
    lv_obj_set_style_clip_corner(panel,true,S)
    local canvas=lv_canvas_create(panel,w,h)
    lv_obj_set_pos(canvas,0,0)
    local c={canvas=canvas,w=w,h=h,value=-1}
    A.cards[i]=c
    box(panel,0,h/2,w,1,skin().seam,0)
    box(panel,0,h/2-3,3,6,skin().hinge,1)
    box(panel,w-3,h/2-3,3,6,skin().hinge,1)
  end
  if A.seconds then lv_obj_clear_flag(A.iconSecond,LV_OBJ_FLAG_HIDDEN)
  else lv_obj_add_flag(A.iconSecond,LV_OBJ_FLAG_HIDDEN) end
  A.dateKey=nil
end
local function update(animate)
  local t=timeparts()
  if not t then lv_label_set_text(A.date,"等待系统校时");lv_label_set_text(A.lunar,"");return end
  local values={t.hour,t.min,t.sec}
  local stamp=nowms()
  for i,c in ipairs(A.cards) do
    if c.value~=values[i] then
      local data
      if c.nextValue==values[i] then data=c.nextPixels;c.nextPixels=nil;c.nextValue=nil
      else
        data=readcard(values[i],c.w,c.h)
      end
      local old=c.pixels
      if diagnostics and c.started and A.motion=="rebound" then
        status.rebound_interrupted=(status.rebound_interrupted or 0)+1
      end
      c.pixels=data;c.value=values[i]
      c.reboundFrames=0
      if animate and old then c.old=old;c.started=stamp;A.flips=A.flips+1
        if diagnostics and A.motion=="rebound" then status.rebound_started=(status.rebound_started or 0)+1 end
      else c.old=nil;c.started=nil;blit(c,data) end
    end
    frame(c,stamp)
  end
  local dateKey=t.year*10000+t.mon*100+t.day
  if A.dateKey~=dateKey then
    A.dateKey=dateKey
    local names={"日","一","二","三","四","五","六"}
    status.date=string.format("%04d年%d月%d日  星期%s",t.year,t.mon,t.day,names[weekday(t.year,t.mon,t.day)])
    status.lunar=calendar.text(lunarData,t.year,t.mon,t.day)
    lv_label_set_text(A.date,status.date)
    lv_label_set_text(A.lunar,status.lunar)
  end
  status.clock=string.format("%02d:%02d:%02d",t.hour,t.min,t.sec)
end
local function prefetch()
  -- 在没有翻动时分散读取下一张卡片，进位瞬间直接使用内存中的图片。
  for _,c in ipairs(A.cards) do if c.started then return end end
  for i,c in ipairs(A.cards) do
    local nextValue=(c.value+1)%(i==1 and 24 or 60)
    if c.value>=0 and c.nextValue~=nextValue then
      c.nextPixels=readcard(nextValue,c.w,c.h)
      c.nextValue=nextValue
      return
    end
  end
end
local function capture()
  -- 截图是验证证据，失败时只记录，不中断时钟。
  local handle
  local ok,e=pcall(function()
    handle=lv_snapshot_take(A.panel,LV_IMG_CF_TRUE_COLOR_ALPHA or 5)
    assert(handle,"snapshot unavailable")
    local result,err=lv_snapshot_save_to_png(handle,DIR.."preview.png")
    return tostring(result)..":"..tostring(err)
  end)
  if handle then pcall(lv_snapshot_free,handle) end
  status.capture=tostring(e)
end
local function start()
  -- 只加载仓库随包提供的纯 Lua 日期模块，农历数据每日查询一次。
  calendar=assert(load(assert(file.getcontents(DIR.."calendar.lua")),"@calendar.lua"))()
  lunarData=assert(load(assert(file.getcontents(DIR.."lunar_data.lua")),"@lunar_data.lua"))()
  preferences=assert(load(assert(file.getcontents(DIR.."preferences.lua")),"@preferences.lua"))()
  skins=assert(load(assert(file.getcontents(DIR.."skins.lua"))))()
  motion=assert(load(assert(file.getcontents(DIR.."motion.lua"))))()
  local saved=preferences.load(file,sjson,DIR.."settings.json")
  A.light=saved.light;A.seconds=saved.seconds;A.theme=saved.theme;A.motion=saved.motion
  A.skinIndex=1;for i,v in ipairs(skins) do if v.id==A.theme then A.skinIndex=i end end
  local root=lv_scr_act()
  -- 应用面板仍然透明；底层帧缓冲以黑色清屏，避免透明根节点留下旧像素。
  lv_obj_set_style_bg_color(root,0x000000,S)
  lv_obj_set_style_bg_opa(root,255,S)
  A.panel=lv_obj_create(root);reset(A.panel)
  lv_obj_set_size(A.panel,320,240);lv_obj_set_style_bg_opa(A.panel,0,S)
  local function loadfont(size)
    local f=assert(lv_font_load(DIR.."chinese"..size..".bin"),"Chinese font missing")
    A.fonts[#A.fonts+1]=f;return f
  end
  local font,datefont,lunarfont=loadfont(12),loadfont(16),loadfont(13)
  box(A.panel,14,26,4,4,0xffffff,2)
  A.title=label("北京时间",23,21,190,font)
  -- 图标用几何图形绘制，不依赖字体是否包含时钟符号。
  A.icon=box(A.panel,287,21,16,16,0,8)
  lv_obj_set_style_bg_opa(A.icon,0,S)
  lv_obj_set_style_border_width(A.icon,1,S)
  lv_obj_set_style_border_color(A.icon,0xffffff,S)
  box(A.panel,294,24,1,6,0xffffff)
  box(A.panel,294,29,4,1,0xffffff)
  A.iconSecond=box(A.panel,298,32,2,2,0xffffff,1)
  A.date=label("",0,183,320,datefont,LV_TEXT_ALIGN_CENTER)
  A.lunar=label("",0,211,320,lunarfont,LV_TEXT_ALIGN_CENTER)
  rebuild();update(false)
  local function bind(code,left)
    key.on(code,function(event)
      if not A.running or (event~=key.LONG_START and (left or event~=key.SHORT)) then return end
      local ok,e=pcall(function()
        local text
        if left then
          A.skinIndex=A.skinIndex%#skins+1;A.theme=skin().id;A.light=A.theme=="light";text=skin().name
        elseif event==key.SHORT then
          local nextMotion={original="rebound",rebound="original"}
          local names={original="原版翻页",rebound="机械回弹"}
          A.motion=nextMotion[A.motion];text=names[A.motion]
        else A.seconds=not A.seconds end
        if text then lv_label_set_text(A.title,text);A.titleUntil=nowms() end
        local saved,saveError=preferences.save(file,sjson,DIR.."settings.json",A.light,A.seconds,A.theme,A.motion)
        status.settings_saved=saved;status.settings_error=saveError
        rebuild();update(false);status.last_action=left and "theme" or (event==key.SHORT and "motion" or "seconds");report()
      end)
      if not ok then status.error=tostring(e);A.stop("input-error") end
    end)
  end
  bind(key.LEFT,true);bind(key.RIGHT,false)
  -- 文档通过 IPC 通知应用停止，不向即将销毁的应用承诺 exit 回调。
  -- 保留显式 stop 与退出标志轮询；不拦截系统原有返回手势。
  local timer=tmr.create();A.timers[#A.timers+1]=timer
  timer:alarm(40,tmr.ALARM_AUTO,function()
    if not A.running then return end
    local ok,e=pcall(function()
      if app.exiting() then A.stop("app.exiting");return end
      local began=nowms()
      A.tick=A.tick+1;update(true)
      if A.titleUntil and (nowms()-A.titleUntil)%4294967.296>1400 then
        lv_label_set_text(A.title,"北京时间");A.titleUntil=nil
      end
      local cost=(nowms()-began)%4294967.296
      status.max_update_ms=math.max(status.max_update_ms or 0,cost)
      status.total_update_ms=(status.total_update_ms or 0)+cost
      status.average_update_ms=status.total_update_ms/A.tick
      prefetch()
      if diagnostics and A.tick==30 then report() end
      if A.tick%250==0 then report() end
    end)
    if not ok then status.error=tostring(e);A.stop("timer-error") end
  end)
  status.state="running";report()
end
local ok,e=pcall(start)
if not ok then status.error=tostring(e);A.stop("startup-error") end
return A
