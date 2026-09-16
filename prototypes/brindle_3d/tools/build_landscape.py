"""Rebuild the terrain source data. Runtime needs Godot only; this tool needs NumPy."""
from pathlib import Path
import json
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RIVER_SPEC = json.loads((ROOT / 'planning/river-layout-v2.json').read_text(encoding='utf-8'))
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
    cx,cz=site.get('terrain_center_xz',site['center_xz']); w,d=site['footprint_xz']
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

# Water surfaces follow the neighbouring land; floodplains merge over tens of metres.
# Preserve the original sea floor rather than raising a tube of land into the ocean.
coastal_base = H.copy()
lake = SPEC['lake']; lx,lz=lake['center_xz']; rx,rz=np.array(lake['extent_xz'])/2
angle = np.arctan2((Z-lz)/rz,(X-lx)/rx)
shore_irregularity = 2.6*np.sin(angle*5+.6)+1.4*np.sin(angle*9-1.4)
lake_distance = (np.sqrt(((X-lx)/rx)**2+((Z-lz)/rz)**2)-1)*rz+shore_irregularity
lake_y = float(lake['proposed_water_height_m'])
lake_bed = lake_y-6.0*smooth(0,22,-lake_distance)
lake_bank = lake_y+.12*np.maximum(lake_distance,0)+.0014*np.maximum(lake_distance,0)**2
lake_target = np.where(lake_distance<0,lake_bed,lake_bank)
lake_weight = 1-smooth(4,72,lake_distance)
H = H*(1-lake_weight)+np.minimum(H,lake_target)*lake_weight
H = np.where(lake_distance<3,lake_target,H)

W=np.zeros_like(H)
flowx=np.full_like(H,-.3);flowz=np.full_like(H,.4);speed=np.full_like(H,.17)
river_bed=np.full_like(H,np.inf)
river_min_distance=np.full_like(H,np.inf)
water_nearest=np.full_like(H,np.inf)
runtime_profiles=[]
crossings=[]

def project_to_curve(points,at):
    a=points[:-1,:2]; delta=np.diff(points[:,:2],axis=0)
    u=np.clip(((np.asarray(at)-a)*delta).sum(axis=1)/(delta*delta).sum(axis=1),0,1)
    closest=a+u[:,None]*delta
    i=int(np.argmin(((closest-at)**2).sum(axis=1)))
    flow=delta[i]/np.linalg.norm(delta[i])
    level=float(points[i,2]+u[i]*(points[i+1,2]-points[i,2]))
    return closest[i],flow,level

for course in RIVER_SPEC['courses']:
    points=curve(course['profile_xzy'],spacing=3)
    dist,water,t,fx,fz=nearest(points)
    is_main=course['id']=='riviere_principale'
    half=np.interp(t,[0,1],course['half_width_m'])*(1+.11*np.sin(t*np.pi*7+.5))
    course_crossings=[]
    for planned in RIVER_SPEC['crossings']:
        if planned['course']!=course['id']:continue
        center,flow,level=project_to_curve(points,planned['anchor_xz'])
        across=np.array([flow[1],-flow[0]])
        # +Z points across the current. Exact geometry dimensions come from the local kit.
        yaw=float(np.arctan2(across[0],across[1]))
        record=dict(planned,center_xyz=[float(center[0]),level+planned['freeboard_m'],float(center[1])],
                    yaw_radians=yaw,water_y=level,direction_xz=across.tolist())
        for name,sign in [('entry_xyz',-1),('exit_xyz',1)]:
            point=center+sign*across*planned['length_m']*.5
            record[name]=[float(point[0]),record['center_xyz'][1],float(point[1])]
        crossings.append(record);course_crossings.append(record)
        near=np.hypot(X-center[0],Z-center[1])
        pinch=1-smooth(planned['length_m']*.6,planned['length_m']*.6+24,near)
        half=half*(1-pinch)+planned['water_width_m']*.5*pinch
    edge=dist-half
    depth=course['depth_m']*(.88+.12*np.sin(t*13+.8)**2)
    bed=water-depth*np.maximum(0,1-(dist/half)**2)**.85
    bank_distance=np.maximum(edge,0)
    # Low shelves at the water, then a gradual climb into the undisturbed hillside.
    target_bank=water+.16*bank_distance+.0018*bank_distance**2
    target=np.where(edge<0,bed,target_bank)
    reach=course['valley_blend_m'] if course['id']=='bras_scierie' or course['id'].startswith('royal_') else np.clip(course['valley_blend_m']+np.maximum(0,H-water-7)*1.5,45,140)
    influence=1-smooth(5,reach,edge)
    H=H*(1-influence)+np.minimum(H,target)*influence
    # Fit the wet channel itself, with a two-metre shoreline shelf at its boundary.
    shore_fit=1-smooth(1,5,edge)
    H=H*(1-shore_fit)+target*shore_fit
    if course['id'].startswith('royal_'):
        # These defensive channels include a constructed earth bank. Their constant
        # water level must never extend as a suspended sheet over lower outer ground.
        bank_weight=(1-smooth(7,16,edge))*smooth(-.1,1.0,edge)
        bank_top=water+.9+.05*np.maximum(edge,0)
        H=H*(1-bank_weight)+np.maximum(H,bank_top)*bank_weight
    river_bed=np.minimum(river_bed,np.where(edge<0,bed,np.inf))
    choose=(edge<6)&(dist/half<water_nearest)
    W=np.where(choose,water,W)
    flowx=np.where(choose,fx,flowx);flowz=np.where(choose,fz,flowz)
    speed=np.where(choose,.56 if is_main else .66,speed)
    water_nearest=np.where(choose,dist/half,water_nearest)
    river_min_distance=np.minimum(river_min_distance,np.abs(edge))
    runtime_profiles.append({'id':course['id'],'profile_xzy':np.round(points,3).tolist(),
                             'half_width_m':course['half_width_m'],'depth_m':course['depth_m']})

