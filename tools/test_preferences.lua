-- 用内存文件系统模拟退出重开、损坏数据和写入失败。
local P=dofile('package/preferences.lua')
local files={}
local storage={getcontents=function(p) return files[p] end,putcontents=function(p,v) files[p]=v end}
local json={encode=function(t) return tostring(t.light)..','..tostring(t.seconds) end,
  decode=function(s)
    if s=='invalid-types' then return {light=1,seconds='false'} end
    local l,r=s:match('^(%a+),(%a+)$');assert(l and r,'invalid json')
    return {light=l=='true',seconds=r=='true'}
  end}
local function check(light,seconds)
  local reopened=dofile('package/preferences.lua').load(storage,json,'settings')
  assert(reopened.light==light and reopened.seconds==seconds)
end
check(false,true)
for _,pair in ipairs({{true,false},{false,false},{true,true},{false,true}}) do
  local ok,err=P.save(storage,json,'settings',pair[1],pair[2])
  assert(ok and err==nil);check(pair[1],pair[2])
end
files.settings='broken';check(false,true)
files.settings='invalid-types';check(false,true)
storage.putcontents=function() error('disk full') end
local ok,err=P.save(storage,json,'settings',true,false);assert(not ok and err:find('disk full'))
storage.putcontents=function() end
ok,err=P.save(storage,json,'settings',true,false);assert(not ok and err)
storage.getcontents=function() error('read failed') end
check(false,true)
print('PASS preferences: reopen, four combinations, invalid data, storage failures')
