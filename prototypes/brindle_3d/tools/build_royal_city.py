"""Save the mountain capital, native relief handles and painted streets.

Positions and architectural designs live in planning/royal-city.json. Regeneration
is deliberate; no assets are generated while playing.
"""
from pathlib import Path
import json,math,re
import numpy as np
from PIL import Image,ImageDraw,ImageFilter

ROOT=Path(__file__).resolve().parents[1]
PLAN=ROOT/'planning/royal-city.json'
layout=json.loads(PLAN.read_text(encoding='utf-8'))
cat={a['id']:a for a in json.loads((ROOT/'assets/royal_city/catalog.json').read_text(encoding='utf-8'))['assets']}
buildings=layout['buildings']
paths=[r for r in layout['paths'] if not r['id'].startswith('Entree_')]
props=[dict(id='Fontaine',asset='fontaine_de_la_place',xz=[-189,-166],yaw=0),
       dict(id='EtalVivres',asset='etal_marche_0',xz=[-190,-154],yaw=10),
       dict(id='EtalDraps',asset='etal_marche_1',xz=[-194,-166],yaw=90),
       dict(id='EtalArtisan',asset='etal_marche_2',xz=[-186,-172],yaw=0),
       dict(id='EtalVannerie',asset='etal_marche_3',xz=[-194,-171],yaw=0)]
for b in buildings:
    a=cat[b['asset']];b['scene']=a['scene'];b['size_m']=a['size_m'];b['bounds_center_m']=a['bounds_center_m']
for b in props:
    b['altitude']=64+max(0,-b['xz'][1]-145)*.025;b['group']='PlaceRoyale';b.update({k:cat[b['asset']][k] for k in ['scene','size_m','bounds_center_m']})

def ramp_pad(name,a,b,width=6,blend=4):
    dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
    return dict(id=name,xz=[(a[0]+b[0])/2,(a[1]+b[1])/2],altitude=(a[2]+b[2])/2,size=[width,length+1.0],yaw=math.degrees(math.atan2(dx,dz)),blend=blend,slope=[0,(b[2]-a[2])/length],outline='Rectangle')

pads=[dict(id='Royal_TerrasseVille',xz=[-174,-175],altitude=64.75,size=[119,92],yaw=0,blend=8,slope=[0,-.025],outline='Ellipse'),
      dict(id='Royal_EperonChateau',xz=[-193,-275],altitude=94,size=[91,70],yaw=0,blend=12,slope=[0,0],outline='Ellipse'),
      dict(id='Royal_CourChateau',xz=[-193,-275],altitude=94,size=[82,63],yaw=0,blend=3,slope=[0,0],outline='Rectangle')]
for i,(a,b) in enumerate(zip(layout['ramp_xyz'],layout['ramp_xyz'][1:])):pads.append(ramp_pad('Royal_Montee'+str(i),a,b,7.6,3.5))
for b in buildings:
    w,_,d=b['size_m'];cx,_,cz=b['bounds_center_m'];ang=math.radians(b['yaw']);x,z=b['xz']
    pads.append(dict(id='Royal_Assise_'+b['id'],xz=[x+cx*math.cos(ang)+cz*math.sin(ang),z-cx*math.sin(ang)+cz*math.cos(ang)],altitude=b['altitude'],size=[w+2.4,d+2.4],yaw=b['yaw'],blend=3.4,slope=[0,0],outline='Rectangle'))
# A graded approach links the drawbridge landing to the existing regional crossroads.
exit_ramp=[[-168,-105,64.2],[-159,-95,62.5],[-133,-87,60.4],[-110,-89,56.8],[-90,-90,53.91],[-81,-78,51.69],[-72,-65,50.02]]
for i,(a,b) in enumerate(zip(exit_ramp,exit_ramp[1:])):pads.append(ramp_pad('Royal_RouteSud'+str(i),a,b,8,10))

