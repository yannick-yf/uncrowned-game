"""Bake farming-only traffic data: soil coverage, wheel wear and compacted yards."""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops


def paint_paths(layout, curve_samples, root):
    bounds=layout['bounds_xz'];size=1024
    mask=Image.new('L',(size,size));ruts=Image.new('L',(size,size));yards=Image.new('L',(size,size))

    def pixel(p):
        return ((p[0]-bounds[0])/bounds[2]*size,(p[1]-bounds[1])/bounds[3]*size)

    def overlay(image,polygon,value):
        layer=Image.new('L',(size,size))
        ImageDraw.Draw(layer).polygon([pixel(v) for v in polygon],fill=value)
        return ImageChops.lighter(image,layer)

    for index,route in enumerate(layout['paths']):
        samples=curve_samples(route['points_xz'])
        tangent=np.gradient(samples,axis=0)
        tangent/=np.maximum(.0001,np.linalg.norm(tangent,axis=1))[:,None]
        normal=np.column_stack((-tangent[:,1],tangent[:,0]))
        distance=np.concatenate(([0],np.cumsum(np.linalg.norm(np.diff(samples,axis=0),axis=1))))
        variation=1+.055*np.sin(distance*.75+index)+.035*np.sin(distance*2.1-index*.6)
        half=route['width_m']*.5*variation
        style=route.get('style','lane')
        polygon=np.vstack((samples+normal*half[:,None],(samples-normal*half[:,None])[::-1]))
        mask=overlay(mask,polygon,145 if style=='field_track' else 219 if style=='cart_lane' else 232)
        if style in ['cart_lane','field_track']:
            for side in [-1,1]:
                centers=samples+normal*(side*min(.70,route['width_m']*.24))
                width=.19 if style=='field_track' else .16
                ribbon=np.vstack((centers+normal*width,(centers-normal*width)[::-1]))
                mask=overlay(mask,ribbon,248)
                ruts=overlay(ruts,ribbon,200 if style=='field_track' else 135)
        if 'paint_end_xz' in route:
            end=np.array(route['paint_end_xz']);start=samples[-1];direction=end-start
            if np.linalg.norm(direction)>.001:
                side=np.array([-direction[1],direction[0]])/np.linalg.norm(direction)*route['width_m']*.46
                mask=overlay(mask,[start-side,start+side,end+side,end-side],245)

    for area in layout.get('ground_areas',[]):
        mask=overlay(mask,area['points_xz'],int(area.get('wear',238)))
        yards=overlay(yards,area['points_xz'],220)
    for area in layout['door_aprons']:
        mask=overlay(mask,area['points_xz'],246)
        yards=overlay(yards,area['points_xz'],245)
    for building in layout['buildings']:
        if building['asset'] not in ['grange_traversante','grange_a_foin_ouverte']:continue
        # Dirt continues through open barns, without enclosing every house in a
        # rectangular brown footprint that would erase its adjoining garden.
        angle=np.deg2rad(building['yaw'])
        rotation=np.array([[np.cos(angle),np.sin(angle)],[-np.sin(angle),np.cos(angle)]])
        depth=10.8 if building['asset']=='grange_traversante' else 6.6
        polygon=[np.array(building['xz'])+rotation@np.array([x,z]) for x,z in [(-1.65,-depth*.5),(1.65,-depth*.5),(1.65,depth*.5),(-1.65,depth*.5)]]
        mask=overlay(mask,polygon,239);yards=overlay(yards,polygon,220)

    wear=np.array(mask.filter(ImageFilter.GaussianBlur(1.15)),dtype=float)/255
    packed=np.array(yards.filter(ImageFilter.GaussianBlur(1.6)),dtype=float)/255
    wx,wz=np.meshgrid(np.linspace(bounds[0],bounds[0]+bounds[2],size),np.linspace(bounds[1],bounds[1]+bounds[3],size))
    grain=(np.sin(wx*2.7+np.sin(wz*1.1))+np.sin(wz*4.1-wx*.7))*.5
    # Break up the verge without punching holes across the walking tread.
    wear=np.clip(wear-grain*.14*(1-wear)*np.minimum(1,wear*6),0,1)
    tracks=np.array(ruts.filter(ImageFilter.GaussianBlur(.85)),dtype=float)*(1-packed)
    combined=np.stack((wear*255,tracks,packed*255),axis=2).astype(np.uint8)
    (root/'assets/farming_village').mkdir(exist_ok=True)
    Image.fromarray(combined).save(root/'assets/farming_village/ground_wear.png')
