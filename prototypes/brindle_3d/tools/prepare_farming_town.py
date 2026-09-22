"""Resolve the editable farming plan and paint terrain wear; no global height bake."""
from pathlib import Path
import json, math, re
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / 'planning/farming-town.json'
layout = json.loads(PLAN.read_text(encoding='utf-8'))
catalog = {a['id']: a for a in json.loads((ROOT/'assets/farming/catalog.json').read_text(encoding='utf-8'))['assets']}

def rotation(yaw):
    a = math.radians(yaw)
    return np.array([[math.cos(a), math.sin(a)], [-math.sin(a), math.cos(a)]])

def terrace(xz):
    return round(30.85 - .018 * (xz[1]-35), 3)

def curve_samples(points, step=.18):
    points=np.asarray(points,dtype=float); samples=[]
    for i in range(len(points)-1):
        a,b=points[i:i+2]
        ha=a+(points[min(i+1,len(points)-1)]-points[max(0,i-1)])/6
        hb=b-(points[min(i+2,len(points)-1)]-points[i])/6
        for t in np.linspace(0,1,max(3,int(np.linalg.norm(b-a)/step)+1),endpoint=False):
            samples.append((1-t)**3*a+3*(1-t)**2*t*ha+3*(1-t)*t*t*hb+t**3*b)
    return np.array(samples+[points[-1]])

def nearest_to_routes(point, routes, target=None, normal=None):
    options=[]
    for route in routes:
        samples=route['_samples'];a,b=samples[:-1],samples[1:];delta=b-a
        t=np.clip(np.sum((point-a)*delta,axis=1)/np.maximum(.001,np.sum(delta*delta,axis=1)),0,1)
        projected=a+delta*t[:,None]
        if target is not None:
            projected=projected[((projected-target)@normal)>.8]
            if not len(projected):continue
        index=np.argmin(np.linalg.norm(projected-point,axis=1));p=projected[index]
        options.append((np.linalg.norm(point-p),p))
    if not options:raise ValueError('No street lies in front of the entrance at '+str(target))
    return min(options,key=lambda a:a[0])[1]

def approach_points(start,target,normal):
    advance=float(np.dot(start-target,normal))
    reach=min(2.6,advance*.75)
    far=target+normal*reach;near=target+normal*min(1.6,reach*.67)
    points=[start.tolist()]
    if np.linalg.norm(start-far)>.2:points.append(far.tolist())
    if np.linalg.norm(np.array(points[-1])-near)>.2:points.append(near.tolist())
    points.append(target.tolist())
    return points

def marker(source,name):
    match=re.search(r'\[node name="'+name+r'"[^\n]*\]\ntransform = Transform3D\(([^)]+)\)',source)
    return np.array([float(x) for x in match[1].split(',')][-3:]) if match else None

foundation_pads = []
layout['paths'] = [r for r in layout['paths'] if not r['id'].startswith('Entree_')]
main_paths = list(layout['paths'])
for route in main_paths:route['_samples']=curve_samples(route['points_xz'])
layout['door_aprons']=[]
for b in layout['buildings']:
    b.update({key: catalog[b['asset']][key] for key in ['scene','size_m','bounds_center_m']})
    if b['id'] != 'MoulinDesPres':
        b['altitude'] = terrace(b['xz'])
        c = np.array(b['xz']) + rotation(b['yaw']) @ np.array(b['bounds_center_m'])[::2]
        foundation_pads.append(dict(id='Assise_'+b['id'],xz=c.tolist(),altitude=b['altitude'],size=[b['size_m'][0]+2,b['size_m'][2]+2],yaw=b['yaw'],blend=3.5,slope=[0,0],outline='Rectangle'))
    source = (ROOT/b['scene'][6:]).read_text(encoding='utf-8')
    door=marker(source,'DoorFace');stair=marker(source,'StairFoot');stair_base=marker(source,'StairBase')
    b['door_approaches'] = []
    if door is not None:
        normal=rotation(b['yaw'])@np.array([0,1])
        is_barn=b['asset'] in ['grange_traversante','grange_a_foin_ouverte']
        contact=(stair_base if stair_base is not None else stair if stair is not None else door)[[0,2]]
        threshold=np.array(b['xz'])+rotation(b['yaw'])@contact
        target=np.array(b['xz'])+rotation(b['yaw'])@stair[[0,2]] if stair is not None else threshold+normal*(0 if is_barn else .42)
        front=target+normal*(2.4 if is_barn else 1.7)
        start=nearest_to_routes(front,main_paths,target,normal)
        # The last segment is square to the facade, including under porches.
        # Connecting a nearby street behind an L-shaped wing would cross walls.
        ps=approach_points(start,target,normal)
        width=3.0 if is_barn else 1.6 if stair is not None or b['id']=='MoulinDesPres' else 1.5 if b['id']=='ReserveGrains' else 1.3
        b.update(threshold_xz=threshold.tolist(),approach_end_xz=target.tolist(),entrance_front_xz=front.tolist(),access_width_m=width)
        b['door_approaches'] = [ps]
        layout['paths'].append(dict(id='Entree_'+b['id'],width_m=width,points_xz=ps,style='door',paint_end_xz=threshold.tolist()))
        side=rotation(b['yaw'])@np.array([1,0]);back=threshold-normal*(.28 if stair is not None else .18)
        apron=[back-side*width*.48,back+side*width*.48,target+normal*1.15+side*width*.70,target+normal*1.15-side*width*.70]
        layout['door_aprons'].append(dict(id=b['id'],points_xz=[v.tolist() for v in apron]))
    for access in b.get('secondary_accesses',[]):
        normal=rotation(b['yaw'])@np.array([0,1]);side=rotation(b['yaw'])@np.array([1,0])
        threshold=np.array(b['xz'])+rotation(b['yaw'])@np.array(access['local_xz'])
        target=threshold+normal*.42;front=target+normal*1.8
        routes=[r for r in main_paths if r['id']==access['route_id']] if 'route_id' in access else main_paths
        start=nearest_to_routes(front,routes,target,normal)
        points=approach_points(start,target,normal)
        access.update(threshold_xz=threshold.tolist(),approach_end_xz=target.tolist(),entrance_front_xz=front.tolist(),points_xz=points)
        layout['paths'].append(dict(id='Entree_'+b['id']+'_'+access['id'],width_m=access['width_m'],style='door',points_xz=points,paint_end_xz=threshold.tolist()))
        back=threshold-normal*.15;width=access['width_m']
        polygon=[back-side*width*.5,back+side*width*.5,target+normal+side*width*.65,target+normal-side*width*.65]
        layout['door_aprons'].append(dict(id=b['id']+'_'+access['id'],points_xz=[v.tolist() for v in polygon]))
