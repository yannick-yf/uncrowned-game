"""Verify continuous water, downhill profiles, dry settlement centres and valley banks."""
from pathlib import Path
from collections import deque
import json
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'assets/landscape'
meta=json.loads((DATA/'landscape.json').read_text(encoding='utf-8'))
n=meta['grid_size']; step=meta['extent_m']/(n-1); origin=meta['extent_m']*.5
h=np.fromfile(DATA/'height.f32',dtype='<f4').reshape(n,n)
w=np.fromfile(DATA/'water_level.f32',dtype='<f4').reshape(n,n)
def cell(x,z):return int(np.clip(round((z+origin)/step),0,n-1)),int(np.clip(round((x+origin)/step),0,n-1))
wet=w-h>.02
seen=np.zeros_like(wet); seed=cell(120,-140);seen[seed]=True;q=deque([seed])
while q:
    z,x=q.popleft()
    for dz,dx in [(0,1),(0,-1),(1,0),(-1,0)]:
        zz,xx=z+dz,x+dx
        if 0<=zz<n and 0<=xx<n and wet[zz,xx] and not seen[zz,xx]:seen[zz,xx]=True;q.append((zz,xx))
failures=[]
profile_count=0
for course in meta['water_profiles']:
    points=np.asarray(course['profile_xzy'])
    assert np.diff(points[:,2]).max()<=.001,course['id']+' climbs upstream'
    for x,z,y in points:
        profile_count+=1
        if not seen[cell(x,z)]:failures.append(f'{course["id"]}: disconnected water at {x:.2f},{z:.2f}')
assert seen[cell(-365,300)],'Lake must connect to the sea'
for site in meta['sites']:
    x,y,z=site['center_xyz'];assert h[cell(x,z)]>w[cell(x,z)]+1,site['id']+' flooded'
for name,channels in [('height',1),('water_level',1),('terrain_paint',3),('water_flow',3)]:
    values=np.fromfile(DATA/(name+'.f32'),dtype='<f4')
    assert values.size==n*n*channels and np.isfinite(values).all(),name+' invalid source data'
assert h[cell(120,-140)]<35 and w[cell(120,-140)]==40,'Lake basin and height preserved'
# Banks in the inhabited lowlands should not jump up a cliff immediately beside the water.
bank_rises=[]
for course in meta['water_profiles']:
    points=np.asarray(course['profile_xzy'])
    for i in range(2,len(points)-2,4):
        p=points[i]
        if p[2]>45 or p[2]<15:continue
        direction=points[i+1,:2]-points[i-1,:2];direction/=np.linalg.norm(direction)
        normal=np.array([direction[1],-direction[0]])
        for sign in [-1,1]:
            sample=p[:2]+normal*16*sign
            bank_rises.append(float(h[cell(*sample)]-p[2]))
report={'profiles_checked':profile_count,'connected_wet_cells':int(seen.sum()),'disconnected_center_samples':len(failures),
        'lowland_bank_rise_at_16m_median_m':round(float(np.median(bank_rises)),3),
        'lowland_bank_rise_at_16m_95percent_m':round(float(np.percentile(bank_rises,95)),3),'crossings':len(meta['crossings'])}
print(json.dumps(report,indent=2))
if failures:raise AssertionError('\n'.join(failures[:30]))
assert np.percentile(bank_rises,95)<7.0,'Lowland banks still form high walls'
print('RIVER_DATA PASS')
