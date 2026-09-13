"""Rebuild the terrain source data. Runtime needs Godot only; this tool needs NumPy."""
from pathlib import Path
import json
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SPEC = json.loads((ROOT / 'planning/geographie-v1.json').read_text(encoding='utf-8-sig'))
OUT = ROOT / 'assets/landscape'
OUT.mkdir(parents=True, exist_ok=True)
N, EXTENT = 385, 768.0
axis = np.linspace(-EXTENT / 2, EXTENT / 2, N)
X, Z = np.meshgrid(axis, axis)


def smooth(a, b, value):
    t = np.clip((value-a)/(b-a), 0, 1)
    return t*t*(3-2*t)


def noise(x, z, scale, seed=0):
    x, z = x/scale, z/scale
    ix, iz = np.floor(x), np.floor(z)
    fx, fz = x-ix, z-iz
    fx, fz = fx*fx*(3-2*fx), fz*fz*(3-2*fz)
    def h(a,b):
        v = np.sin(a*127.1+b*311.7+seed*47.71)*43758.5453
        return v-np.floor(v)
    return (h(ix,iz)*(1-fx)+h(ix+1,iz)*fx)*(1-fz)+(h(ix,iz+1)*(1-fx)+h(ix+1,iz+1)*fx)*fz


def gaussian(cx, cz, sx, sz):
    return np.exp(-0.5*(((X-cx)/sx)**2+((Z-cz)/sz)**2))


def curve(nodes, spacing=5):
    """Smooth plan bends while keeping the prescribed water level monotonic."""
    nodes = np.asarray(nodes, dtype=float)
    result = []
    for i in range(len(nodes)-1):
        p0, p1 = nodes[max(0,i-1),:2], nodes[i,:2]
        p2, p3 = nodes[i+1,:2], nodes[min(len(nodes)-1,i+2),:2]
        count = max(2, int(np.ceil(np.linalg.norm(p2-p1)/spacing)))
        for t in np.linspace(0,1,count,endpoint=False):
            p = .5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)
            h = nodes[i,2]*(1-t)+nodes[i+1,2]*t
            result.append([p[0],p[1],h])
    result.append(nodes[-1].tolist())
    return np.asarray(result)


def nearest(points):
    best = np.full_like(X, np.inf)
    level = np.zeros_like(X)
    along = np.zeros_like(X)
    flow_x, flow_z = np.zeros_like(X), np.zeros_like(X)
    lengths = np.linalg.norm(np.diff(points[:,:2],axis=0),axis=1)
    total, elapsed = lengths.sum(), 0.0
    for i, length in enumerate(lengths):
        if length < .0001:
            continue
        a,b = points[i],points[i+1]
        dx,dz = b[0]-a[0],b[1]-a[1]
        t = np.clip(((X-a[0])*dx+(Z-a[1])*dz)/(length*length),0,1)
        dist2 = (X-a[0]-t*dx)**2+(Z-a[1]-t*dz)**2
        take = dist2<best
        best = np.where(take,dist2,best)
        level = np.where(take,a[2]+t*(b[2]-a[2]),level)
        along = np.where(take,(elapsed+t*length)/total,along)
        flow_x = np.where(take,dx/length,flow_x)
        flow_z = np.where(take,dz/length,flow_z)
        elapsed += length
    return np.sqrt(best),level,along,flow_x,flow_z


# Coast stays on the west and south; the northern/eastern ranges reach the map edges.
coast = [[-334,-384,0],[-326,-150,0],[-345,50,0],[-315,210,0],[-235,300,0],[-100,350,0],[25,320,0],[180,345,0],[300,325,0],[384,305,0]]
coast_points = curve(coast,spacing=8)
distance, *_ = nearest(coast_points)
polygon = np.vstack([coast_points[:,:2], [384,-384]])
inside = np.zeros_like(X,dtype=bool)
for a,b in zip(polygon,np.roll(polygon,-1,axis=0)):
    if abs(b[1]-a[1]) < 1e-9:
        continue
    cross = ((a[1]>Z)!=(b[1]>Z)) & (X < (b[0]-a[0])*(Z-a[1])/(b[1]-a[1])+a[0])
    inside ^= cross
signed_coast = np.where(inside,distance,-distance)

