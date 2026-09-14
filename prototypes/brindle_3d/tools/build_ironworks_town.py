"""Compose the approved kit into an editable settlement; no mesh duplication."""
from pathlib import Path
import json, math, re
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
CAT={a['id']:a for a in json.loads((ROOT/'assets/ironworks/catalog.json').read_text(encoding='utf-8'))['assets']}
buildings=[];props=[];roads=[];pads=[]
def add(name,asset,x,z,yaw=0,y=43.1,group='Habitations',major=True):
    a=CAT[asset]
    item=dict(id=name,asset=asset,scene=a['scene'],xz=[x,z],altitude=y,yaw=yaw,group=group,size_m=a['size_m'],bounds_center_m=a['bounds_center_m'],building_design=a.get('building_design',''),building_kind=a.get('building_kind',''))
    source=(ROOT/a['scene'].replace('res://','')).read_text(encoding='utf-8')
    match=re.search(r'\[node name="Entrance"[^\n]*\]\ntransform = Transform3D\([^\n]*, ([^,]+), ([^,]+), ([^,)]+)\)',source)
    if match:
        px,_,pz=map(float,match.groups());rad=math.radians(yaw)
        # Exterior access stops in front of the closed door, counter or first step.
        pz+=1.05 if asset!='grenier_vivres' else 1.35
        item['entrance_xz']=[x+px*math.cos(rad)+pz*math.sin(rad),z-px*math.sin(rad)+pz*math.cos(rad)]
    (buildings if major else props).append(item)
    return item
def prop(name,asset,x,z,yaw=0,group='Production'):
    return add(name,asset,x,z,yaw,group=group,major=False)
def road(name,width,pts):roads.append(dict(id=name,width_m=width,points_xz=pts))

# Dwellings follow two curved lanes, with larger communal roofs breaking the silhouette.
for v in [
 ('MaisonEntreeNord','logis_porte_basse',197,6,10,43.0),
 ('MaisonPignon','maison_aux_deux_volumes',208,2,8,43.6),
 ('MaisonHaute','baraquement_des_equipes',220,-2,20,44.0),
 ('MaisonArdoise','logis_a_colombages',231,2,-50,43.8),
 ('MaisonCourInterieure','baraque_jumelee_de_la_cour',218,18,90,43.2),
 ('MaisonVirage','maison_du_virage',200,32,90,42.8),
 ('MaisonVenelle','maison_haute_de_la_venelle',211,33,90,43.1),
 ('DortoirNord','baraquement_de_la_grande_cour',206,19,0,43.2),
 ('DortoirPlace','baraquement_a_galerie',234,29,-90,43.1),
 ('MaisonContremaitre','logis_du_contremaitre_en_l',239,14,-90,43.2),
 ('MaisonOuest','maison_des_charretiers',192,37,50,42.8),
 ('MaisonJardin','maison_au_toit_decale',198,47,30,42.8),
]:add(*v)
for v in [
 ('CuisineCommune','cuisine_commune',218,44,85,43.0),
 ('GrenierCommun','grenier_vivres',212,54,0,42.9),
 ('EcurieEntree','remise_ecurie',199,71,30,41.2),
 ('RelaisCharrettes','hangar_charrettes',216,78,180,42.2),
 ('RemiseSud','remise_des_betes_de_trait',205,83,75,41.8),
]:add(*v,group='Services')
for v in [
 ('BureauPesee','bureau_pesee',241,56,5,43.0),
 ('AtelierOutillage','atelier_outilleur',231,56,-8,43.0),
 ('HalleExpedition','depot_barres',232,77,175,41.4),
 ('ReserveBarres','reserve_barres_longue',220,56,0,43.0),
 ('TriArriveeMine','halle_tri_minerai',267.5,44.5,-90,43.0),
 ('TriReserveMinerai','tri_minerai_a_pignon',274,28,-90,43.0),
 ('CharbonRouteScierie','depot_charbon',256,4,180,44.0),
 ('CharbonReserve','charbon_halle_a_croupes',268,9,90,44.0),
 ('HalleMartelage','forge_affinage',242,36,90,43.1),
 ('ForgeFinition','forge_de_finition_a_pignon',244,47,85,43.1),
]:add(*v,group='Production')

