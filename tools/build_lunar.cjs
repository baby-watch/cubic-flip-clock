// 构建紧凑农历月表；设备只查表，不运行天文算法，不访问互联网。
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..');
let lib;try{lib=require('lunar-javascript')}catch{lib=require(path.join(root,'_temp/build/node_modules/lunar-javascript'))}
const {Solar}=lib;
const serial=d=>Math.floor(d.getTime()/86400000);
const begin=new Date(Date.UTC(1900,0,1)),end=new Date(Date.UTC(2101,0,1));
const entries=[];
let d=begin;
while(d<end){
  const lunar=Solar.fromYmd(d.getUTCFullYear(),d.getUTCMonth()+1,d.getUTCDate()).getLunar();
  const start=serial(d)-lunar.getDay()+1;
  entries.push([start,Math.abs(lunar.getMonth()),lunar.getMonth()<0?1:0]);
  // 逐日走到下个月，保证闰月不被跳过。
  do {d=new Date(d.getTime()+86400000);if(d>=end)break;} while(Solar.fromYmd(d.getUTCFullYear(),d.getUTCMonth()+1,d.getUTCDate()).getLunar().getDay()!==1);
}
const result=`-- 由 lunar-javascript 1.7.7 生成，MIT；记录为公历纪元日、农历月、闰月标志。\nreturn {min=${serial(begin)}, max=${serial(end)-1}, months={\n${entries.map(e=>'{'+e.join(',')+'},').join('\n')}\n}}\n`;
fs.writeFileSync(path.join(root,'package/lunar_data.lua'),result);
fs.writeFileSync(path.join(root,'_temp/lunar-months.json'),JSON.stringify({min:serial(begin),max:serial(end)-1,months:entries}));
console.log('lunar months:',entries.length,'bytes:',Buffer.byteLength(result));