low_noise = noise(X,Z,110,21)
detail = noise(X,Z,25,47)*.65 + noise(X,Z,9,82)*.35
H = 23 + (384-Z)*.038 + (X+120)*.012 + (low_noise-.5)*12 + (detail-.5)*2.0
H += 9*gaussian(-25,-25,95,85) + 8*gaussian(110,185,80,45)
north = np.exp(-.5*((Z+351)/43)**2) * (75+35*noise(X,Z,62,51))
east = np.exp(-.5*((X-356)/37)**2) * (80+35*noise(X,Z,55,68))
H += np.maximum(north,east) + np.minimum(north,east)*.2
for cx,cz,amp,sx,sz in [(-255,-347,65,29,27),(-23,-357,76,36,24),(245,-337,69,33,33),(357,-165,82,25,38),(354,139,71,27,42)]:
    H += amp*gaussian(cx,cz,sx,sz)
mountains = smooth(65,125,H)
H += mountains*((noise(X,Z,14,12)-.5)*7 + (noise(X,Z,6,14)-.5)*2)

# Rounded building terraces; river valleys are carved afterwards and always take precedence.
targets = {'ville_chateau':62,'village_fermier':30,'village_scierie':54,'village_acierie':43,'brindle':25}
for site in SPEC['sites']:
    cx,cz=site['center_xz']; w,d=site['footprint_xz']
    radius = (((X-cx)/(w*.57))**4+((Z-cz)/(d*.57))**4)**.25
    weight = 1-smooth(.66,1.4,radius)
    target = targets[site['id']] + (noise(X,Z,45,31)-.5)*.7
    if site['id']=='ville_chateau':
        target += np.clip((-180-Z)*.07,-5,7)
    H = H*(1-weight)+target*weight
castle = gaussian(-160,-233,35,25)
H += castle*10

# Beach and shallow seabed. The basin reaches sea level at the coastline.
H = np.where(inside,H*smooth(0,48,signed_coast),-np.minimum(24,-signed_coast*.5))

lake = SPEC['lake']; lx,lz=lake['center_xz']; rx,rz=np.array(lake['extent_xz'])/2
angle = np.arctan2((Z-lz)/rz,(X-lx)/rx)
shore_irregularity = 1.2*np.sin(angle*5+.6)+.7*np.sin(angle*9-1.4)
lake_distance = (np.sqrt(((X-lx)/rx)**2+((Z-lz)/rz)**2)-1)*rz+shore_irregularity
lake_y = float(lake['proposed_water_height_m'])
lake_bed = lake_y-7*smooth(0,15,-lake_distance)
lake_bank = lake_y+np.maximum(lake_distance,0)*.20
lake_target = np.where(lake_distance<0,lake_bed,lake_bank)
lake_weight = 1-smooth(8,38,lake_distance)
H = H*(1-lake_weight)+lake_target*lake_weight

W = np.zeros_like(H)
W = np.where(lake_distance<10,lake_y,W)
flowx = np.full_like(H,-.3); flowz = np.full_like(H,.4); speed=np.full_like(H,.17)
speed = np.where(lake_distance<10,.07,speed)
river_bed = np.full_like(H,np.inf)
river_water_sum = np.zeros_like(H)
river_water_weight = np.zeros_like(H)
river_influence = np.zeros_like(H)
river_target = np.zeros_like(H)
river_min_distance = np.full_like(H,np.inf)
water_nearest = np.full_like(H,np.inf)
runtime_profiles=[]
for course in SPEC['watercourses']:
    nodes = [list(p) for p in course['profile_xzy']]
    # Short, level aprons make tributaries meet the lake exactly at its constant level.
    if course['id']=='source_nord_est': nodes.insert(-1,[177,-185,40])
    if course['id']=='affluent_ville': nodes.insert(-1,[44,-161,40])
    if course['id']=='riviere_principale': nodes=[[105,-110,40],[100,-92,40]]+nodes[1:]
    points=curve(nodes)
    dist,water,t,fx,fz=nearest(points)
    is_main=course['id']=='riviere_principale'
    half=(5.5+t*3.5) if is_main else (3.2+t*1.4)
    depth=3.2 if is_main else 2.0
    edge=dist-half
    bed=water-depth*np.maximum(0,1-(dist/half)**2)**.7
    outside=water+np.maximum(edge,0)*.42
    target=np.where(edge<0,bed,outside)
    influence=1-smooth(3,24 if is_main else 20,edge)
    take=influence>river_influence
    river_target=np.where(take,target,river_target)
    river_influence=np.maximum(river_influence,influence)
    river_bed=np.minimum(river_bed,np.where(edge<0,bed,np.inf))
    water_weight=1-smooth(0,8,edge)
    river_water_sum += water*water_weight
    river_water_weight += water_weight
    take_flow=(edge<8)&(dist/half<water_nearest)
    flowx=np.where(take_flow,fx,flowx);flowz=np.where(take_flow,fz,flowz)
    speed=np.where(take_flow,.8 if is_main else .65,speed)
    water_nearest=np.where(take_flow,dist/half,water_nearest)
    river_min_distance=np.minimum(river_min_distance,np.abs(edge))
    runtime_profiles.append({'id':course['id'],'profile_xzy':np.round(points,3).tolist()})

