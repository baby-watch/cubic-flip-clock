-- 用逐行画布模拟器对照旧算法，覆盖跳帧、重复帧及两种卡片尺寸。
local R=dofile('package/renderer.lua');local motion=dofile('package/motion.lua')
local draws=0
function lv_canvas_frame_begin() end
function lv_canvas_frame_end() end
function lv_canvas_blit_rgb565(canvas,x,y,w,h,data,opts)
  draws=draws+1;local offset=opts and opts.offset or 0
  for row=0,h-1 do canvas[y+row+1]=data:sub(offset+row*w*2+1,offset+(row+1)*w*2) end
end
function lv_canvas_draw_rect(canvas,x,y,w,h,color)
  for row=y+1,y+h do canvas[row]=string.rep('B',w*2) end
end
local function olddraw(c,elapsed,kind)
  local half=c.h/2;local split=c.w*half*2;local p=math.min(1,elapsed/320)
  lv_canvas_blit_rgb565(c.canvas,0,0,c.w,c.h,elapsed>=320 and c.pixels or c.pixels:sub(1,split)..c.old:sub(split+1))
  if elapsed>=320 then lv_canvas_draw_rect(c.canvas,0,half,c.w,half,0) end
  local ratio=p<.5 and math.cos(p*math.pi) or (kind=='rebound' and motion.rebound(elapsed-160) or math.sin((p-.5)*math.pi))
  local th=math.max(1,math.floor(half*ratio));local sy=p<.5 and 0 or half
  local data=p<.5 and c.old or c.pixels;local rows={}
  for r=0,th-1 do local s=sy+math.floor(r*half/th);rows[#rows+1]=data:sub(s*c.w*2+1,(s+1)*c.w*2) end
  lv_canvas_blit_rgb565(c.canvas,0,p<.5 and half-th or half,c.w,th,table.concat(rows))
end
local checks=0
for _,size in ipairs({{94,100},{140,116}}) do
 local w,h=table.unpack(size);local old,new={},{}
 for y=1,h do old[y]=string.rep(string.char(y),w*2);new[y]=string.rep(string.char(y+120),w*2) end
 for _,kind in ipairs({'original','rebound'}) do
  local regular={};for t=0,(kind=='rebound' and 759 or 319),17 do regular[#regular+1]=t end
  for _,times in ipairs({regular,{0,145,177,319,351,459,461,621,759},{210,400,740},{350,400,400,410,700}}) do
   local a={w=w,h=h,old=table.concat(old),pixels=table.concat(new),canvas={}}
   local b={w=w,h=h,old=a.old,pixels=a.pixels,canvas={}}
   for i=1,h do a.canvas[i]=old[i];b.canvas[i]=string.rep('?',w*2) end
   for _,t in ipairs(times) do if kind=='rebound' or t<320 then
    olddraw(a,t,kind);R.draw(b,t,kind,motion,0)
    assert(table.concat(a.canvas)==table.concat(b.canvas),'pixel mismatch '..w..'/'..kind..'/'..t)
    local before=draws;assert(R.draw(b,t,kind,motion,0)==false and before==draws,'duplicate redraw')
    checks=checks+1
   end end
   R.reset(b);assert(b.renderRows==nil and b.renderStage==nil)
  end
 end
end
print('PASS renderer: '..checks..' exact pixel comparisons, skipped stages and duplicate frames')
