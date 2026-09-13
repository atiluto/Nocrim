"""Focused, sequential checks; all Godot saves stay in tests/godot-saves."""
from pathlib import Path
import argparse,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--render',action='store_true');args=p.parse_args()
logs=ROOT/'tests/events';logs.mkdir(parents=True,exist_ok=True)
jobs=[('prologue',[sys.executable,'tools/compile_scenario.py','--check']),('events',[sys.executable,'tools/compile_events.py','--check'])]
for name in ['test_region_events','test_event_catalog','test_calendar','test_campaign','test_arrival_flow','test_map_token','test_region_ui']:
    jobs.append((name,[sys.executable,'tools/godot_task.py']+([] if args.render and name=='test_region_ui' else ['--headless'])+['--script',f'res://tests/{name}.gd']))
failed=[]
for name,cmd in jobs:
    try:r=subprocess.run(cmd,cwd=ROOT,capture_output=True,timeout=60)
    except subprocess.TimeoutExpired:
        print(name+': TIMEOUT');failed.append(name);continue
    output=(r.stdout+r.stderr).decode('utf-8',errors='replace')
    (logs/(name+'.log')).write_text(output,encoding='utf-8')
    error=r.returncode!=0 or 'SCRIPT ERROR:' in output or 'FAIL:' in output
    print(name+(': FAILED' if error else ': passed'))
    if error:failed.append(name);print(output[-5000:])
print('Failed: '+', '.join(failed) if failed else 'All focused checks passed.')
raise SystemExit(1 if failed else 0)
