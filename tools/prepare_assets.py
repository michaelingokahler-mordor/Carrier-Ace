"""Normalize approved Runway drafts into small local runtime files.

Source downloads are private build inputs. Only finished PNG/OGG files are
versioned. No model call or paid operation occurs in this script.
"""
from pathlib import Path
import json
import shutil
import subprocess
import tempfile
import wave
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/source'
ART = ROOT / 'assets/art'
AUDIO = ROOT / 'assets/audio'
OUTPUT = ROOT / 'output'


def sprite(name, source_name, size, background='pink', rotate=False):
    im = Image.open(SOURCE / f'{source_name}.png').convert('RGBA')
    a = np.array(im)
    rgb = a[:, :, :3].astype(float)
    if background == 'pink':
        mask = (rgb[:, :, 0] > rgb[:, :, 1] * 1.24) & (rgb[:, :, 2] > rgb[:, :, 1] * 0.80)
    else:
        # Carrier draft uses an entirely flat cyan background and dark blue shadow.
        mask = (rgb[:, :, 2] > rgb[:, :, 0] * 1.3) & (rgb[:, :, 1] > rgb[:, :, 0] * 1.18)
    a[:, :, 3][mask] = 0
    a[:, :, :3][mask] = 0
    im = Image.fromarray(a).crop(Image.fromarray(a[:, :, 3]).getbbox())
    if rotate:
        im = im.transpose(Image.Transpose.ROTATE_180)
    im.thumbnail((size[0] - 4, size[1] - 4), Image.Resampling.NEAREST)
    im = im.quantize(colors=48, method=Image.Quantize.FASTOCTREE).convert('RGBA')
    canvas = Image.new('RGBA', size)
    canvas.alpha_composite(im, ((size[0] - im.width)//2, (size[1] - im.height)//2))
    canvas.save(ART / f'{name}.png', optimize=True)
    return {'size': size, 'source': source_name, 'transparent_border': True}


def background(name, size):
    im = Image.open(SOURCE / f'{name}.png').convert('RGB').resize(size, Image.Resampling.BOX)
    if name == 'ocean':
        a = np.array(im).astype(float)
        # Identical top/bottom rows plus a sixteen-pixel blend hide scroll joins.
        n = 16
        edge = (a[0] + a[-1]) / 2
        for j in range(n):
            w = j / n
            a[j] = edge * (1-w) + a[j] * w
            a[-1-j] = edge * (1-w) + a[-1-j] * w
        im = Image.fromarray(np.uint8(a))
    im.quantize(colors=96).save(ART / f'{name}.png', optimize=True)


def audio(name, loop=False):
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise RuntimeError('ffmpeg is required for offline asset preparation.')
    channels = 2 if 'music' in name else 1
    with tempfile.TemporaryDirectory(dir=OUTPUT) as folder:
        raw = Path(folder) / 'decoded.wav'
        ready = Path(folder) / 'ready.wav'
        subprocess.run([ffmpeg, '-v', 'error', '-y', '-i', str(SOURCE/f'{name}.mp3'),
                        '-ar', '44100', '-ac', str(channels), '-c:a', 'pcm_s16le', str(raw)], check=True)
        with wave.open(str(raw), 'rb') as f:
            samples = np.frombuffer(f.readframes(f.getnframes()), dtype='<i2').reshape(-1, channels).astype(float) / 32768
        if loop:
            n = min(11025 if 'music' in name else 4410, len(samples)//8)
            t = np.linspace(0, 1, n)[:, None]
            blend = samples[-n:]*(1-t) + samples[:n]*t
            samples = np.concatenate([samples[n:-n], blend])
        else:
            n = min(220, len(samples)//8)
            samples[:n] *= np.linspace(0, 1, n)[:, None]
            samples[-n:] *= np.linspace(1, 0, n)[:, None]
        peak = float(np.max(np.abs(samples)))
        ceiling = 0.50 if 'music' in name else 0.708
        samples *= ceiling / max(peak, 0.00001)
        with wave.open(str(ready), 'wb') as f:
            f.setnchannels(channels)
            f.setsampwidth(2)
            f.setframerate(44100)
            f.writeframes((samples * 32767).astype('<i2').tobytes())
        subprocess.run([ffmpeg, '-v', 'error', '-y', '-i', str(ready), '-c:a', 'libvorbis',
                        '-q:a', '5', str(AUDIO/f'{name}.ogg')], check=True)
        return {'seconds': round(len(samples)/44100, 3), 'loop': loop,
                'channels': channels, 'pcm_peak': round(ceiling, 3),
                'seam_jump': round(float(np.max(np.abs(samples[-1]-samples[0]))), 6) if loop else None}


def main():
    for directory in [ART, AUDIO, OUTPUT]:
        directory.mkdir(parents=True, exist_ok=True)
    report = {'art': {}, 'audio': {}}
    specs = [('player', 'player_v2', (64, 64), 'pink', False),
             ('fighter', 'fighter', (64, 64), 'pink', True),
             ('interceptor', 'interceptor', (64, 64), 'pink', True),
             ('armored', 'armored_v2', (80, 80), 'pink', True),
             ('boss', 'boss_v2', (160, 132), 'pink', True),
             ('carrier', 'carrier', (128, 340), 'blue', False),
             ('island', 'island', (192, 144), 'pink', False)]
    for name, source, size, bg, rotate in specs:
        report['art'][name] = sprite(name, source, size, bg, rotate)
    background('ocean', (480, 270))
    background('title', (960, 540))
    for name in ['shot', 'enemy_shot', 'engine', 'explosion', 'explosion_big', 'hit',
                 'pickup', 'roll', 'takeoff', 'landing', 'ui', 'title_music', 'game_music']:
        report['audio'][name] = audio(name, name in ['engine', 'title_music', 'game_music'])
    (OUTPUT/'asset_qa.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    sheet = Image.new('RGB', (960, 720), '#153442')
    draw = ImageDraw.Draw(sheet)
    for i, name in enumerate(['player', 'fighter', 'interceptor', 'armored', 'boss', 'carrier', 'island', 'ocean', 'title']):
        im = Image.open(ART/f'{name}.png').convert('RGBA')
        im.thumbnail((290, 190), Image.Resampling.NEAREST)
        x, y = (i % 3)*320, (i//3)*240
        sheet.paste(im, (x+(320-im.width)//2, y+30), im)
        draw.text((x+15, y+10), name, fill='white')
    sheet.save(OUTPUT/'asset_contact.png')
    print('Prepared 9 PNG sprites/backgrounds and 13 OGG sounds. QA: output/asset_qa.json')


if __name__ == '__main__':
    main()
