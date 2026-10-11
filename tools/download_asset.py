"""Download an already generated Runway output; retain no signed URLs."""
import sys
import subprocess
from pathlib import Path
name, extension, url = sys.argv[1:4]
root = Path(__file__).resolve().parents[1]
target = root / 'assets' / 'source' / f'{name}.{extension}'
target.parent.mkdir(parents=True, exist_ok=True)
result = subprocess.run(['curl.exe', '--silent', '--show-error', '--fail', '--location', '--http1.1', '--tls-max', '1.2', '--retry', '3', '--retry-all-errors', '--retry-delay', '1', '--max-time', '45', url, '--output', str(target)])
if result.returncode:
    sys.exit(f'Download failed for {name}: curl exit {result.returncode}. No signed URL retained.')
print(f'Saved {name}.{extension}: {target.stat().st_size} bytes')
