"""Compose the sawmill village as editable scenes, grouped by working district."""
from pathlib import Path
import json,math,re
import numpy as np
from PIL import Image,ImageDraw,ImageFilter

ROOT=Path(__file__).resolve().parents[1]
CAT={a['id']:a for a in json.loads((ROOT/'assets/sawmill/catalog.json').read_text(encoding='utf-8'))['assets']}
buildings=[];props=[];paths=[];pads=[]

def add(name,asset,x,z,yaw,y,group,major=True):
    a=CAT[asset]
    record=dict(id=name,asset=asset,scene=a['scene'],xz=[x,z],yaw=yaw,altitude=y,group=group,size_m=a['size_m'],bounds_center_m=a['bounds_center_m'])
    source=(ROOT/a['scene'][6:]).read_text(encoding='utf-8')
    doors=[]
    for m in re.finditer(r'\[node name="(DoorFace[^"\n]*)"[^\n]*\]\ntransform = Transform3D\(([^\n]*)\)',source):
        values=[float(v.strip()) for v in m[2].split(',')]
        if values[-2]<1.1:doors.append(values[-3:])
    record['doors_local']=doors
    (buildings if major else props).append(record)
    return record

def prop(name,asset,x,z,yaw=0,y=46,group='Ateliers'):return add(name,asset,x,z,yaw,y,group,False)
def road(name,width,points):paths.append(dict(id=name,width_m=width,points_xz=points))

# Northern timber yards receive the forest carts. The river skirts the eastern edge.
add('DepotForestier','depot_grumes',240,-194,12,51.7,'CourDesGrumes')
add('RemiseVoitures','hangar_charrettes_bois',220,-187,20,50.8,'CourDesGrumes')
add('HalleCharron','atelier_charron',235,-179,-5,50.0,'CourDesGrumes')
add('BaraquementBucherons','baraquement_des_equipes',252,-186,-5,51.0,'Logements')
add('Sechoir','halle_sechage',250,-174,0,49.8,'Sechage')

# Houses face short, gently bent lanes leading to the shared square.
add('MaisonMaitreScieur','logis_du_contremaitre_en_l',237,-164,-12,48.4,'Logements')
add('MaisonDeuxVolumes','maison_aux_deux_volumes',222,-165,8,48.8,'Logements')
add('LogisLisiere','logis_porte_basse',210,-153,62,47.7,'Logements')
add('MaisonColombages','logis_a_colombages',228,-148,172,47.0,'Logements')
add('BaraquementGalerie','baraquement_a_galerie',212,-135,95,45.6,'Logements')
add('MaisonVoituriers','maison_des_charretiers',223,-128,175,44.7,'Logements')
add('MaisonRive','maison_au_toit_decale',212,-166,5,48.8,'Logements')

# The mill occupies the lower bank, with room for the ramp and side access.
add('GrandeScierie','scierie_hydraulique',250,-147,0,44.20,'RiveDuMoulin')
add('AtelierCharpentier','atelier_charpentier',247,-135,-90,44.7,'Ateliers')
add('ComptoirBois','bureau_bois',235,-141,-5,46.0,'PlaceDuVillage')

prop('PortiqueGrumes','portique_chargement',235,-188,0,51.0,'CourDesGrumes')
prop('CharretteChargement','charrette_grumes',224,-184,-12,50.8,'CourDesGrumes')
prop('ReserveTroncs','grumes_longues',246,-199,12,51.7,'CourDesGrumes')
prop('ReserveBillons','grumes_courtes',235,-202,0,51.7,'CourDesGrumes')
prop('TraineauForet','traineau_debardage',224,-197,10,51.2,'CourDesGrumes')
prop('ScieursDeLong','fosse_sciage',218,-175,5,49.8,'Ateliers')
prop('ChevaletsCharpente','chevalets_sciage',240,-128,0,44.7,'Ateliers')
prop('ReservePoutres','poutres_equarries',258,-184,0,50.8,'Sechage')
prop('PlanchesAuSec','tas_planches',255,-172,0,49.8,'Sechage')
prop('BillonsSciage','grumes_courtes',244,-148,0,44.2,'RiveDuMoulin')
prop('ChutesAtelier','tas_chutes',250,-130,0,44.7,'Ateliers')
prop('OutilsBucherons','ratelier_outils_bois',216,-172,-90,49.8,'Ateliers')
prop('BillotCour','billot_fendage',225,-169,0,48.8,'Logements')
prop('TonneauxComptoir','tonneaux_resine',237,-144,0,46.0,'PlaceDuVillage')
prop('EtabliExterieur','etabli_menuisier',242,-128,-90,44.7,'Ateliers')

