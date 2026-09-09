-- 仅保存用户偏好，不保存当前时间、动画中间状态或诊断信息。
local P={}
function P.load(storage,json,path)
  local ok,data=pcall(function()
    local raw=storage.getcontents(path)
    return raw and json.decode(raw) or nil
  end)
  local result={light=false,seconds=true}
  if ok and type(data)=='table' then
    if type(data.light)=='boolean' then result.light=data.light end
    if type(data.seconds)=='boolean' then result.seconds=data.seconds end
  end
  return result
end
function P.save(storage,json,path,light,seconds)
  local ok,err=pcall(function()
    local raw=json.encode({version=1,light=light,seconds=seconds})
    storage.putcontents(path,raw)
    -- 检查实际读回，覆盖返回 nil 但没有抛错的固件文件 API。
    local stored=json.decode(assert(storage.getcontents(path),'settings write failed'))
    assert(stored.light==light and stored.seconds==seconds,'settings verification failed')
  end)
  if ok then return true end
  return false,tostring(err)
end
return P