H=np.minimum(H,river_bed)
H=np.where(lake_distance<0,np.minimum(H,lake_bed),H)
# Tributaries terminate on a level apron inside the lake, keeping junctions seamless.
lake_blend=1-smooth(-1,5,lake_distance)
W=W*(1-lake_blend)+lake_y*lake_blend
flowx=np.where(lake_distance<0,-.25,flowx);flowz=np.where(lake_distance<0,.45,flowz)
speed=np.where(lake_distance<0,.07,speed)
W*=smooth(-5,5,signed_coast)
H=np.where(signed_coast<0,np.minimum(H,coastal_base),H)
H=np.where(signed_coast<-5,np.minimum(H,-.5),H)

# Earth approaches meet the ends of the selected bridges, without blocking the water.
for crossing in crossings:
    center=np.array(crossing['center_xyz'])[::2]
    direction=np.array(crossing['direction_xz'])
    lateral=(X-center[0])*direction[1]-(Z-center[1])*direction[0]
    along=(X-center[0])*direction[0]+(Z-center[1])*direction[1]
    end_distance=np.abs(along)-crossing['length_m']*.5
    blend=(1-smooth(crossing['clear_width_m']*.5+1,crossing['clear_width_m']*.5+7,np.abs(lateral)))
    blend*=1-smooth(1,22,end_distance)
    blend*=smooth(-.75,.0,end_distance)
    # A half-metre of buried overlap eliminates the seam at a saved collision slab.
    overlap=(end_distance>-.55)&(end_distance<.8)&(np.abs(lateral)<crossing['clear_width_m']*.5+.45)
    blend=np.maximum(blend,overlap.astype(float))
    H=H*(1-blend)+crossing['center_xyz'][1]*blend

# The original Brindle building terraces are applied in Godot after loading this data.


# The sawmill's elevated supply and low tailrace have different hydraulic levels.
if any(c['id']=='bras_scierie' for c in RIVER_SPEC['courses']):
    from sawmill_hydrology import apply as apply_sawmill_water
    apply_sawmill_water(H,W,flowx,flowz,speed,X,Z)

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
      'river_revision':2, 'crossings':crossings,
      'coastline_xz':np.round(coast_points[:,:2],3).tolist(),
      'data_layout':'Little-endian float32, row-major Z then X; paint/flow interleaved 3 channels.'}
(OUT/'landscape.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf8')

assert np.isfinite(H).all() and np.isfinite(W).all()
assert all(np.diff(np.array(p['profile_xzy'])[:,2]).max()<=.001 for p in runtime_profiles)
assert abs(sample(W,120,-140)-40)<.001 and sample(H,120,-140)<35
report={'grid':N,'height_min':meta['height_min_m'],'height_max':meta['height_max_m'],'lake_y':lake_y,
        'water_samples':int((W-H>.02).sum()),'sites':site_samples,'crossings':crossings}
print(json.dumps(report,ensure_ascii=False,indent=2))