# Four legible streets, irregular in plan but with clear junctions and work courts.
road('RouteForestiere',4.0,[[236,-217],[233,-205],[229,-194],[229,-184],[229,-175]])
road('RueDuBois',3.6,[[229,-175],[232,-170],[232,-159],[236,-153],[240,-145],[241,-138],[237,-133],[235,-132]])
road('RueDesLogis',2.8,[[229,-159],[220,-158],[218,-150],[219,-142],[221,-135],[228,-133],[235,-132]])
road('VenelleDesVoituriers',2.5,[[218,-133],[221,-135],[228,-133]])
road('CourSechage',3.5,[[232,-170],[240,-172],[245,-168.5],[250,-168.5]])
road('AccesMoulin',3.3,[[241,-138],[243,-141],[247,-140.9],[250,-140.8]])
road('PlaceAuPont',3.8,[[235,-132],[234,-126],[230,-124],[228.95,-119.91]])
road('AteliersPlace',3.2,[[235,-132],[240,-132],[243,-135]])

road('CourBucherons',2.6,[[229,-184],[235,-184],[244,-182],[250,-180],[255,-180]])

# Door approaches use actual saved markers; main streets are checked in Godot.
main_paths=list(paths)

for b in buildings:
    a=math.radians(b['yaw']);rot=np.array([[math.cos(a),math.sin(a)],[-math.sin(a),math.cos(a)]])
    b['door_approaches']=[]
    for index,door in enumerate(b['doors_local']):
        local_door=np.array([door[0],door[2]+1.15])
        if b['id']=='AtelierCharpentier':local_door=np.array([2.2,4.3])
        if b['id']=='ComptoirBois':local_door=np.array([.80,2.85])
        target=np.array(b['xz'])+rot@local_door
        start=target+rot@np.array([0,3.0])
        b['door_approaches'].append([start.tolist(),target.tolist()])
        candidates=[]
        for route in main_paths:
            for a,c in zip(route['points_xz'],route['points_xz'][1:]):
                a=np.array(a);c=np.array(c);delta=c-a
                nearest=a+np.clip(np.dot(start-a,delta)/np.dot(delta,delta),0,1)*delta
                candidates.append((np.linalg.norm(nearest-start),nearest))
        link=min(candidates,key=lambda pair:pair[0])[1]
        road('Entree_'+b['id']+str(index),1.6,[link.tolist(),start.tolist(),target.tolist()])

# A broad north-south fall keeps neighbourhoods connected; smaller pads seat buildings.
pads=[dict(id='Scierie_TerrasseQuartiers',xz=[228,-159],altitude=47.9,size=[50,76],yaw=0,blend=12,outline='Ellipse',slope=[.015,-.12]),
      dict(id='Scierie_Place',xz=[233,-132],altitude=45.0,size=[12,10],yaw=-8,blend=7,outline='Ellipse',slope=[.01,-.05]),
      dict(id='Scierie_CourMoulin',xz=[249,-142],altitude=44.2,size=[13,17],yaw=0,blend=5,outline='Rectangle')]
# Graded cartway from upper yards to the mill, before the individual house seats.
ramp=[[232,-170,49.3],[232,-159,48.0],[236,-153,47.2],[240,-145,45.9],[241,-138,44.7]]
for i,(a,b) in enumerate(zip(ramp,ramp[1:])):
    dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
    pads.append(dict(id='Scierie_RampeBois'+str(i),xz=[(a[0]+b[0])/2,(a[1]+b[1])/2],altitude=(a[2]+b[2])/2,size=[5.4,length+1.2],yaw=math.degrees(math.atan2(dx,dz)),blend=4,outline='Rectangle',slope=[0,(b[2]-a[2])/length]))
for b in buildings:
    s=b['size_m'];c=b['bounds_center_m'];a=math.radians(b['yaw'])
    x,z=b['xz'];cx=x+c[0]*math.cos(a)+c[2]*math.sin(a);cz=z-c[0]*math.sin(a)+c[2]*math.cos(a)
    if b['id']=='GrandeScierie':continue
    pads.append(dict(id='Scierie_Sol_'+b['id'],xz=[cx,cz],altitude=b['altitude'],size=[s[0]+3.5,s[2]+3.5],yaw=b['yaw'],blend=4.0,outline='Rectangle'))

