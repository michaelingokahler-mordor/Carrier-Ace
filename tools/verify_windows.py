"""Run the exported Windows game with the deterministic, normal-speed pilot."""
from pathlib import Path
import os, subprocess, sys, argparse
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--mission',type=int,choices=[1,2,3,4],default=1)
parser.add_argument('--accelerated',action='store_true')
parser.add_argument('--radar',action='store_true')
options=parser.parse_args()
destination=root/'output/windows08'/('mission'+str(options.mission)+('-radar' if options.radar else '')+('' if options.accelerated else '-realtime'))
destination.mkdir(parents=True,exist_ok=True)
profile=root/'.tools/export08-profile'
config=profile/'Godot/app_userdata/Carrier Ace/carrier_ace.cfg'
config.parent.mkdir(parents=True,exist_ok=True)
# Disposable export fixture; actual player settings are never read or changed.
config.write_text('[hangar]\nstate={"version":2,"selected":"hellcat","completed":3,"mission":1,"unlocked":{"wildcat":true,"hellcat":true}}\n',encoding='utf-8')
env=dict(os.environ,APPDATA=str(profile))
args=[str(root/'builds/windows/CarrierAce.exe'),'--resolution','1920x1080','--',
      '--verify' if options.accelerated else '--verify-real-time','--verify-mission='+str(options.mission),
      '--silent','--report='+str(destination/'report.json'),'--capture-dir='+str(destination/'captures')]
if options.radar: args.append('--verify-radar-alarms')
sys.exit(subprocess.call(args,cwd=root,env=env))
