"""Prepare high-resolution Runway art; no generation or audio mutation occurs."""
from pathlib import Path
import argparse
import json
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/source'
ART = ROOT / 'assets/art'

def prepare(name):
    source = SOURCE / f'{name}.png'
    image = Image.open(source).convert('RGBA')
    original = image.size
    if name == 'title':
        image = image.convert('RGB').resize((1920, 1080), Image.Resampling.LANCZOS)
    else:
        data = np.asarray(image).astype(np.float32)
        rgb = data[:, :, :3]
        chroma = np.minimum(rgb[:, :, 0], rgb[:, :, 2]) - rgb[:, :, 1]
        keyed = (chroma > 12) & (rgb[:, :, 0] > rgb[:, :, 1] * 1.15) & (rgb[:, :, 2] > rgb[:, :, 1] * 1.15)
        alpha = np.where(keyed, np.clip((75 - chroma) / 55, 0, 1), 1)
        alpha *= data[:, :, 3] / 255
        # Remove the magenta matte from anti-aliased edge pixels.
        for channel in [0, 2]:
            rgb[:, :, channel] = np.clip((rgb[:, :, channel] - 255 * (1-alpha)) / np.maximum(alpha, 0.001), 0, 255)
        rgb[:, :, 1] = np.clip(rgb[:, :, 1] / np.maximum(alpha, 0.001), 0, 255)
        data[:, :, 3] = alpha * 255
        data[alpha == 0, :3] = 0
        image = Image.fromarray(data.astype(np.uint8)).crop(Image.fromarray(data[:, :, 3].astype(np.uint8)).getbbox())
        size = (1024, 768) if name.startswith('island') else ((512, 1200) if name == 'carrier' else (768, 768) if name in ['boss','bomber_ace'] else (512, 512))
        image.thumbnail((size[0]-48, size[1]-48), Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA', size)
        canvas.alpha_composite(image, ((size[0]-image.width)//2, (size[1]-image.height)//2))
        image = canvas
        if name.startswith(('biplane','fighter','bomber')) or name == 'boss':
            image = image.transpose(Image.Transpose.ROTATE_180)
    ART.mkdir(parents=True, exist_ok=True)
    image.save(ART / f'{name}.png', optimize=True)
    if name.startswith('island'):
        alpha = Image.new('L', (image.width + 192, image.height + 192))
        alpha.paste(image.getchannel('A'), (96, 96))
        expanded = alpha.filter(ImageFilter.MaxFilter(81)).filter(ImageFilter.GaussianBlur(12))
        outer = np.maximum(0, np.asarray(expanded).astype(float) - np.asarray(alpha).astype(float))
        mask = Image.fromarray(outer.astype(np.uint8))
        # RGB carries bank depth. The shader provides animated foam and alpha.
        Image.merge('RGBA', (mask,mask,mask,mask)).save(ART / f'{name}_shore.png', optimize=True)
    return {'source_size': original, 'runtime_size': image.size, 'quantized': False}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('names', nargs='*')
    args=parser.parse_args()
    names=args.names or ['island_1','island_2','island_3','player','biplane_1','biplane_2','biplane_ace','fighter_1','fighter_2','fighter_ace','bomber_1','bomber_2','bomber_ace','boss','carrier','title']
    report={name:prepare(name) for name in names if (SOURCE/f'{name}.png').exists()}
    (ROOT/'output').mkdir(exist_ok=True)
    (ROOT/'output/art02.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))

if __name__=='__main__': main()