road('RueDuBourg',3.5,[[224,66],[225,60],[225,52],[228,45],[227,36],[224,28],[225,19],[223,11]])
road('BoucleOuvriere',2.8,[[224,28],[216,26],[207,26],[196,24],[192,17],[199,11],[211,10],[223,11]])
road('VenelleCuisine',2.6,[[207,26],[205,33],[208,40],[214,48],[225,52]])
road('CourOuest',2.2,[[205,33],[205,39],[200,39],[197,40]])
road('CourDuJardin',2.2,[[205,39],[206,45],[205,51],[201,53],[208,56],[214,62]])
road('CourDesFourneaux',3.5,[[253,48],[258,43],[261,38],[260,29],[255,23],[250,20]])
road('CourDuMinerai',3.4,[[257,53],[260,49],[262,43],[265,37],[269,36],[272,35]])
road('CourCharbon',3.5,[[250,20],[248,10],[249,-3],[261,-3],[272,1],[275,13],[271,22],[260,29]])
road('ExpeditionSud',3.8,[[224,66],[228,70],[229,71],[232,71],[238,70],[247,66]])
road('RelaisEntree',3.8,[[207,60],[211,67],[214,71],[216,71],[228,70]])
road('Remises',2.9,[[211,67],[207,73],[210,78],[210,84]])
road('ComptoirForges',2.8,[[241,65],[247,61],[248,53],[249,46],[250,39],[250,31]])
road('PlaceCommune',3.0,[[225,52],[233,48],[238,43],[237,37],[237,34]])
road('MaisonsHautes',2.3,[[223,11],[228,8],[233,8],[235,9]])
road('AccesContremaitre',2.2,[[225,19],[232,18],[234,15]])

# Each front door has a short, separate approach; no story or interaction is attached.
for b in buildings:
    if 'entrance_xz' not in b:continue
    p=np.array(b['entrance_xz']);rad=math.radians(b['yaw']);out=p+np.array([math.sin(rad),math.cos(rad)])*1.6
    # Attach to a manually chosen court or lane, avoiding a straight line through neighbours.
    joins={
      'MaisonEntreeNord':[199,11],'MaisonPignon':[211,10],'MaisonHaute':[223,11],'MaisonArdoise':[228,8],
      'MaisonCourInterieure':[225,19],'MaisonVirage':[205,33],'MaisonVenelle':[217,35],
      'DortoirNord':[207,26],'DortoirPlace':[227,29],'MaisonContremaitre':[234,15],
      'MaisonOuest':[197,40],'MaisonJardin':[201,53],'CuisineCommune':[228,45],
      'GrenierCommun':[214,62],'EcurieEntree':[207,73],'RelaisCharrettes':[216,71],'RemiseSud':[210,84],
      'BureauPesee':[241,65],'AtelierOutillage':[231,65],'HalleExpedition':[232,71],
      'ReserveBarres':[224,66],'TriArriveeMine':[262,43],'TriReserveMinerai':[269,36],
      'CharbonRouteScierie':[257,-3],'CharbonReserve':[275,13],'HalleMartelage':[250,39],'ForgeFinition':[249,46],
    }
    b['approach_xz']=[joins[b['id']],out.tolist(),p.tolist()]
    road('Acces_'+b['id'],2.0 if b['group']=='Habitations' else 2.8,b['approach_xz'])

