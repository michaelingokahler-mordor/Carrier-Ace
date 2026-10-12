"""Run the exported Windows game with the deterministic, normal-speed pilot."""
from pathlib import Path
import os, subprocess, sys
root=Path(__file__).resolve().parents[1]
destination=root/'output/windows07'
destination.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,APPDATA=str(root/'.tools/export-runtime-profile'))
args=[str(root/'builds/windows/CarrierAce.exe'),'--resolution','1920x1080','--','--verify-real-time',
      '--silent','--report='+str(destination/'report.json'),'--capture-dir='+str(destination/'captures')]
sys.exit(subprocess.call(args,cwd=root,env=env))
