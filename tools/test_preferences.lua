-- 用内存文件系统模拟退出重开、损坏数据和写入失败。
local P=dofile('package/preferences.lua')
local files={}
local storage={getcontents=function(p) return files[p],'read-status' end,putcontents=function(p,v) files[p]=v end}
local json={encode=function(t) return tostring(t.light)..','..tostring(t.seconds)..','..t.theme..','..t.motion end,
  decode=function(s,options)
    assert(options==nil or type(options)=='table','decode options must be a table')
    if s=='invalid-types' then return {light=1,seconds='false'} end
    local l,r,theme,motion=s:match('^(%a+),(%a+),(%a+),(%a+)$')
    if not l then l,r=s:match('^(%a+),(%a+)$') end
    assert(l and r,'invalid json')
    return {light=l=='true',seconds=r=='true',theme=theme,motion=motion}
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
-- 升级前的黑白设置可迁移；所有新增选项都能跨模块加载恢复。
files.settings='true,false';check(true,false)
files.settings='false,true,jade,afterglow'
assert(P.load(storage,json,'settings').theme=='violet')
for _,theme in ipairs({'dark','light','amber','ice','violet','cream','blood'}) do
  for _,motion in ipairs({'original','afterglow','rebound'}) do
    assert(P.save(storage,json,'settings',theme=='light',false,theme,motion))
    local saved=P.load(storage,json,'settings')
    assert(saved.theme==theme and saved.motion==motion and not saved.seconds)
  end
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
