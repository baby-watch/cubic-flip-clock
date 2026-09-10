-- 秒卡片持续预读，时分卡片仅在进位前三秒保留下一张图片。
local P={}
function P.step(cards,t,readcard)
  local busy=false
  for i,c in ipairs(cards) do
    local wanted=t and (i==3 or (t.sec>=57 and (i==2 or t.min==59)))
    local nextValue=(c.value+1)%(i==1 and 24 or 60)
    -- 校时跳出预读窗口或目标已改变时，及时释放失效缓存。
    if not wanted or c.nextValue~=nextValue then c.nextPixels=nil;c.nextValue=nil end
    if c.started then busy=true end
  end
  if not t or busy then return end
  for i,c in ipairs(cards) do
    local wanted=i==3 or (t.sec>=57 and (i==2 or t.min==59))
    local nextValue=(c.value+1)%(i==1 and 24 or 60)
    if wanted and c.value>=0 and not c.nextPixels then
      c.nextPixels=readcard(nextValue,c.w,c.h);c.nextValue=nextValue
      -- 每次只读一张，整点前三秒分散完成时、分、秒的读取。
      return
    end
  end
end
return P
