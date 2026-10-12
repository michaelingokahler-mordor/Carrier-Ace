"""Extract fixed sprite contours offline, inset by two logical pixels."""
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np
import json
import re

ROOT = Path(__file__).resolve().parents[1]

def simplify(points, epsilon=1.0):
    if len(points) <= 2:
        return points
    a, b = np.array(points[0]), np.array(points[-1])
    delta = b-a
    data = np.array(points)
    if np.dot(delta, delta):
        t = np.clip(((data-a) @ delta)/np.dot(delta, delta), 0, 1)
        distances = np.linalg.norm(data-(a+t[:, None]*delta), axis=1)
    else:
        distances = np.linalg.norm(data-a, axis=1)
    index = int(distances.argmax())
    if distances[index] <= epsilon:
        return [points[0], points[-1]]
    return simplify(points[:index+1], epsilon)[:-1] + simplify(points[index:], epsilon)

def contours(mask):
    edges = {}
    height, width = mask.shape
    for y, x in zip(*np.where(mask)):
        x, y = int(x), int(y)
        segments = []
        if y == 0 or not mask[y-1, x]: segments.append(((x,y),(x+1,y)))
        if x == width-1 or not mask[y, x+1]: segments.append(((x+1,y),(x+1,y+1)))
        if y == height-1 or not mask[y+1, x]: segments.append(((x+1,y+1),(x,y+1)))
        if x == 0 or not mask[y, x-1]: segments.append(((x,y+1),(x,y)))
        for a,b in segments: edges.setdefault(a, []).append(b)
    loops = []
    while edges:
        first = next(iter(edges))
        points, current = [], first
        while True:
            points.append(current)
            targets = edges[current]
            following = targets.pop()
            if not targets: del edges[current]
            current = following
            if current == first: break
        area = sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(points, points[1:]+points[:1]))/2
        if area < -4:
            raise ValueError('Unexpected interior hole; preserve it before decomposition')
        if area > 4:
            middle = len(points)//2
            reduced = simplify(points[:middle+1])[:-1] + simplify(points[middle:]+points[:1])[:-1]
            if len(reduced) >= 3:
                reduced_area = sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(reduced,reduced[1:]+reduced[:1]))/2
                if reduced_area > 2: loops.append(reduced)
    return loops

def main():
    result = {}
    for name in ['player','biplane_1','biplane_2','biplane_ace','fighter_1','fighter_2','fighter_ace','bomber_1','bomber_2','bomber_ace','boss']:
        profile = ROOT/'resources'/('player.tres' if name=='player' else 'enemy_'+name+'.tres')
        match = re.search(r'sprite_size = Vector2\((\d+), (\d+)\)', profile.read_text())
        size = tuple(int(x) for x in match.groups())
        alpha = Image.open(ROOT/'assets/art'/f'{name}.png').getchannel('A')
        alpha = alpha.resize((size[0]*2, size[1]*2), Image.Resampling.LANCZOS)
        # Opaque body only, eroded two logical pixels; soft propeller fringes vanish.
        solid = Image.fromarray(np.where(np.asarray(alpha)>=192, 255, 0).astype('uint8'))
        mask = np.asarray(solid.filter(ImageFilter.MinFilter(9))) > 0
        # Retain the narrow fuselage: a one-pixel inset here avoids eroding it away.
        narrow = np.asarray(solid.filter(ImageFilter.MinFilter(5))) > 0
        center = size[0]
        mask[:, center-10:center+10] |= narrow[:, center-10:center+10]
        polygons = contours(mask)
        result[name] = {'sprite_size':size,'inset_logical_pixels':2,'contours':[
            [[round(x/(size[0]*2)-.5,7),round(y/(size[1]*2)-.5,7)] for x,y in loop] for loop in polygons]}
        print(name, 'contours',len(polygons),'vertices',sum(map(len,polygons)))
    (ROOT/'output').mkdir(exist_ok=True)
    (ROOT/'output/collision_contours.json').write_text(json.dumps(result,indent=2)+'\n')

if __name__=='__main__': main()
