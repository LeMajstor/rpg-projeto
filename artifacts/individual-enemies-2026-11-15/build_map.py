"""Mapa de orientação autorado a partir dos mesmos dados do catálogo jogável."""
import html,json,math
from pathlib import Path
from xml.etree import ElementTree
root=Path(__file__).resolve().parents[2]
lab=json.loads((root/'data/lab.json').read_text())
presets={p['id']:p for p in lab['presets']}
colors={'heavy':'#edb26d','agile':'#f38a8a','flying':'#8ce0ff','static':'#ffe28c'}
names={'heavy':'Pesado','agile':'Ágil','flying':'Voador','static':'Estático'}
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="2180" viewBox="0 0 2560 3720">',
 '<rect width="2560" height="3720" fill="#0e1b22"/>',
 '<style>text{font-family:Arial,sans-serif;fill:#e2ecee} .small{font-size:24px} .title{font-size:40px;font-weight:bold}</style>',
 '<text x="80" y="66" class="title">Dungeon · D158 · 18 monstros / 6 encontros</text>',
 '<text x="80" y="110" class="small">Detecção individual · paredes bloqueiam visão · qualquer integrante inicia o grupo completo</text>']
for floor,file in enumerate(['dungeon.json','dungeon_upper.json']):
 d=json.loads((root/'data'/file).read_text()); oy=180+floor*1720
 parts.append(f'<g transform="translate(80 {oy})">')
 parts.append(f'<text x="0" y="-24" class="title">{html.escape(d["label"])}</text>')
 parts.append('<rect width="2400" height="1600" fill="#253941" stroke="#647980" stroke-width="3"/>')
 for region in d.get('regions',[]):
  x,y,w,h=region['rect'];parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#{region["color"]}" opacity=".65"/>')
 actors=[]
 for group in d['encounters']:
  for participant in presets[group['battle_preset_id']]['enemies']:
   member=group['members'][participant['id']];profile=lab['enemy_types'][participant['type']]['movement_behavior'];color=colors[profile]
   x,y=member['position'];label=group['label'].split(' · ')[0]+'/'+participant['id'].upper()
   actors.append((x,y,label,profile))
   if profile=='static':
    dx,dy=member['vision_direction'];angle=math.atan2(dy,dx);a=angle-math.pi/4;b=angle+math.pi/4
    x1,y1=x+180*math.cos(a),y+180*math.sin(a);x2,y2=x+180*math.cos(b),y+180*math.sin(b)
    parts.append(f'<circle cx="{x}" cy="{y}" r="60" fill="{color}" fill-opacity=".12" stroke="{color}" stroke-width="2"/>')
    parts.append(f'<path d="M{x},{y} L{x1},{y1} A180,180 0 0,1 {x2},{y2} Z" fill="{color}" fill-opacity=".08" stroke="{color}" stroke-width="2"/>')
   else:
    route=member['route']+([member['route'][0]] if profile=='flying' else [])
    pts=' '.join(f'{a},{b}' for a,b in route)
    parts.append(f'<polyline points="{pts}" fill="none" stroke="{color}" stroke-width="3" stroke-dasharray="10 7" opacity=".8"/>')
 for wall in d['obstacles']:
  x,y,w,h=wall['rect'];parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#778c91" stroke="#9aabb0" stroke-width="2"/>')
 for wall in d.get('wall_shapes',[]):
  pts=' '.join(f'{x},{y}' for x,y in wall['points']);parts.append(f'<polygon points="{pts}" fill="#697e84" stroke="#9aabb0" stroke-width="2"/>')
 for obj in d['objects']:
  x,y=obj['position']
  if obj['object_type']=='door':
   rx,ry,w,h=obj['rect'];parts.append(f'<rect x="{rx}" y="{ry}" width="{w}" height="{h}" fill="#a38a55"/>')
  parts.append(f'<circle cx="{x}" cy="{y}" r="12" fill="#d8bd80"/><text x="{x+20}" y="{y+8}" class="small">{html.escape(obj["label"])}</text>')
 for x,y,label,profile in actors:
  color=colors[profile];parts.append(f'<circle cx="{x}" cy="{y}" r="16" fill="{color}" stroke="#10212a" stroke-width="3"/><text x="{x+24}" y="{y-20}" class="small">{label} · {names[profile]}</text>')
 for t in d['transitions']:
  x,y=t['position'];parts.append(f'<circle cx="{x}" cy="{y}" r="18" fill="#6ecbb5"/><text x="{x+28}" y="{y+8}" class="small">{html.escape(t["label"])}</text>')
 parts.append('</g>')
parts.extend(['<text x="80" y="3660" class="small">Tracejado: rota original · amarelo: círculo60 + cone180/90° dos estáticos (sólidos bloqueiam ativação)</text>', '</svg>'])
svg='\n'.join(parts)+'\n';ElementTree.fromstring(svg)
out=Path(__file__).with_name('mapa-dungeon.svg');out.write_text(svg)
print(out)
