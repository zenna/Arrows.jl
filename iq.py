from theano import tensor as T
from theano import function
import numpy as np

import numpy
import pylab
import matplotlib.pyplot as plt
from PIL import Image

# # Return the number of parameters needed for an edit chain of n units
# def edit_chain_nparams(n):
#     return 10
#
# # Chain of signed distance functions
# def edit_chain(pos, params, n):
#     # generate a chain of n nodes (n primitives, )
#
#     # For n edits we need n primitives, n translations and n - 1 merges
#     for i in range(n):
#         prims = super_prim(pos, params[start:end])
#
#     for i in rnage(n-1)
#         merge = super_merge(...)
#
#     return ok
#
# def stack_images(imgs):
#     return T.stack(imgs, axis = 2)
#
# def smooth_min(dists, k):
#     stacked_imgs = stack_images(dists)
#     b = T.pow(stack_images, k)
#
#
# def super_prim(pos, b, t, r):
#     box = sdBox(pos, b)
#     torus = sdBox(pos, t)
#     roundbox = udRoundBox(pos, b,r)
#     return merged = softmin([box, torus, roundbox])

## Signed Distance Functions, xyz -> d

## Which representatin of geometry?   It doesnt even matter
## WHat kind of function would a basis function be
# distance to a point, if its zero then it has no surface.


def adddim(img):
    return T.reshape(img, (640, 480, 1))

def sdPlane(pos):
    return adddim(pos[:,:,1])

def sdBox(pos, b):
  d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));

def sdTorus(pos, t):
    a = pos[:,:,(0,2)].norm(2,axis=2) - t[0] # 640, 480
    b = T.stack([a, pos[:,:,1]], axis=2)
    return adddim(b.norm(2,axis=2) - t[1])

def udRoundBox(pos, b, r):
    #FIXME, using magicnu mber 100 instead of ∞, i.e max
    a = T.clip(T.abs_(pos) - b, 0.0, 1000.0)
    return adddim(a.norm(2, axis=2) - r)

def sdSphere(pos, s):
    return adddim(pos.norm(2, axis=2) - s)

## Operators
## =========

## Union - d1, d2 = width × height × 2
def opU(d1, d2, width, height):
    cond = d1[:,:,0] < d2[:,:,0]
    broadcond = T.reshape(cond, (width, height, 1))
    return T.switch(broadcond, d1, d2)

# ## Try a mix and a blend using softmax
# def opBlend(ds, weights, width, height):
#     dosomebledingin = 10
#     ok = T.stack(ds, axis = 2)
#     oksum = T.sum(ok, axis = 2)
#     return ok / oksum

## Try a mix and a blend using softmax
def opBlend(dswithcolor, weights, width, height):
    ds = []
    # extract distances, ignore colours
    for d in dswithcolor:
        ds.append(d[:,:,0])

    expweights = np.exp(weights)
    softweights = expweights / np.sum(expweights)
    rewightedds = []
    for i in range(len(weights)):
        rewightedds.append(ds[i] * weights[i])

    ok = T.stack(rewightedds, axis = 2)
    summed = T.sum(ok, axis = 2)
    return T.reshape(summed, (width, height, 1))

def map(pos, width, height):
    res = stack(sdSphere(pos - np.array([0.0, 0.25, 0.0]), 0.25 ), width, height, 100.0)
    torus = stack(sdTorus(pos - np.array([0.0, 0.25, 1.0]), np.array([0.20, 0.05])), width, height, 25.0)
    plane = stack(sdPlane(pos), width, height, 10.0)
    rndbox = stack(udRoundBox(pos - np.array([0.0, 0.25, 1.0]), np.array([.15, .15, .15]), 0.1), width, height, 41.0)
    boxtorus = opBlend([rndbox, torus], [0.2, 0.9], width, height)
    # rndbox = stack(udRoundBox(pos - np.array([1.0, 0.25, 1.0]), np.array([.15, .15, .15]), 0.1), width, height, 41.0)
    # Union these all
    res = opU(res, plane, width, height)
    # res = opU(res, torus, width, height)
    # res = opU(res, rndbox, width, height)
    res = opU(res, boxtorus, width, height)
    return res

def castray(ro, rd, width, height):
    tmin = 1.0
    tmax = 20.0
    precis = 0.002
    m = -1.0
    # There are a sequence of distances, d1, d2, ..., dn
    # then theres the accumulated distances d1, d1+d2, d1+d2+d3....
    # What we actually want in the output is the sfor each ray the distance to the surface
    # So we want something like 0, 20, 25, 27, 28, 28, 28, 28, 28
    # OK

    max_num_steps = 25

    distcolors = map(ro + rd * 0, width, height) #FIXME, reshape instead of mul by 0
    dists = distcolors[:,:,0]
    steps = T.switch(dists < precis, T.zeros_like(dists), T.ones_like(dists))
    accum_dists = T.reshape(dists, (width, height, 1))

    for i in range(max_num_steps - 1):
        distcolors = map(ro + rd * accum_dists, width, height) #FIXME, reshape instead of mul by 0
        dists = distcolors[:,:,0]
        steps = steps + T.switch(dists < precis, T.zeros_like(dists), T.ones_like(dists))
        accum_dists = accum_dists + T.reshape(dists, (width, height, 1))

    last_depth = T.reshape(accum_dists, (width, height))
    depthmap = T.switch(last_depth < tmax, last_depth / tmax, T.zeros_like(last_depth))
    color = 1.0 - steps / float(max_num_steps)
    # Distance marched along ray and delta between last two steps
    return (depthmap, depthmap, depthmap, depthmap, depthmap)