# Protect the small logis seat from the neighbouring graded street blend.
for pad in list(pads):
    if pad['id']=='Scierie_Sol_MaisonColombages':pads.append(dict(pad,id=pad['id']+'_Assise',blend=1.5))

# Loaded carts leave the bridge along a continuous, modest rise toward the ironworks.
exit_ramp=[[232.0933,-102.184,44.1],[241,-90,47.0],[243,-80,49.2],[243,-70,51.3],[243,-60,48.7],[243,-51,47.6]]
for i,(a,b) in enumerate(zip(exit_ramp,exit_ramp[1:])):
    dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
    pads.append(dict(id='Scierie_RouteAcierie'+str(i),xz=[(a[0]+b[0])/2,(a[1]+b[1])/2],altitude=(a[2]+b[2])/2,size=[7,length+2],yaw=math.degrees(math.atan2(dx,dz)),blend=7,outline='Rectangle',slope=[0,(b[2]-a[2])/length]))

# Smooth the pre-existing terrace lip on the connecting cart route outside the ironworks.
a=[179,50,37.35];b=[194,55,43.1];dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
pads.append(dict(id='Scierie_RaccordGrandeRoute',xz=[186.5,52.5],altitude=(a[2]+b[2])/2,size=[6,length+1],yaw=math.degrees(math.atan2(dx,dz)),blend=5,outline='Rectangle',slope=[0,(b[2]-a[2])/length]))

layout=dict(version=1,focus_xz=[235,-159],bounds_xz=[199,-205,72,91],buildings=buildings,props=props,paths=paths,pads=pads,
 districts=['CourDesGrumes','Sechage','Logements','PlaceDuVillage','Ateliers','RiveDuMoulin'],
 hydraulics=dict(mill_origin_xyz=[250,44.2,-147],headwater_y=48.88,flume_water_y=48.76,tailwater_y=44.22,lake_y=40,
 intake_xyz=[254.65,48.76,-154.25],wheel_axis_xyz=[254.65,46.45,-147.65]))
