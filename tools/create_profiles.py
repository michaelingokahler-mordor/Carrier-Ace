"""Write the reviewed, editable Godot balancing resources."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def resource(name, cls, script, fields):
    text = f'[gd_resource type="Resource" script_class="{cls}" load_steps=2 format=3]\n'
    text += f'[ext_resource type="Script" path="res://scripts/{script}.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'
    text += ''.join(f'{key} = {value}\n' for key, value in fields.items())
    (ROOT / 'resources' / f'{name}.tres').write_text(text, encoding='utf-8')

for ident, title, hp, speed, radius, points, interval in [
    ('fighter', 'M-11 Falke', 2, 93, 17, 100, 4.2),
    ('interceptor', 'R-07 Sturmvogel', 6, 115, 19, 100, 3.8),
    ('armored', 'B-04 Büffel', 12, 72, 24, 300, 3.5),
    ('boss', 'B-99 Behemoth', 300, 0, 62, 3000, 2.0),
]:
    resource(f'enemy_{ident}', 'EnemyProfile', 'enemy_profile', {
        'id': f'"{ident}"', 'display_name': f'"{title}"', 'armor': hp,
        'speed': float(speed), 'radius': float(radius), 'points': points,
        'shoot_interval': interval, 'texture_id': f'"{ident}"',
    })

for level, name, angles, offsets in [
    (1, 'Einzelschuss', '0.0', '0.0'),
    (2, 'Doppelschuss', '0.0, 0.0', '-10.0, 10.0'),
    (3, 'Trippelschuss', '-0.16, 0.0, 0.16', '-12.0, 0.0, 12.0'),
]:
    resource(f'weapon_{level}', 'WeaponProfile', 'weapon_profile', {
        'level': level, 'display_name': f'"{name}"',
        'angles': f'PackedFloat32Array({angles})', 'offsets': f'PackedFloat32Array({offsets})',
    })

for index, (name, pattern, enemies, pickup, density) in enumerate([
    ('Erster Kontakt', 'line', ['fighter'], 'double', 3),
    ('Über den Inseln', 'arc', ['fighter', 'interceptor'], 'repair', 3),
    ('Kreuzfeuer', 'cross', ['fighter', 'interceptor'], 'speed', 4),
    ('Schwere Eskorte', 'line', ['fighter', 'armored'], 'double', 4),
    ('Sturmfront', 'arc', ['interceptor', 'fighter', 'armored'], 'triple', 4),
    ('Letzte Verteidigung', 'cross', ['armored', 'interceptor', 'fighter'], 'repair', 5),
], start=1):
    kinds = ', '.join(f'"{kind}"' for kind in enemies)
    resource(f'wave_{index}', 'WaveProfile', 'wave_profile', {
        'title': f'"{name}"', 'duration': 30.0, 'pattern': f'"{pattern}"',
        'enemy_ids': f'PackedStringArray({kinds})', 'pickup': f'"{pickup}"', 'density': density,
    })
print('Wrote 13 balancing resources.')
