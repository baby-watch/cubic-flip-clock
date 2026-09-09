-- 仅保存用户偏好，不保存当前时间、动画中间状态或诊断信息。
local P={}
local themes={dark=true,light=true,amber=true,ice=true,violet=true,cream=true,blood=true}
local motions={original=true,afterglow=true,rebound=true}
function P.load(storage,json,path)
  local ok,data=pcall(function()
    local raw=storage.getcontents(path)
    return raw and json.decode(raw) or nil
  end)
  local result={light=false,seconds=true,theme='dark',motion='original'}
  if ok and type(data)=='table' then
    if type(data.light)=='boolean' then result.light=data.light end
    if type(data.seconds)=='boolean' then result.seconds=data.seconds end
    result.theme=result.light and 'light' or 'dark'
    if data.theme=='jade' then result.theme='violet'
    elseif themes[data.theme] then result.theme=data.theme end
    if motions[data.motion] then result.motion=data.motion end
    result.light=result.theme=='light'
  end
  return result
end
function P.save(storage,json,path,light,seconds,theme,motion)
  theme=theme or (light and 'light' or 'dark');motion=motion or 'original'
  local ok,err=pcall(function()
    assert(themes[theme] and motions[motion],'invalid preferences')
    local raw=json.encode({version=2,light=theme=='light',seconds=seconds,theme=theme,motion=motion})
    storage.putcontents(path,raw)
    -- 检查实际读回，覆盖返回 nil 但没有抛错的固件文件 API。
    -- assert(value, message) 成功时也会透传 message，不能直接作为 decode 的参数。
    local readback=storage.getcontents(path)
    assert(readback,'settings write failed')
    local stored=json.decode(readback)
    assert(stored.theme==theme and stored.motion==motion and stored.seconds==seconds,'settings verification failed')
  end)
  if ok then return true end
  return false,tostring(err)
end
return P
