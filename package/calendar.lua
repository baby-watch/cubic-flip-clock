-- 公历日期与农历月表查询。明确限定 1900—2100，超出范围不给出猜测日期。
local C={}
function C.serial(y,m,d)
  if m<=2 then y=y-1 end
  local era=math.floor(y/400)
  local yo=y-era*400
  local mp=m+(m>2 and -3 or 9)
  local doy=math.floor((153*mp+2)/5)+d-1
  return era*146097+yo*365+math.floor(yo/4)-math.floor(yo/100)+doy-719468
end
function C.lunar(data,y,m,d)
  local day=C.serial(y,m,d)
  if day<data.min or day>data.max then return nil end
  local lo,hi=1,#data.months
  while lo<=hi do
    local mid=math.floor((lo+hi)/2)
    if data.months[mid][1]<=day then lo=mid+1 else hi=mid-1 end
  end
  local item=data.months[hi]
  if not item then return nil end
  return item[2],day-item[1]+1,item[3]==1
end
function C.text(data,y,m,d)
  local month,day,leap=C.lunar(data,y,m,d)
  if not month then return '农历超出范围' end
  local months={'正','二','三','四','五','六','七','八','九','十','冬','腊'}
  local digits={'一','二','三','四','五','六','七','八','九','十'}
  local text
  if day<=10 then text='初'..digits[day]
  elseif day<20 then text='十'..digits[day-10]
  elseif day==20 then text='二十'
  elseif day<30 then text='廿'..digits[day-20]
  else text='三十' end
  return '农历'..(leap and '闰' or '')..months[month]..'月'..text
end
return C