for v in [
 ('PuitsDuBourg','puits_abreuvoir',222,37,15,'Services'),
 ('LatrinesSud','latrines_a_deux_places',196,86,175,'Services'),
 ('LatrinesOuest','latrines_bois',191,46,-5,'Services'),
 ('FourneauUn','bas_fourneau_actif',258,33,-85,'Production'),
 ('FourneauDeux','bas_fourneau_pierre',264,23,170,'Production'),
 ('FourneauTrois','bas_fourneau_argile',259,21,-95,'Production'),
 ('FourneauQuatre','bas_fourneau_actif',266,18,160,'Production'),
 ('FourneauCinq','bas_fourneau_pierre',256,39,-115,'Production'),
 ('FourneauSix','bas_fourneau_argile',265,33,-15,'Production'),
 ('GrillageUn','grillage_minerai',270,39,-20,'Production'),
 ('GrillageDeux','grillage_minerai',275,37,10,'Production'),
 ('ConcassageDeux','concassage_minerai',276,21,-85,'Production'),
 ('MineraiBrutDeux','tas_minerai',276,45,35,'Production'),
 ('MineraiBrutTrois','tas_minerai',278,30,65,'Production'),
 ('BacsTries','bacs_minerai',264,51,-80,'Production'),
 ('CharretteMine','charrette_ore',266,54,95,'Production'),
 ('CharrettePrete','charrette_bars',237,75,165,'Production'),
 ('BarresExpediees','barres_fer_liees',229,73,85,'Production'),
 ('CuveOuvriere','cuve_trempe',246.7,42,-45,'Production'),
 ('LoupeChaude','loupe_fer_brute',255,35,0,'Production'),
 ('EnclumeCour','billot_enclume',255,34,25,'Production'),
 ('TuyeresReserve','tuyeres_argile',269.25,10.5,90,'Production'),
 ('ReserveBoisNord','buches_rangees',263,3,20,'Production'),
 ('BoisCuisine','buches_rangees',213,44,85,'Services'),
 ('MeuleOutillage','meule_manivelle',243.1,34.3,90,'Production'),
 ('EnseigneAtelier','enseigne_forge',238,60,10,'Production'),
 ('ScoriesFroidesUn','tas_scories',228,85,-15,'Dechets'),
 ('ScoriesFroidesDeux','tas_scories',232,85,20,'Dechets'),
 ('ScoriesFroidesTrois','tas_scories',230,87,50,'Dechets'),
]:prop(*v)
for item in props:
    if item['id']=='MeuleOutillage':item['sheltered_by']='HalleMartelage'
    if item['id']=='TuyeresReserve':item['sheltered_by']='CharbonReserve'

# Small yard fragments leave visible openings instead of enclosing circulation.
for name,asset,points in [
 ('MuretCharbon','soubassement_2m',[(252,7,90),(252,5,90),(252,3,90),(255,8,0),(257,8,0)]),
 ('MuretMinerai','soubassement_2m',[(277,41,90),(277,43,90),(277,47,90),(274,50,0)]),
 ('ScoriesContainment','soubassement_2m',[(225,83,90),(225,85,90),(225,87,90),(227,89,0),(229,89,0),(231,89,0),(233,89,0),(235,86,90)]),
 ('JardinHaute','cloture_2m',[(218,-7,0),(220,-7,0),(222,-7,0),(216,-5,90)]),
 ('CourPignon','cloture_2m',[(206,-3,0),(208,-3,0),(211,-1,90)]),
 ('CourOuest','cloture_2m',[(194,46,90),(194,48,90),(197,51,0)]),
 ('EnclosEcurie','cloture_2m',[(196,75,90),(196,77,90),(198,77,0),(200,77,0)]),
]:
    for i,(x,z,yaw) in enumerate(points):prop(f'{name}_{i:02}',asset,x,z,yaw,'Abords')
# Houses already contain sheltered wood stores and barrels in their reusable scenes.

