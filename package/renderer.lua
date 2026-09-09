-- 只绘制正在运动的半页；保持固定宽度与原有逐行压缩效果。
local R={}
local function blit(c,data,y,h,offset)
  lv_canvas_blit_rgb565(c.canvas,0,y,c.w,h,data,offset and {offset=offset} or nil)
end
local function squeeze(c,data,sy,th)
  local rows=c.renderRows or {};c.renderRows=rows
  local stride=c.w*2;local half=c.h/2
  -- 复用行容器，并清掉上次较高半页留下的条目。
  for i=#rows,th+1,-1 do rows[i]=nil end
  for row=0,th-1 do
    local source=sy+math.floor(row*half/th)
    rows[row+1]=data:sub(source*stride+1,(source+1)*stride)
  end
  return table.concat(rows)
end
function R.draw(c,elapsed,kind,motion,bottom)
  local half=c.h/2;local stage=elapsed<160 and 0 or (elapsed<320 and 1 or 2)
  local ratio
  if stage==0 then ratio=math.cos(elapsed/320*math.pi)
  elseif kind=='rebound' then ratio=motion.rebound(elapsed-160)
  else ratio=math.sin((math.min(1,elapsed/320)-.5)*math.pi) end
  local height=math.max(1,math.floor(half*ratio))
  if c.renderStage==stage and c.renderHeight==height then return false end
  lv_canvas_frame_begin(c.canvas)
  -- 新动画可能被校时打断；每次动画只拼接一次确定的上下底图。
  local first=c.renderStage==nil
  if first then
    local split=c.w*half*2
    blit(c,c.pixels:sub(1,split)..c.old:sub(split+1),0,c.h)
  end
  -- 阶段判断不能依赖恰好命中 160 ms，定时回调可能跨过边界。
  if not first and (stage==0 or c.renderStage==0) then
    blit(c,c.pixels,0,half,0)
  end
  if stage==0 then
    blit(c,squeeze(c,c.old,0,height),half-height,height)
  else
    if stage==1 then
      if not first then blit(c,c.old,half,half,c.w*half*2) end
    else lv_canvas_draw_rect(c.canvas,0,half,c.w,half,bottom) end
    blit(c,squeeze(c,c.pixels,half,height),half,height)
  end
  lv_canvas_frame_end(c.canvas)
  c.renderStage=stage;c.renderHeight=height
  return true
end
function R.reset(c)
  c.renderStage=nil;c.renderHeight=nil;c.renderRows=nil
end
return R