H = H*(1-river_influence)+river_target*river_influence
H = np.minimum(H,river_bed)
river_water=river_water_sum/np.maximum(river_water_weight,1e-8)
W = np.where(river_water_weight>1e-8,river_water,W)
# The lake wins at its overlap with tributaries; land beneath it remains a single basin.
H = np.where(lake_distance<0,np.minimum(H,lake_bed),H)
lake_blend=1-smooth(-1,8,lake_distance)
W = W*(1-lake_blend)+lake_y*lake_blend
flowx=np.where(lake_distance<0,-.25,flowx);flowz=np.where(lake_distance<0,.45,flowz)
speed=np.where(lake_distance<0,.07,speed)
W *= smooth(-5,10,signed_coast)
H = np.where(np.isfinite(river_bed),np.minimum(H,W-.35),H)
H = np.where(signed_coast < -5,np.minimum(H,-.5),H)

# Paint data is shared by terrain vertices. Existing Brindle palette is applied in Godot.
gz,gx=np.gradient(H,EXTENT/(N-1))
slope=np.sqrt(gx*gx+gz*gz)
rock=np.maximum(smooth(.45,1.05,slope),smooth(92,155,H)*.88)
sand=(1-smooth(2,7,H))*smooth(-.5,1,H)*(1-rock)
bank=(1-smooth(1,5,river_min_distance))*smooth(.1,1.8,H-W)*(1-rock)
bank=np.maximum(bank,(1-smooth(0,5,np.abs(lake_distance)))*smooth(0,1,H-W)*.6)
paint=np.stack([rock,sand,bank],axis=-1).astype('<f4')
flows=np.stack([flowx,flowz,speed],axis=-1).astype('<f4')

for name,data in [('height',H),('water_level',W),('terrain_paint',paint),('water_flow',flows)]:
    np.asarray(data,dtype='<f4').tofile(OUT/(name+'.f32'))

def sample(grid,x,z):
    ix=np.clip((x+EXTENT/2)/(EXTENT/(N-1)),0,N-1)
    iz=np.clip((z+EXTENT/2)/(EXTENT/(N-1)),0,N-1)
    x0,z0=int(ix),int(iz);x1,z1=min(x0+1,N-1),min(z0+1,N-1)
    tx,tz=ix-x0,iz-z0
    return float((grid[z0,x0]*(1-tx)+grid[z0,x1]*tx)*(1-tz)+(grid[z1,x0]*(1-tx)+grid[z1,x1]*tx)*tz)

site_samples=[]
for site in SPEC['sites']:
    x,z=site['center_xz'];site_samples.append({'id':site['id'],'center_xyz':[x,round(sample(H,x,z),3),z]})
meta={'grid_size':N,'extent_m':EXTENT,'height_min_m':round(float(H.min()),3),'height_max_m':round(float(H.max()),3),
      'sea_level_m':0,'lake_level_m':lake_y,'sites':site_samples,'water_profiles':runtime_profiles,
      'coastline_xz':np.round(coast_points[:,:2],3).tolist(),
      'data_layout':'Little-endian float32, row-major Z then X; paint/flow interleaved 3 channels.'}
(OUT/'landscape.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf8')

assert np.isfinite(H).all() and np.isfinite(W).all()
assert all(np.diff(np.array(p['profile_xzy'])[:,2]).max()<=.001 for p in runtime_profiles)
assert abs(sample(W,120,-140)-40)<.001 and sample(H,120,-140)<35
report={'grid':N,'height_min':meta['height_min_m'],'height_max':meta['height_max_m'],'lake_y':lake_y,
        'water_samples':int((W-H>.02).sum()),'sites':site_samples}
print(json.dumps(report,ensure_ascii=False,indent=2))
