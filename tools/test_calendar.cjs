// 用香港天文台年度对照表校验实际 Lua 查询；不使用已知 2027 年有差异的 ICU。
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const root=path.resolve(__dirname,'..');
const monthNames=['正月','二月','三月','四月','五月','六月','七月','八月','九月','十月','冬月','腊月'];
const lines=[];
const digits=['一','二','三','四','五','六','七','八','九','十'];
const dayNames=Array.from({length:30},(_,i)=>{const d=i+1;return d<=10?'初'+digits[d-1]:d<20?'十'+digits[d-11]:d===20?'二十':d<30?'廿'+digits[d-21]:'三十'});
for(let year=2024;year<=2030;year++){
  const text=fs.readFileSync(path.join(root,`_temp/T${year}c.txt`),'utf8');
  for(const line of text.split('\n')){
    const m=line.match(/^(\d+)年(\d+)月(\d+)日\s+(\S+)/);if(!m)continue;
    const name=m[4].replace('閏','闰').replace('臘','腊').replace('十一月','冬月').replace('十二月','腊月');
    const month=monthNames.indexOf(name.replace('闰',''))+1;
    const day=month?1:dayNames.indexOf(name)+1;
    if(!day)throw new Error('Unknown HKO date '+line);
    lines.push(`{${m[1]},${m[2]},${m[3]},${month},${day},${name.includes('闰')?'true':'false'}},`);
  }
}
if(lines.length!==2557)throw new Error('Incomplete HKO fixtures: '+lines.length);
const script=`-- 官方年度表验证日期，月初额外验证月份及闰月。\nlocal C=dofile('package/calendar.lua')\nlocal data=dofile('package/lunar_data.lua')\nlocal cases={${lines.join('\n')}}\nfor _,t in ipairs(cases) do local m,d,l=C.lunar(data,t[1],t[2],t[3]);assert(d==t[5] and (t[4]==0 or (m==t[4] and l==t[6])),table.concat({t[1],t[2],t[3]},'-')) end\nassert(C.serial(1970,1,1)==0)\nassert(C.lunar(data,1899,12,31)==nil)\nassert(C.lunar(data,2101,1,1)==nil)\nassert(C.text(data,2026,2,17)=='农历正月初一')\nassert(C.text(data,2027,2,6)=='农历正月初一')\nassert(C.text(data,2025,7,25)=='农历闰六月初一')\nassert(C.text(data,2026,9,9)=='农历七月廿八')\nprint('PASS calendar: '..#cases..' dates, leap month, new year, bounds')\n`;
fs.writeFileSync(path.join(root,'_temp/calendar-test.lua'),script);
let cli=path.join(root,'node_modules/fengari-node-cli/src/lua-cli.js');
if(!fs.existsSync(cli))cli=path.join(root,'_temp/build/node_modules/fengari-node-cli/src/lua-cli.js');
const output=cp.execFileSync(process.execPath,[cli,'_temp/calendar-test.lua'],{cwd:root,encoding:'utf8'});
if(!output.includes('PASS calendar:'))throw new Error('Lua validation failed');
console.log(output.trim());
