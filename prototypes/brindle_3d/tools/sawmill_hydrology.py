"""Local headrace/tailrace detail; the upstream branch itself lives in river-layout-v2.json."""
import numpy as np

TAILRACE = [[254.65,-147.65,44.22],[254.65,-143,44.17],[258,-137,44.04],[259,-129,43.73]]

def apply(h,w,fx,fz,speed,x,z):
    # An elevated wooden flume carries the high water over this dry mill apron.
    # Do not let the coarse grid's upstream water envelope flood its lower floor.
    apron=(x>=242)&(x<=256)&(z>=-157.5)&(z<=-136)
    w[apron]=0
    distance=np.full_like(x,np.inf); level=np.zeros_like(x); dxs=np.zeros_like(x); dzs=np.zeros_like(x)
    for a,b in zip(TAILRACE,TAILRACE[1:]):
        dx,dz=b[0]-a[0],b[1]-a[1];length=np.hypot(dx,dz)
        t=np.clip(((x-a[0])*dx+(z-a[1])*dz)/(length*length),0,1)
        d=np.hypot(x-a[0]-t*dx,z-a[1]-t*dz);take=d<distance
        distance=np.minimum(distance,d);level=np.where(take,a[2]+t*(b[2]-a[2]),level)
        dxs=np.where(take,dx/length,dxs);dzs=np.where(take,dz/length,dzs)
    width=1.65
    wet=distance<width
    depth=.65*np.maximum(0,1-(distance/width)**2)**.7
    edge=np.maximum(distance-width,0)
    influence=np.clip(1-edge/3.0,0,1);influence=influence*influence*(3-2*influence)
    target=level-depth+.25*edge
    h[:]=h*(1-influence)+np.minimum(h,target)*influence
    w[:]=np.where(distance<width+1.5,level,w)
    fx[:]=np.where(wet,dxs,fx);fz[:]=np.where(wet,dzs,fz);speed[:]=np.where(wet,.65,speed)
    # Small millpond joining the river, immediately before the flume intake.
    pond=((x-255)/4.2)**2+((z+163)/5.0)**2
    inside=pond<1
    h[:]=np.where(inside,np.minimum(h,48.88-.85*(1-pond)),h)
    w[:]=np.where(inside,48.88,w)
