"""Prepare approved Runway plan-view images, local damage states and masks."""
from pathlib import Path
import json,re
from collections import deque
import numpy as np
from PIL import Image,ImageFilter,ImageDraw
from prepare_collision_contours import contours
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'assets/art'
SIZES={'minesweeper':(512,768),'aux_minesweeper':(512,768),'radar_station':(512,512),'mg_nest':(512,512),'island_mountain':(1024,768),'island_fortress':(1024,768)}

def key(source,size):
 im=Image.open(source).convert('RGBA')
 data=np.asarray(im).copy()
 rgb=data[:,:,:3].astype(float)
 ratio=np.minimum(rgb[:,:,0],rgb[:,:,2])/np.maximum(1,rgb[:,:,1])
 alpha=np.clip((1.45-ratio)/0.20,0,1)
 # Pale magenta reflections around generated coast edges are matte spill.
 # Sand, green vegetation and warm rocks do not have both red and blue above green.
 if size==(1024,768):
  spill=(rgb[:,:,0]>rgb[:,:,1]+2)&(rgb[:,:,2]>rgb[:,:,1]+2)
  alpha[spill]=0
 # Remove the magenta matte from partially transparent boundary colors.
 edge=(alpha>0)&(alpha<1)
 foreground=(rgb-(1-alpha[:,:,None])*np.array([255,0,255]))/np.maximum(alpha[:,:,None],0.01)
 data[edge,:3]=np.clip(foreground[edge],0,255).astype('uint8')
 data[:,:,3]=(alpha*data[:,:,3]).astype('uint8')
 data[data[:,:,3]==0,:3]=0
 im=Image.fromarray(data)
 bbox=im.getchannel('A').point(lambda x:255 if x>=128 else 0).getbbox()
 if not bbox: raise ValueError('Empty foreground')
 im=im.crop(bbox)
 im.thumbnail((size[0]-48,size[1]-48),Image.Resampling.LANCZOS)
 result=Image.new('RGBA',size)
 result.alpha_composite(im,((size[0]-im.width)//2,(size[1]-im.height)//2))
 return result

def shore(name,im):
 alpha=Image.new('L',(im.width+192,im.height+192));alpha.paste(im.getchannel('A'),(96,96))
 expanded=alpha.filter(ImageFilter.MaxFilter(81)).filter(ImageFilter.GaussianBlur(12))
 ring=Image.fromarray(np.maximum(0,np.asarray(expanded).astype(float)-np.asarray(alpha).astype(float)).astype('uint8'))
 Image.merge('RGBA',(ring,ring,ring,ring)).save(ART/(name+'_shore.png'),optimize=True)

def main():
 result={}
 for name,size in SIZES.items():
  im=key(ROOT/'assets/source'/f'{name}.png',size)
  im.save(ART/f'{name}.png',optimize=True)
  if name.startswith('island'): shore(name,im)
  else:
   for state in ['damaged','wreck']:
    damaged=im.copy();a=np.asarray(damaged).copy();a[:,:,:3]=(a[:,:,:3]*([0.62,0.58,0.53] if state=='damaged' else [0.36,0.38,0.36])).astype('uint8');damaged=Image.fromarray(a)
    marks=Image.new('RGBA',size);draw=ImageDraw.Draw(marks)
    for x,y,r in [(0.49,0.43,0.08),(0.51,0.65,0.055),(0.45,0.28,0.04)]:
     cx,cy=x*size[0],y*size[1];radius=r*size[0];draw.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),fill=(20,21,18,150))
    marks.putalpha(Image.fromarray((np.asarray(marks.getchannel('A')).astype(float)*np.asarray(im.getchannel('A'))/255).astype('uint8')))
    damaged.alpha_composite(marks);damaged.save(ART/f'{name}_{state}.png',optimize=True)
   profile=ROOT/'resources'/f'surface_{name}.tres'
   dimensions=re.search(r'sprite_size = Vector2\(([\d.]+), ([\d.]+)\)',profile.read_text(encoding='utf-8'))
   logical=tuple(int(float(v)) for v in dimensions.groups()) if dimensions else (96,144)
   alpha=im.getchannel('A').resize((logical[0]*2,logical[1]*2),Image.Resampling.LANCZOS)
   solid=Image.fromarray(np.where(np.asarray(alpha)>=192,255,0).astype('uint8')).filter(ImageFilter.MinFilter(9))
   mask=np.asarray(solid)>0
   # Decks and concrete bases are continuous solid surfaces. Fill matte pinholes,
   # preserving all exterior gaps; aircraft contours are not processed here.
   exterior=np.zeros_like(mask);todo=deque()
   for y,x in [(0,x) for x in range(mask.shape[1])]+[(mask.shape[0]-1,x) for x in range(mask.shape[1])]+[(y,0) for y in range(mask.shape[0])]+[(y,mask.shape[1]-1) for y in range(mask.shape[0])]:
    if not mask[y,x] and not exterior[y,x]: exterior[y,x]=True;todo.append((y,x))
   while todo:
    y,x=todo.popleft()
    for yy,xx in [(y-1,x),(y+1,x),(y,x-1),(y,x+1)]:
     if 0<=yy<mask.shape[0] and 0<=xx<mask.shape[1] and not mask[yy,xx] and not exterior[yy,xx]: exterior[yy,xx]=True;todo.append((yy,xx))
   mask|=~exterior
   result[name]={'contours':[[[round(x/(logical[0]*2)-.5,7),round(y/(logical[1]*2)-.5,7)] for x,y in loop] for loop in contours(mask)],'size':logical}
 # Reuse an approved coastal motif, with a different orientation and palette.
 coast=Image.open(ART/'island_1.png').convert('RGBA').transpose(Image.Transpose.FLIP_LEFT_RIGHT)
 coast.save(ART/'island_coast.png',optimize=True);shore('island_coast',coast)
 (ROOT/'output/surface_contours.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
 print('Prepared 6 production motifs, damage states and three padded shore masks')
if __name__=='__main__': main()
