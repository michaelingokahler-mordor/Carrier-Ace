"""Fetch only Windows and Web templates from the official remote ZIP.

The seekable Range reader avoids downloading templates for unrelated platforms.
Cached chunks are local build inputs and ignored by Git.
"""
import io
import json
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'

class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        self.url = url
        self.position = 0
        with urllib.request.urlopen(urllib.request.Request(url, method='HEAD'), timeout=60) as response:
            self.url = response.url
            self.length = int(response.headers['Content-Length'])

    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position if whence == 1 else self.length) + offset
        return self.position

    def read(self, size=-1):
        if size < 0: size = self.length - self.position
        size = min(size, self.length - self.position)
        if size <= 0: return b''
        start, finish = self.position, self.position + size - 1
        request = urllib.request.Request(self.url, headers={'Range': f'bytes={start}-{finish}', 'User-Agent': 'CarrierAceBuild/0.1'})
        with urllib.request.urlopen(request, timeout=180) as response:
            if response.status != 206:
                raise RuntimeError('Server did not honor byte ranges; refusing a full archive download.')
            payload = response.read()
        if len(payload) != size:
            raise RuntimeError(f'Incomplete range: wanted {size}, received {len(payload)}')
        self.position += len(payload)
        return payload

destination = ROOT / '.tools' / 'templates'
destination.mkdir(parents=True, exist_ok=True)
names = ['windows_release_x86_64.exe', 'windows_debug_x86_64.exe', 'web_nothreads_release.zip', 'web_nothreads_debug.zip', 'version.txt']
with zipfile.ZipFile(RemoteZip(URL)) as archive:
    listing = archive.namelist()
    for name in names:
        target = destination / name
        if target.exists():
            print(f'Already downloaded: {name}', flush=True)
            continue
        source = next((item for item in listing if item.endswith('/' + name)), None)
        if source is None:
            raise RuntimeError(f'Template missing: {name}. Available: {listing}')
        print(f'Downloading {name} ({archive.getinfo(source).compress_size / 1048576:.1f} MiB)', flush=True)
        target.write_bytes(archive.read(source))
        print(f'Saved {name}', flush=True)
(destination / 'source.json').write_text(json.dumps({'version': '4.7.2.stable', 'source': URL, 'templates': names}, indent=2), encoding='utf-8')
