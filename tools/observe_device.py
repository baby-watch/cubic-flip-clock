"""只读采样设备，不修改设置、不自动重启；断网单独记录，不误判应用崩溃。"""
import argparse
import json
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--url', required=True)
parser.add_argument('--hours', type=float, default=24)
parser.add_argument('--interval', type=float, default=60)
parser.add_argument('--output', default='_temp/endurance')
args = parser.parse_args()
if args.hours <= 0 or args.interval < 10:
    parser.error('观察时长必须为正，采样间隔至少 10 秒')
output = Path(args.output)
output.mkdir(parents=True, exist_ok=True)
http = urllib.request.build_opener(urllib.request.ProxyHandler({}))
status_path = '/devtools/api/read?path=' + urllib.parse.quote('/sd/apps/flip-clock/status.json') + '&offset=0&size=16384'
summary = {'state': 'running', 'started': datetime.now(timezone.utc).isoformat(), 'samples': 0, 'network_errors': 0, 'app_alerts': 0}
previous = None
deadline = time.monotonic() + args.hours * 3600

def read(path):
    with http.open(args.url.rstrip('/') + path, timeout=10) as response:
        return json.load(response)

def save():
    # 先写临时文件再替换，读取者不会遇到只写了一半的汇总。
    temporary = output / 'summary.tmp'
    temporary.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    temporary.replace(output / 'summary.json')

save()
while time.monotonic() < deadline:
    row = {'at': datetime.now(timezone.utc).isoformat()}
    try:
        status = read(status_path)
        row['status'] = status
        alerts = []
        if status.get('state') != 'running':
            alerts.append('应用未运行')
        if status.get('error'):
            alerts.append('应用报告错误')
        if previous:
            if status.get('started') != previous.get('started'):
                alerts.append('应用实例发生变化，需区分手动重开与异常退出')
            elif status.get('ticks') == previous.get('ticks'):
                alerts.append('诊断计数未推进，需确认应用与诊断开关')
        if alerts:
            row['alerts'] = alerts
            summary['app_alerts'] += 1
            # 异常时再读系统现场，避免平时额外增加设备负载。
            for key, path in [('display', '/display/api/settings'), ('apps', '/devtools/api/apps')]:
                try:
                    row[key] = read(path)
                except Exception as error:
                    row[key + '_error'] = str(error)
        previous = status
        summary['last_status'] = status
        free = status.get('usage', {}).get('heap_free')
        if isinstance(free, (int, float)):
            summary['heap_min'] = min(summary.get('heap_min', free), free)
            summary['heap_max'] = max(summary.get('heap_max', free), free)
        summary['samples'] += 1
    except Exception as error:
        row['network_error'] = str(error)
        summary['network_errors'] += 1
    summary['last_sample'] = row['at']
    with (output / 'samples.jsonl').open('a', encoding='utf-8') as stream:
        stream.write(json.dumps(row, ensure_ascii=False) + '\n')
    save()
    time.sleep(max(0, min(args.interval, deadline - time.monotonic())))
summary['state'] = 'completed'
summary['finished'] = datetime.now(timezone.utc).isoformat()
save()
