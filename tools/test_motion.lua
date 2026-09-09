-- 确认回弹有清晰的收回阶段，并在下一秒到来前完整落下。
local M=dofile('package/motion.lua')
assert(M.rebound(0)==0)
assert(M.rebound(160)==1)
assert(math.abs(M.rebound(300)-.80)<.001)
assert(M.rebound(460)==1)
assert(math.abs(M.rebound(540)-.95)<.001)
assert(M.rebound(600)==1 and M.rebound(1000)==1)
for ms=0,1000,10 do local h=M.rebound(ms);assert(h>=0 and h<=1) end
assert(M.glow==nil)
print('PASS rebound: two rebounds, bounded height, complete landing')
