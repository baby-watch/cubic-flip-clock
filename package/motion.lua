-- 返回翻页下半页的高度比例；回弹使用有限次数的分段插值。
local M={}
function M.rebound(ms)
  local points={{0,0},{160,1},{265,.82},{360,1},{410,.965},{460,1}}
  for i=2,#points do
    local a,b=points[i-1],points[i]
    if ms<=b[1] then return a[2]+(b[2]-a[2])*math.max(0,(ms-a[1])/(b[1]-a[1])) end
  end
  return 1
end
function M.glow(ms) return math.floor(180*math.max(0,1-ms/500)) end
return M
