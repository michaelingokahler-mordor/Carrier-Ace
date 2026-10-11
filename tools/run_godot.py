"""Use the pinned engine with a workspace-local runtime profile."""
from pathlib import Path
import os
import subprocess
import sys
root=Path(__file__).resolve().parents[1]
engine=root/'.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
env=dict(os.environ,APPDATA=str(root/'.tools/runtime-profile'))
sys.exit(subprocess.call([str(engine),'--path',str(root),*sys.argv[1:]],cwd=root,env=env))
