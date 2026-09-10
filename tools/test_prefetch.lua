-- 验证平时释放时分缓存、提前进位准备、动画避让和校时清理。
local P=dofile('package/prefetch.lua')
local reads=0
local function read(n) reads=reads+1;return 'image'..n end
local cards={{value=23},{value=59},{value=56}}
local function fill(t) for _=1,3 do P.step(cards,t,read) end end
fill({hour=23,min=59,sec=56})
assert(not cards[1].nextPixels and not cards[2].nextPixels and cards[3].nextValue==57)
local before=reads
cards[3].value=57;cards[3].started=1
P.step(cards,{hour=23,min=59,sec=57},read)
assert(reads==before and not cards[3].nextPixels)
cards[3].started=nil
fill({hour=23,min=59,sec=57})
assert(cards[1].nextValue==0 and cards[2].nextValue==0 and cards[3].nextValue==58)
before=reads;fill({hour=23,min=59,sec=57});assert(reads==before)
-- 时钟向后调整后，即使动画在进行，也应释放不再需要的大图片。
cards[1].started=1
P.step(cards,{hour=12,min=34,sec=20},read)
assert(not cards[1].nextPixels and not cards[2].nextPixels)
cards[1].started=nil;cards[1].value=12;cards[2].value=34
fill({hour=12,min=34,sec=58})
assert(not cards[1].nextPixels and cards[2].nextValue==35)
cards[2].value=40;P.step(cards,{hour=12,min=40,sec=58},read)
assert(cards[2].nextValue==41)
P.step(cards,nil,read);assert(not cards[2].nextPixels and not cards[3].nextPixels)
local large={{value=12},{value=34}}
for _=1,3 do P.step(large,{hour=12,min=34,sec=20},read) end
assert(not large[1].nextPixels and not large[2].nextPixels)
P.step(large,{hour=12,min=34,sec=57},read)
assert(not large[1].nextPixels and large[2].nextValue==35)
print('PASS prefetch: idle memory, midnight, minute rollover, busy frames, clock jumps, large cards')
