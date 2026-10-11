"""Build with the pinned official engine and local export templates."""
from pathlib import Path
import os
import subprocess
import shutil
import zipfile
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT/'.tools/godot/Godot_v4.7.2-stable_win64_console.exe'


def package():
    for folder in ['windows', 'web']:
        destination = ROOT/'builds'/folder
        for document in ['README.md', 'THIRD_PARTY_NOTICES.md']:
            shutil.copyfile(ROOT/document, destination/document)
        shutil.copytree(ROOT/'docs', destination/'docs', dirs_exist_ok=True)
    for folder, label in [('windows', 'Windows-x64'), ('web', 'Web')]:
        package_path = ROOT/'builds'/f'CarrierAce-0.1.0-{label}.zip'
        with zipfile.ZipFile(package_path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
            for path in sorted((ROOT/'builds'/folder).rglob('*')):
                if path.is_file() and path.suffix != '.import' and path.name != '.gdignore':
                    z.write(path, arcname=f'CarrierAce-{label}/'+path.relative_to(ROOT/'builds'/folder).as_posix())
    hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted((ROOT/'builds').glob('CarrierAce-0.1.0-*.zip'))}
    (ROOT/'builds/SHA256SUMS.json').write_text(json.dumps(hashes, indent=2)+'\n')
    print(json.dumps(hashes, indent=2))


def main():
    if '--package-only' in sys.argv:
        package()
        return
    env = dict(os.environ, APPDATA=str(ROOT/'.tools/runtime-profile'))
    command = [str(ENGINE), '--headless', '--path', str(ROOT)]
    version = subprocess.check_output([str(ENGINE), '--version'], env=env, text=True).strip()
    if not version.startswith('4.7.2.stable.'):
        raise RuntimeError(f'Wrong engine: {version}')
    subprocess.run(command+['--editor', '--import'], cwd=ROOT, env=env, check=True)
    for folder, preset, filename in [('windows', 'Windows x64', 'CarrierAce.exe'), ('web', 'Web', 'index.html')]:
        destination = ROOT/'builds'/folder
        destination.mkdir(parents=True, exist_ok=True)
        subprocess.run(command+['--export-release', preset, str(destination/filename)], cwd=ROOT, env=env, check=True)
        for document in ['README.md', 'THIRD_PARTY_NOTICES.md']:
            shutil.copyfile(ROOT/document, destination/document)
        if folder == 'web':
            compiler = Path(os.environ['WINDIR'])/'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
            subprocess.run([str(compiler), '/nologo', '/optimize+', '/target:exe',
                            '/out:'+str(destination/'CarrierServer.exe'), str(ROOT/'tools/CarrierServer.cs')], check=True)
            for launcher in ['Start-Browser.ps1', 'Start-Browser.cmd']:
                shutil.copyfile(ROOT/'tools'/launcher, destination/launcher)
    package()


if __name__ == '__main__':
    main()