for route in main_paths:route.pop('_samples',None)
layout['terrain']['foundation_pads'] = foundation_pads
for road in layout['terrain'].get('graded_paths',[]):
    for i,(a,b) in enumerate(zip(road['profile_xzy'],road['profile_xzy'][1:])):
        dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
        foundation_pads.append(dict(id=road['id']+str(i),xz=[(a[0]+b[0])/2,(a[1]+b[1])/2],altitude=(a[2]+b[2])/2,size=[road['width'],length+2.5],yaw=math.degrees(math.atan2(dx,dz)),blend=road['blend'],slope=[0,(b[2]-a[2])/length],outline='Rectangle'))
layout['terrain']['pads'] = [p for p in layout['terrain']['pads'] if not p['id'].startswith('Champ_')]
foundation_pads.extend(layout['terrain'].get('access_pads',[]))
for f in layout['fields']:
    if 'cultivation_level' not in f:continue
    size_m=catalog[f['asset']]['size_m']
    layout['terrain']['pads'].append(dict(id='Champ_'+f['id'],xz=f['xz'],altitude=f['cultivation_level'],size=[size_m[0]*f['scale'][0]+2,size_m[2]*f['scale'][1]+2],yaw=f['yaw'],blend=13,slope=[0,-.03],outline='Rectangle'))
layout['terrain']['dry_areas'] = [dict(id='CorpsMoulin',xz=[-207.8,34],altitude=30,size=[9.6,9.2],yaw=0,blend=.5)]
for c in layout['terrain']['watercourses']:
    if c['id']=='BiefDuMoulin':
        c['half_width']=.84
        c['smooth']=False
for p in layout['props']+layout['dressing']:
    if p['id']!='VanneIrrigation':p['altitude']=terrace(p['xz'])

layout['orchards']=[]
variants=['pommier_etale','pommier_jeune','pommier_penche','poirier_fuseau','poirier_ancien']
for k, block in enumerate(layout['orchard_blocks']):
    trees=[]
    block['rows'],block['columns']=int(block['rows']),int(block['columns'])
    for row in range(block['rows']):
        for col in range(block['columns']):
            i=row*block['columns']+col
            delta=np.array([col*block['spacing'][0],row*block['spacing'][1]])
            delta+=np.array([math.sin(i*4+k)*.30,math.cos(i*3+k)*.35])
            at=np.array(block['origin_xz'])+rotation(block['yaw'])@delta
            trees.append(dict(asset=variants[(i+k)%5],xz=at.tolist(),yaw=(i*71+k*37)%360,scale=round(.86+.07*(i%4),2)))
    layout['orchards'].append(dict(id=block['id'],trees=trees))
PLAN.write_text(json.dumps(layout,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

# Only this local terrain-use mask changes; other village materials are untouched.
from paint_farming_paths import paint_paths
paint_paths(layout,curve_samples,ROOT)
print('FARM_PLAN_READY',len(layout['buildings']),'buildings',len(layout['paths']),'routes',sum(len(o['trees']) for o in layout['orchards']),'fruit trees')
