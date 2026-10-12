"""Write the approved Carrier Ace 0.5 balancing resources."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def resource(name,cls,script,fields):
    text=f'[gd_resource type="Resource" script_class="{cls}" load_steps=2 format=3]\n'
    text+=f'[ext_resource type="Script" path="res://scripts/{script}.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'
    ident = 'player' if name == 'player' else name.removeprefix('enemy_')
    shapes_path = ROOT/'resources/collision_shapes.json'
    if shapes_path.exists() and (name == 'player' or name.startswith('enemy_')):
        shapes = json.loads(shapes_path.read_text())[ident]['polygons']
        fields['hit_polygons'] = 'Array[PackedVector2Array]([' + ', '.join('PackedVector2Array('+', '.join(str(n) for point in polygon for n in point)+')' for polygon in shapes) + '])'
    text+=''.join(f'{k} = {v}\n' for k,v in fields.items())
    (ROOT/'resources'/f'{name}.tres').write_text(text,encoding='utf-8')
resource('player','AircraftProfile','aircraft_profile',{
 'display_name':'"F6F Hellcat"','model_name':'"Grumman F6F Hellcat"','role':'"Carrier fighter"',
 'armor':3,'penetration':0,'speed_rating':3,'projectile_damage':1,'shot_interval':0.145,
 'texture_id':'"player"','initial_weapon':1,'bullet_capacity':6,'sprite_size':'Vector2(72, 72)',
 'propeller_positions':'PackedVector2Array(0, -24)'})
for ident,model,hp,rating,weapon,style,size in [
 ('biplane_1','Kawasaki Ki-10',1,1,'Single Shot','inherit',(58,48)),
 ('biplane_2','Kawasaki Ki-10',1,1,'Single Shot','arc',(58,48)),
 ('biplane_ace','Kawasaki Ki-10',2,1,'Double Shot','cross',(62,52)),
 ('fighter_1','Nakajima Ki-43',1,2,'Single Shot','inherit',(66,56)),
 ('fighter_2','Nakajima Ki-43',1,2,'Single Shot','cross',(66,56)),
 ('fighter_ace','Nakajima Ki-44',2,2,'Double Shot','arc',(68,64)),
 ('bomber_1','Mitsubishi Ki-30',2,1,'Single Shot','inherit',(90,72)),
 ('bomber_2','Mitsubishi Ki-30',2,1,'Single Shot','arc',(90,72)),
 ('bomber_ace','Mitsubishi Ki-21',3,1,'Rockets','inherit',(126,98)),
 ('boss','B-99 Behemoth',300,1,'Fan Fire','boss',(168,138))]:
    title=ident.replace('_',' ').title() if ident!='boss' else model
    props='PackedVector2Array(-15, 31, 15, 31)' if ident=='bomber_ace' else 'PackedVector2Array(-29, 47, 29, 47)' if ident=='boss' else f'PackedVector2Array(0, {size[1]*0.50})'
    resource('enemy_'+ident,'EnemyProfile','enemy_profile',{
     'id':json.dumps(ident),'display_name':json.dumps(title),'model_name':json.dumps(model),
     'role':json.dumps('Heavy bomber boss' if ident=='boss' else 'Elite '+ident.split('_')[0] if 'ace' in ident else ident.split('_')[0].title()),
     'armor':hp,'speed_rating':1+(rating-1)*2,'projectile_damage':2 if weapon=='Rockets' else 1,
     'penetration':0,'weapon_name':json.dumps(weapon),'flight_style':json.dumps(style),
     'sprite_size':f'Vector2({size[0]}, {size[0]})','propeller_positions':props,
     'points':3000 if ident=='boss' else 300 if 'ace' in ident or 'bomber' in ident else 100,
     'shoot_interval':2.0 if ident=='boss' else 3.2 if weapon=='Rockets' else 2.8,
     'texture_id':json.dumps(ident)})
for level,name,angles,offsets in [(1,'Single Shot','0.0','0.0'),(2,'Double Shot','0.0, 0.0','-10.0, 10.0'),(3,'Triple Shot','-0.16, 0.0, 0.16','-12.0, 0.0, 12.0')]:
    resource(f'weapon_{level}','WeaponProfile','weapon_profile',{'level':level,'display_name':json.dumps(name),'angles':f'PackedFloat32Array({angles})','offsets':f'PackedFloat32Array({offsets})'})
for index,(name,pattern,enemies,density) in enumerate([
 ('First Contact','line',['biplane_1','biplane_2'],3),
 ('Island Patrol','arc',['biplane_1','biplane_2','biplane_ace'],3),
 ('Crossfire','zigzag',['fighter_1','fighter_2'],4),
 ('Heavy Escort','line',['fighter_1','fighter_ace','bomber_1'],4),
 ('Storm Front','loop',['bomber_1','bomber_2','fighter_ace'],4),
 ('Final Defense','cross',['bomber_ace','fighter_ace','biplane_ace','bomber_2','fighter_2'],5)],1):
    resource(f'wave_{index}','WaveProfile','wave_profile',{'title':json.dumps(name),'duration':30.0,'pattern':json.dumps(pattern),'enemy_ids':'PackedStringArray('+', '.join(json.dumps(x) for x in enemies)+')','density':density})
print('Wrote 20 balancing resources for Carrier Ace 0.5.')
