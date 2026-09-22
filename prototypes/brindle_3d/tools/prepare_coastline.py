"""Build a sparse coast overlay; original regional terrain and water stay untouched."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/coastline'
PLAN = ROOT / 'planning/coastline.json'


def smooth(a, b, v):
    t = np.clip((v-a)/(b-a), 0, 1)
    return t*t*(3-2*t)


def project(points, x, z):
    best = np.full_like(x, np.inf, dtype=float)
    along = np.zeros_like(x, dtype=float)
    nx = np.zeros_like(x, dtype=float)
    nz = np.zeros_like(x, dtype=float)
    height = np.zeros_like(x, dtype=float)
    elapsed = 0.
    for a, b in zip(points[:-1], points[1:]):
        delta = b[:2]-a[:2]
        length = float(np.linalg.norm(delta))
        if length < .001:
            continue
        t = np.clip(((x-a[0])*delta[0]+(z-a[1])*delta[1])/(length*length), 0, 1)
        px, pz = a[0]+t*delta[0], a[1]+t*delta[1]
        d = (x-px)**2+(z-pz)**2
        take = d < best
        best = np.where(take, d, best)
        along = np.where(take, elapsed+t*length, along)
        nx, nz = np.where(take, px, nx), np.where(take, pz, nz)
        if points.shape[1] > 2:
            height = np.where(take, a[2]+t*(b[2]-a[2]), height)
        elapsed += length
    return np.sqrt(best), along, nx, nz, height


def build():
    plan = json.loads(PLAN.read_text(encoding='utf-8'))
    meta = json.loads((ROOT/'assets/landscape/landscape.json').read_text())
    n, extent = meta['grid_size'], meta['extent_m']
    axis = np.linspace(-extent/2, extent/2, n)
    x, z = np.meshgrid(axis, axis)
    original = np.fromfile(ROOT/'assets/landscape/height.f32', '<f4').reshape(n, n)
    water = np.fromfile(ROOT/'assets/landscape/water_level.f32', '<f4').reshape(n, n)
    points = np.array(meta['coastline_xz'], dtype=float)
    distance, along, px, pz, _ = project(points, x, z)
    # This polygon is only used to classify land. Its closing edges are NOT coast.
    polygon = np.vstack([points, [extent/2, -extent/2]])
    inside = np.zeros_like(x, dtype=bool)
    for a, b in zip(polygon, np.roll(polygon, -1, axis=0)):
        if abs(b[1]-a[1]) < 1e-8:
            continue
        inside ^= ((a[1]>z)!=(b[1]>z)) & (x < (b[0]-a[0])*(z-a[1])/(b[1]-a[1])+a[0])
    signed = np.where(inside, distance, -distance)
    cove = np.zeros_like(x)
    inset = np.zeros_like(x)
    sand = np.zeros_like(x)
    for item in plan['coves']:
        q = np.array(item['near_xz'])
        _, center, *_ = project(points, np.array(q[0]), np.array(q[1]))
        weight = 1-smooth(item['radius_m']*.32, item['radius_m'], np.abs(along-center))
        take = weight > cove
        cove = np.maximum(cove, weight)
        inset = np.where(take, weight*item['inset_m'], inset)
        sand = np.where(take, weight*item['sand'], sand)
        item['along_m'] = round(float(center), 3)
    priority = np.exp(-.5*((px-plan['priority_center_xz'][0])/plan['priority_radius_m'])**2)
    priority *= smooth(230, 305, pz)
    base = 23 + 8*np.sin(along*.017+.4)**2 + 5*np.sin(along*.047)**2
    north = (1-smooth(-335, -255, pz))*34
    east = smooth(295, 380, px)*17
    crest = base + north + east
    rng = np.random.default_rng(plan['seed'])
    knots = np.arange(0, float(along.max())+30, 18.)
    fractures = np.interp(along, knots, rng.uniform(-1., 1., len(knots)))
    high_knots = np.arange(0, float(along.max())+55, 43.)
    peaks = np.interp(along, high_knots, rng.uniform(-1., 1., len(high_knots)))
    crest = crest*(1-priority) + (plan['priority_cliff_height_m']+7*peaks+3*np.sin(along*.071))*priority
    # Angular, broken headlands rather than a uniform scalloped wall.
    jagged = (7.5*fractures+1.4*np.sin(along*.39))*(1-cove)
    d = signed + jagged - inset
    foot = np.where(d < 0, d*.45, np.minimum(d*.28, 1.25))
    # Offset the fractured benches independently along the headland: vertical
    # seams and broken shelves must not become identical ribs from sea to crest.
    lower = 1.6*np.sin(along*.13+.5)
    middle = 2.1*np.sin(along*.087+2.4)
    upper = 1.8*fractures
    strata = .24*smooth(.8+lower,3.2+lower,d) + .32*smooth(5.0+middle,7.4+middle,d) + .44*smooth(10.0+upper,12.6+upper,d)
    face = smooth(1.0,13.0,d)*.16+strata*.84
    cliff = foot*(1-face)+crest*face
    beach = np.where(d < 0, d*.26, d*.15+.009*np.maximum(0, d-14)**2)
    target = cliff*(1-cove)+beach*cove
    weight = (1-smooth(*plan['landward_blend_m'], signed))*smooth(*plan['seaward_blend_m'], signed)
    estuary = plan['protected_estuary']
    estuary_distance, *_ = project(np.array(estuary['points_xz']), x, z)
    protection = smooth(estuary['clear_half_width_m'], estuary['clear_half_width_m']+estuary['blend_m'], estuary_distance)
    weight *= protection
    # Inland water, not W==0 (also common on dry land), has veto power.
    weight = np.where((water>.02) & (original<water+1.5), 0., weight)
    for anchor in plan['protected_anchors']:
        dist = np.hypot(x-anchor['xz'][0], z-anchor['xz'][1])
        weight *= smooth(anchor['radius_m'], anchor['radius_m']+anchor['blend_m'], dist)
    for route in plan.get('protected_paths', []):
        dist, *_ = project(np.array(route['points_xz'], dtype=float), x, z)
        weight *= smooth(route['clear_half_width_m'], route['clear_half_width_m']+route['blend_m'], dist)
    # Sparse affine edits can be applied after existing Godot terraces without
    # replacing their independent buffers. Trails use the same continuous grid.
    combined_target = target.copy()
    combined_weight = weight.copy()
    paths = np.zeros_like(x)
    trail_strength = np.zeros_like(x)
    trail_numerator = np.zeros_like(x)
    trail_denominator = np.zeros_like(x)
    for trail in plan.get('approach_grading', [])+plan['trails']:
        dist, _, _, _, y = project(np.array(trail['profile_xzy'], dtype=float), x, z)
        # A capsule can straddle a grid diagonal: seat the walking shoulders as
        # well as the painted strip, rather than leaving a ridge one vertex away.
        flat = max(3.3, trail['width_m']*.5)
        influence = 1-smooth(flat, flat+trail['blend_m'], dist)
        # Junctions share a graded surface. Sequential stamps would create a
        # step wherever the shoulder of one branch overwrites another branch.
        proximity = influence*np.exp(-dist*dist/8.)
        trail_numerator += y*proximity
        trail_denominator += proximity
        trail_strength = np.maximum(trail_strength, influence)
        paths = np.maximum(paths, 1-smooth(trail['width_m']*.38, trail['width_m']*.62, dist))
    trail_height = np.divide(trail_numerator, trail_denominator, out=np.zeros_like(x), where=trail_denominator>1e-12)
    total = combined_weight*(1-trail_strength)+trail_strength
    numerator = combined_target*combined_weight*(1-trail_strength)+trail_height*trail_strength
    combined_target = np.divide(numerator, total, out=combined_target.copy(), where=total>1e-7)
    combined_weight = total
    # Buildings retain their original foundations even beside path shoulders.
    for anchor in plan['protected_anchors']:
        if anchor.get('kind') == 'graded_junction':
            continue
        dist = np.hypot(x-anchor['xz'][0], z-anchor['xz'][1])
        combined_weight *= smooth(anchor['radius_m'], anchor['radius_m']+anchor['blend_m'], dist)
    ids = np.flatnonzero(combined_weight.ravel() > .00001)
    records = np.column_stack((ids, combined_target.ravel()[ids], combined_weight.ravel()[ids])).astype('<f4')
    OUT.mkdir(parents=True, exist_ok=True)
    records.tofile(OUT/'terrain_edits.f32')
    control = np.stack([np.clip(weight*1.1,0,1), sand, paths], axis=-1)
    image = Image.fromarray(np.uint8(np.clip(control,0,1)*255))
    image.resize((1024,1024),Image.Resampling.BILINEAR).save(OUT/'coastal_control.png')
    new_height = original*(1-combined_weight)+combined_target*combined_weight
    plan['source_grid_size'] = n
    plan['coast_length_m'] = round(float(np.linalg.norm(np.diff(points,axis=0),axis=1).sum()),3)
    plan['terrain_edit_count'] = len(ids)
    plan['terrain_edit_bytes'] = int(records.nbytes)
    plan['new_height_range_m'] = [round(float(new_height.min()),3), round(float(new_height.max()),3)]
    PLAN.write_text(json.dumps(plan,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'COAST_PLAN_READY edits={len(ids)} bytes={records.nbytes} length={plan["coast_length_m"]}m')


if __name__ == '__main__':
    build()