(ROOT/'planning/sawmill-town.json').write_text(json.dumps(layout,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

ext=['[ext_resource type="Script" path="res://scripts/sector_tools.gd" id="sector"]','[ext_resource type="Script" path="res://scripts/ground_path.gd" id="path"]',
     '[ext_resource type="Script" path="res://scripts/sawmill_machinery.gd" id="motion"]',
     '[ext_resource type="Material" path="res://materials/brindle_path.tres" id="path_material"]',
     '[ext_resource type="PackedScene" path="res://scenes/sectors/scierie_eau.tscn" id="waterworks"]',
     '[ext_resource type="PackedScene" path="res://scenes/sectors/scierie_cours.tscn" id="courtyards"]']
assets={a:i for i,a in enumerate(sorted({b['asset'] for b in buildings+props}))}
for asset,i in assets.items():ext.append(f'[ext_resource type="PackedScene" path="{CAT[asset]["scene"]}" id="asset_{i}"]')
nodes=['[node name="Scierie" type="Node3D"]\nscript = ExtResource("sector")\nmetadata/layout_source = "res://planning/sawmill-town.json"']
for group in layout['districts']+['Chemins']:nodes.append(f'[node name="{group}" type="Node3D" parent="."]')
for b in buildings+props:
    x,z=b['xz'];y=b['altitude'];angle=math.radians(b['yaw'])
    nodes.append(f'[node name="{b["id"]}" parent="{b["group"]}" instance=ExtResource("asset_{assets[b["asset"]]}")]\nposition = Vector3({x},{y},{z})\nrotation = Vector3(0,{angle},0)\nmetadata/ground_offset = -0.02')
for i,r in enumerate(paths):
    ps=', '.join(str(v) for p in r['points_xz'] for v in p)
    nodes.append(f'[node name="{r["id"]}" type="MeshInstance3D" parent="Chemins"]\nvisible = false\nscript = ExtResource("path")\nmaterial_override = ExtResource("path_material")\npoints = PackedVector2Array({ps})\nwidth_m = {r["width_m"]}\nsurface_offset_m = {0.045+i*.0007}')
nodes.append('[node name="CoursEtJardins" parent="." instance=ExtResource("courtyards")]')
nodes.append('[node name="AmenagementsEau" parent="." instance=ExtResource("waterworks")]')
nodes.append('[node name="Mecanisme" type="Node3D" parent="RiveDuMoulin/GrandeScierie"]\nscript = ExtResource("motion")')
(ROOT/'scenes/sectors/scierie.tscn').write_text('[gd_scene format=3]\n\n'+'\n'.join(ext)+'\n\n'+'\n\n'.join(nodes)+'\n',encoding='utf-8')

p=ROOT/'scenes/relief_godot.tscn';text=p.read_text(encoding='utf-8')
blocks=re.split(r'(?=\n\[node name=)',text)
text=''.join(block for block in blocks if not re.search(r'\[node name="Scierie_',block))
for pad in pads:
    x,z=pad['xz'];w,d=pad['size'];sx,sz=pad.get('slope',[0,0])
    text+=f'\n[node name="{pad["id"]}" type="Node3D" parent="."]\nposition = Vector3({x},{pad["altitude"]},{z})\nrotation_degrees = Vector3(0,{pad["yaw"]},0)\nscript = ExtResource("1")\nfootprint_m = Vector2({w},{d})\nblend_m = {pad["blend"]}\noutline = "{pad["outline"]}"\nslope = Vector2({sx},{sz})\n'
p.write_text(text,encoding='utf-8')

# Ground wear is paint in the existing terrain shader, not a thick floor slab.
bounds=[198,-210,80,105];size=768
channels=[Image.new('L',(size,size)) for _ in range(3)]
def pixel(x,z):return ((x-bounds[0])/bounds[2]*size,(z-bounds[1])/bounds[3]*size)
for b in buildings+props:
    x,z=b['xz'];w,d=b['size_m'][0],b['size_m'][2]
    if b['id']=='GrandeScierie':w,d=10,11
    px,pz=pixel(x,z);rx=(w*.49+.35)*size/bounds[2];rz=(d*.49+.35)*size/bounds[3]
    ImageDraw.Draw(channels[0]).ellipse((px-rx,pz-rz,px+rx,pz+rz),fill=210)
    if b['group'] in ['CourDesGrumes','Sechage','Ateliers']:
        ImageDraw.Draw(channels[1]).ellipse((px-rx*.6,pz-rz*.6,px+rx*.6,pz+rz*.6),fill=160)
draw=ImageDraw.Draw(channels[0]);a=pixel(227,-137);b=pixel(239,-127);draw.ellipse((*a,*b),fill=225)
for r in paths:
    points=np.array(r['points_xz']);samples=[]
    for i in range(len(points)-1):
        a,b=points[i:i+2];ha=a+(points[min(i+1,len(points)-1)]-points[max(0,i-1)])/6
        hb=b-(points[min(i+2,len(points)-1)]-points[i])/6
        for t in np.linspace(0,1,max(6,int(np.linalg.norm(b-a)*5))):
            q=(1-t)**3*a+3*(1-t)**2*t*ha+3*(1-t)*t*t*hb+t**3*b;samples.append(pixel(*q))
    draw.line(samples,fill=245,width=round((r['width_m']+.15)*size/80),joint='curve')
Image.merge('RGB',[c.filter(ImageFilter.GaussianBlur(4)) for c in channels]).save(ROOT/'assets/landscape/sawmill_ground_mask.png')

# The existing lake/ironworks roads now join the new bridge's actual two landings.
p=ROOT/'planning/river-routes-v2.json';routes=json.loads(p.read_text(encoding='utf-8'))
bridge=next(c for c in json.loads((ROOT/'assets/landscape/landscape.json').read_text())['crossings'] if c['id']=='PontVillageScierie')
direction=np.array(bridge['direction_xz']);center=np.array(bridge['center_xyz'])[::2]
north=center-direction*6;south=center+direction*6;south_far=center+direction*12
for r in routes['routes']:
    if r['id']=='LacScierie':r['points_xz']=r['points_xz'][:4]+[[185,-87],[213,-93],south_far.tolist(),south.tolist()]
    if r['id']=='ScierieAcierie':r['points_xz']=[south.tolist(),south_far.tolist(),[241,-90],[243,-51],[244,-12],[250,20],[255,65]]
p.write_text(json.dumps(routes,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('SAWMILL_TOWN',len(buildings),'buildings',len(props),'props',len(paths),'paths')