#
# def reflect(ray_dir, normal):
#     -ray_dir * normal

def normal(ok):
    # so the idea is to compute the reflected ray direction, which i do by first getting the normalok

    return 0


## Render with ray at ray origin ro and direction rd
def renderrays(ro, rd, width, height):
    # col = np.array([0.7, 0.9, 1.0]) + T.reshape(rd[:,:,1], (width, height, 1)) * 0.8
    (res1, res2, res3, res4, res5) = castray(ro, rd, width, height)
    return (res1, res2, res3, res4, res5)
    # m = col[:,:,1]
    # return np.array([0.05,0.08,0.10]) * m
#     vec3 col = vec3(0.7, 0.9, 1.0) + rd.y * 0.8;
#     vec2 res = castRay(ro,rd);
#     float t = res.x;
# 	float m = res.y;
#     if( m>-0.5 )
#     {
#         vec3 pos = ro + t*rd;
#         vec3 nor = calcNormal( pos );
#         vec3 ref = reflect( rd, nor );
#
#         // material
# 		col = 0.45 + 0.3*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
#
#         if( m<1.5 )
#         {
#
#             float f = mod( floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
#             col = 0.4 + 0.1*f*vec3(1.0);
#         }
#
#         // lighitng
#         float occ = calcAO( pos, nor );
# 		vec3  lig = normalize( vec3(-0.6, 0.7, -0.5) );
# 		float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
#         float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
#         float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
#         float dom = smoothstep( -0.1, 0.1, ref.y );
#         float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
# 		float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);
#
#         dif *= softshadow( pos, lig, 0.02, 2.5 );
#         dom *= softshadow( pos, ref, 0.02, 2.5 );
#
# 		vec3 lin = vec3(0.0);
#         lin += 1.20*dif*vec3(1.00,0.85,0.55);
# 		lin += 1.20*spe*vec3(1.00,0.85,0.55)*dif;
#         lin += 0.20*amb*vec3(0.50,0.70,1.00)*occ;
#         lin += 0.30*dom*vec3(0.50,0.70,1.00)*occ;
#         lin += 0.30*bac*vec3(0.25,0.25,0.25)*occ;
#         lin += 0.40*fre*vec3(1.00,1.00,1.00)*occ;
# 		col = col*lin;
#
#     	col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.002*t*t ) );
#
#     }
#
# 	return vec3( clamp(col,0.0,1.0) );
# }

# Normalise a vector
def normalize(v):
    return v / np.linalg.norm(v)

def set_camera(ro, ta, cr):
    cw = normalize(ta - ro)
    cp = np.array([np.sin(cr), np.cos(cr),0.0])
    cu = normalize(np.cross(cw,cp))
    cv = normalize(np.cross(cu,cw))
    return (cu, cv, cw)
#    return np.array([cu, cv, cw])

# def init_camera():
#     ro = np.array([-0.5+3.5*np.cos(3.0), 2.0, 0.5 + 3.5*np.sin(3.0)])
#     ta = np.array([-0.5, -0.4, 0.5])
#     ca = set_camera( ro, ta, 0.0 )
#     return (ro, ca)

# Append an image filled with scalars to the back of an image.
def stack(intensor, width, height, scalar):
    scalars = np.ones([width, height, 1]) * scalar
    return T.concatenate([intensor, scalars], axis=2)

def make_render(width, height):
    iResolution = np.array([width, height], dtype=float)
    fragCoords = T.tensor3()
    cat = T.matrix()
    q = fragCoords / iResolution
    p = -1.0 + 2.0 * q
    p2 = p * np.array([iResolution[0]/iResolution[1],1.0])
    # Ray Direction
    op = stack(p2, width, height, 2.0)
    outop = op / T.reshape(op.norm(2, axis=2), (width, height, 1))
    ro = np.array([-0.5+3.5*np.cos(3.0), 2.0, 0.5 + 3.5*np.sin(3.0)])
    ta = np.array([-0.5, -0.4, 0.5])
    (cu, cv, cw) = set_camera(ro, ta, 0.0)
    # setup Camera
    a = T.sum(cu * outop, axis=2)
    b = T.sum(cv * outop, axis=2)
    c = T.sum(cw * outop, axis=2)
    # Get ray direction
    rd = T.stack([a,b,c], axis=2)
    (res1, res2, res3, res4, res5) = renderrays(ro, rd, width, height)
    render = function([fragCoords], [res1, res2, res3, res4, res5])
    return render

def gen_fragcoords(width, height):
    fragCoords = np.zeros([width, height, 2])
    for i in range(width):
        for j in range(height):
            fragCoords[i,j] = np.array([i,j]) + 0.5
    return fragCoords

## example
##########

width = 640
height = 480
exfragcoords = gen_fragcoords(width, height)
render = make_render(width, height)
img = render(exfragcoords)
plt.imshow(img[0])
plt.show()