# Broad existing terrace first; independent local pads remain editable in Godot.
pads=[dict(id='TerrasseBourgAcierie',xz=[234,30],altitude=43.1,size=[73,65],yaw=0,blend=13,outline='Ellipse'),
      dict(id='TerrasseOuestAcierie',xz=[198,36],altitude=42.8,size=[15,27],yaw=0,blend=12,outline='Ellipse'),
      dict(id='TerrasseCharbonAcierie',xz=[264,6],altitude=44.0,size=[25,24],yaw=0,blend=12,outline='Ellipse'),
      dict(id='CourLogistiqueAcierie',xz=[220,74],altitude=42.0,size=[27,16],yaw=-8,blend=12,outline='Ellipse'),
      dict(id='CourScoriesAcierie',xz=[230,85.5],altitude=40.65,size=[11,8],yaw=0,blend=3,outline='Rectangle')]
for b in buildings:
    s=b['size_m'];c=b['bounds_center_m'];a=math.radians(b['yaw'])
    pads.append(dict(id='Sol_'+b['id'],xz=[b['xz'][0]+c[0]*math.cos(a)+c[2]*math.sin(a),b['xz'][1]-c[0]*math.sin(a)+c[2]*math.cos(a)],altitude=b['altitude'],size=[s[0]+2.6,s[2]+3.0],yaw=b['yaw'],blend=3.5,outline='Rectangle'))
for b in props:
    if b['asset'].startswith(('bas_fourneau','grillage','concassage')):
        s=b['size_m'];c=b['bounds_center_m'];a=math.radians(b['yaw'])
        pads.append(dict(id='Sol_'+b['id'],xz=[b['xz'][0]+c[0]*math.cos(a)+c[2]*math.sin(a),b['xz'][1]-c[0]*math.sin(a)+c[2]*math.cos(a)],altitude=43.1,size=[s[0]+3.4,s[2]+3.4],yaw=b['yaw'],blend=3,outline='Rectangle'))
    elif b['asset'] in ('latrines_bois','latrines_a_deux_places'):
        pads.append(dict(id='Sol_'+b['id'],xz=b['xz'],altitude=40.9 if b['id']=='LatrinesSud' else 42.6,size=[5,5],yaw=b['yaw'],blend=3,outline='Rectangle'))