layout['props']=props;layout['pads']=pads;layout['paths']=paths
PLAN.write_text(json.dumps(layout,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
groups=list(dict.fromkeys([b['group'] for b in buildings+props]+['Chateau','Fortifications','Chemins']))
ext=['[ext_resource type="Script" path="res://scripts/sector_tools.gd" id="sector"]','[ext_resource type="Script" path="res://scripts/ground_path.gd" id="path"]']
assets={b['asset']:cat[b['asset']]['scene'] for b in buildings+props}
assets['chateau_de_montagne']=cat['chateau_de_montagne']['scene']
for asset,path in assets.items():ext.append(f'[ext_resource type="PackedScene" path="{path}" id="{asset}"]')
fort=ROOT/'scenes/sectors/ville_royale_enceinte.tscn'
if fort.exists():ext.append('[ext_resource type="PackedScene" path="res://scenes/sectors/ville_royale_enceinte.tscn" id="walls"]')
nodes=['[node name="VilleRoyale" type="Node3D"]\nscript = ExtResource("sector")\nmetadata/layout_source = "res://planning/royal-city.json"']
for group in groups:nodes.append(f'[node name="{group}" type="Node3D" parent="."]')
for b in buildings+props:
    nodes.append(f'[node name="{b["id"]}" parent="{b["group"]}" instance=ExtResource("{b["asset"]}")]\nposition = Vector3({b["xz"][0]},{b["altitude"]},{b["xz"][1]})\nrotation_degrees = Vector3(0,{b["yaw"]},0)\nmetadata/ground_offset = -0.02')
nodes.append('[node name="Citadelle" parent="Chateau" instance=ExtResource("chateau_de_montagne")]\nposition = Vector3(-193,94,-275)')
if fort.exists():nodes.append('[node name="Enceinte" parent="Fortifications" instance=ExtResource("walls")]')
for r in paths:
    ps=', '.join(str(v) for p in r['points_xz'] for v in p)
    nodes.append(f'[node name="{r["id"]}" type="MeshInstance3D" parent="Chemins"]\nvisible = false\nscript = ExtResource("path")\npoints = PackedVector2Array({ps})\nwidth_m = {r["width_m"]}')
(ROOT/'scenes/sectors/ville_royale.tscn').write_text('[gd_scene format=3]\n\n'+'\n'.join(ext)+'\n\n'+'\n\n'.join(nodes)+'\n',encoding='utf-8')

f=ROOT/'scenes/relief_godot.tscn';text=f.read_text(encoding='utf-8')
text=''.join(block for block in re.split(r'(?=\n\[node name=)',text) if not re.search(r'\[node name="Royal_',block))
for pad in pads:
    x,z=pad['xz'];w,d=pad['size'];sx,sz=pad['slope']
    text+=f'\n[node name="{pad["id"]}" type="Node3D" parent="."]\nposition = Vector3({x},{pad["altitude"]},{z})\nrotation_degrees = Vector3(0,{pad["yaw"]},0)\nscript = ExtResource("1")\nfootprint_m = Vector2({w},{d})\nblend_m = {pad["blend"]}\noutline = "{pad["outline"]}"\nslope = Vector2({sx},{sz})\n'
text=re.sub(r'(\[node name="Royal_Assise_[^\n]+\n)(.*?)(?=\n\[node|\Z)',lambda m:m[1]+m[2]+'affect_water_banks = true\n',text,flags=re.S)
f.write_text(text,encoding='utf-8')

bounds=[-255,-316,175,234];size=1024
channels=[Image.new('L',(size,size)) for _ in range(3)]
def pixel(x,z):return ((x-bounds[0])/bounds[2]*size,(z-bounds[1])/bounds[3]*size)
earth=ImageDraw.Draw(channels[0]);court=ImageDraw.Draw(channels[1])
for b in buildings:
    x,z=b['xz'];w,_,d=b['size_m'];px,pz=pixel(x,z);rx=(w*.45+.7)*size/bounds[2];rz=(d*.45+.7)*size/bounds[3]
    earth.ellipse((px-rx,pz-rz,px+rx,pz+rz),fill=215)
for r in paths:
    points=np.array(r['points_xz']);samples=[]
    for i in range(len(points)-1):
        a,b=points[i:i+2];ha=a+(points[min(i+1,len(points)-1)]-points[max(0,i-1)])/6;hb=b-(points[min(i+2,len(points)-1)]-points[i])/6
        for t in np.linspace(0,1,max(8,int(np.linalg.norm(b-a)*4))):
            q=(1-t)**3*a+3*(1-t)**2*t*ha+3*(1-t)*t*t*hb+t**3*b;samples.append(pixel(*q))
    earth.line(samples,fill=250,width=round(r['width_m']*size/bounds[2]),joint='curve')
# Worn thresholds follow each model's actual front door, including rotated houses.
for b in buildings:
    scene=(ROOT/b['scene'].removeprefix('res://')).read_text(encoding='utf-8')
    match=re.search(r'\[node name="Entrance"[^\n]+\ntransform = Transform3D\(([^)]+)\)',scene)
    if not match:continue
    values=[float(v) for v in match[1].split(',')];dx,_,dz=values[-3:]
    a=math.radians(b['yaw']);co,si=math.cos(a),math.sin(a)
    def doorstep(offset):
        return pixel(b['xz'][0]+dx*co+(dz+offset)*si,b['xz'][1]-dx*si+(dz+offset)*co)
    earth.line([doorstep(-.9),doorstep(2.1)],fill=245,width=round(1.9*size/bounds[2]))
earth.ellipse((*pixel(-196,-174),*pixel(-169,-151)),fill=235)
court.rectangle((*pixel(-229,-307),*pixel(-155,-248)),fill=245)
Image.merge('RGB',[c.filter(ImageFilter.GaussianBlur(3)) for c in channels]).save(ROOT/'assets/landscape/royal_ground_mask.png')
print('ROYAL_CITY_SAVED buildings=',len(buildings),'paths=',len(paths),'pads=',len(pads))