layout=dict(version=2,seed=914,description='Medieval bloomery settlement, graphics workshop only.',focus_xz=[233,37],bounds_xz=[185,-10,100,104],buildings=buildings,props=props,paths=roads,pads=pads)
(ROOT/'planning/ironworks-town.json').write_text(json.dumps(layout,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

# Native scene instances share every kit mesh and material with the catalogue.
ext=['[ext_resource type="Script" path="res://scripts/sector_tools.gd" id="sector"]','[ext_resource type="Script" path="res://scripts/ground_path.gd" id="path"]','[ext_resource type="Material" path="res://materials/ironworks_path.tres" id="path_material"]','[ext_resource type="PackedScene" path="res://prototype_3d/assets/library/trees/birch_twin.tscn" id="birch"]']
asset_ids={a:i for i,a in enumerate(sorted({b['asset'] for b in buildings+props}))}
for asset,i in asset_ids.items():ext.append(f'[ext_resource type="PackedScene" path="{CAT[asset]["scene"]}" id="asset_{i}"]')
nodes=['[node name="Acierie" type="Node3D"]\nscript = ExtResource("sector")\nmetadata/layout_source = "res://planning/ironworks-town.json"']
for group in ['Habitations','Services','Production','Dechets','Abords','Chemins']:nodes.append(f'[node name="{group}" type="Node3D" parent="."]')
for b in buildings+props:
    x,z=b['xz'];y=b['altitude'];a=math.radians(b['yaw'])
    nodes.append(f'[node name="{b["id"]}" parent="{b["group"]}" instance=ExtResource("asset_{asset_ids[b["asset"]]}")]\nposition = Vector3({x}, {y}, {z})\nrotation = Vector3(0, {a}, 0)\nmetadata/ground_offset = -0.025\nmetadata/town_building = {str(b in buildings).lower()}')
for path_index,r in enumerate(roads):
    ps=', '.join(str(float(v)) for p in r['points_xz'] for v in p)
    nodes.append(f'[node name="{r["id"]}" type="MeshInstance3D" parent="Chemins"]\nscript = ExtResource("path")\nmaterial_override = ExtResource("path_material")\npoints = PackedVector2Array({ps})\nwidth_m = {float(r["width_m"])}\nsurface_offset_m = {0.06+path_index*0.0008:.4f}')
for i,(x,z,scale,yaw) in enumerate([(214,4,.53,25),(216,37,.46,150),(228,22,.5,65),(202,-5,.65,20),(187,23,.72,65)]):
    nodes.append(f'[node name="Bouleau_{i}" parent="Abords" instance=ExtResource("birch")]\nposition = Vector3({x},43,{z})\nrotation_degrees = Vector3(0,{yaw},0)\nscale = Vector3({scale},{scale},{scale})\nmetadata/ground_offset = -0.05')
(ROOT/'scenes/sectors/acierie.tscn').write_text('[gd_scene format=3]\n\n'+'\n'.join(ext)+'\n\n'+'\n\n'.join(nodes)+'\n',encoding='utf-8')
relief=(ROOT/'scenes/relief_godot.tscn').read_text(encoding='utf-8')
blocks=re.split(r'(?=\n\[node name=)',relief)
base=''.join(block for block in blocks if not re.search(r'\[node name="(?:Sol_|TerrasseBourgAcierie|TerrasseOuestAcierie|TerrasseCharbonAcierie|CourLogistiqueAcierie|CourScoriesAcierie)',block))
for p in pads:
    base+=f'\n[node name="{p["id"]}" type="Node3D" parent="."]\nposition = Vector3({p["xz"][0]}, {p["altitude"]}, {p["xz"][1]})\nrotation_degrees = Vector3(0, {p["yaw"]}, 0)\nscript = ExtResource("1")\nfootprint_m = Vector2({p["size"][0]}, {p["size"][1]})\nblend_m = {float(p["blend"])}\noutline = "{p["outline"]}"\n'
(ROOT/'scenes/relief_godot.tscn').write_text(base,encoding='utf-8')

# Technical terrain paint mask: earth / industrial soot / compacted stone channels.
N=832;bounds=[182,-13,104,108]
channels=[Image.new('L',(N,N)) for _ in range(3)]
def pixel(p):return ((p[0]-bounds[0])/bounds[2]*N,(p[1]-bounds[1])/bounds[3]*N)
def ellipse(ch,x,z,rx,rz,value=255):
    ImageDraw.Draw(ch).ellipse([pixel((x-rx,z-rz)),pixel((x+rx,z+rz))],fill=value)
for b in buildings:
    x,z=b['xz'];s=b['size_m'];ellipse(channels[0],x,z,s[0]*.65+1.8,s[2]*.65+2)
for x,z,rx,rz in [(261,35,17,18),(262,11,13,14),(232,66,18,9),(215,73,15,12),(226,43,11,10)]:ellipse(channels[0],x,z,rx,rz)
for x,z,rx,rz in [(260,30,12,12),(251,41,8,12),(263,8,10,9),(230,85,6,5)]:ellipse(channels[1],x,z,rx,rz,235)
for x,z,rx,rz in [(226,43,7,8),(234,66,11,5),(262,47,7,6)]:ellipse(channels[2],x,z,rx,rz,210)
for b in props:
    x,z=b['xz'];ellipse(channels[0],x,z,1.8,1.6,230)
mask=Image.merge('RGB',tuple(c.filter(ImageFilter.GaussianBlur(7 if i==0 else 12)) for i,c in enumerate(channels)))
(ROOT/'assets/landscape/ironworks_ground_mask.png').parent.mkdir(exist_ok=True)
mask.save(ROOT/'assets/landscape/ironworks_ground_mask.png')
print('Created',len(buildings),'buildings,',len(props),'props,',len(roads),'paths; mask bounds',bounds)
