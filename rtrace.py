from theano import tensor as T
from theano import function
import numpy as np
import theano

import numpy
import pylab
import matplotlib.pyplot as plt
from PIL import Image

## THe function will take as input
theano.config.optimizer = 'None'

# ro_capture = 0
# rd_capture = 0
# params_capture = 0
d_d = 1
ro = np.array([-3.96497374,  2.        ,  0.99392003])
rd = np.array([ 0.68886577, -0.6642004 , -0.2903477 ])
o_o = np.dot(ro, ro)
d_o = np.dot(rd, ro)
a = d_d
b = 2*d_o
radii = 0.01204426
c = o_o - radii**2

# rd = img[1][0,0]
# ro = np.array([-3.96497374,  2.        ,  0.99392003])

def mapedit(ro, rd, params, nprims, width, height):
    # Translate ray origin by the necessary parameters
    ro_repeat = T.tile(T.reshape(ro_repeat, (width, height, 3, 1)), nprims)
    translate_params = params[:, 0:3]
    ro_translated = ro_repeat + translate_params
    ro = ro_translated
    # ro_translated = ro_repeat
    sphere_radii = params[:, 3]

    # Do sphere
    d_d = T.sum(rd * rd, axis = 2)
    d_o = T.sum(rd * ro, axis = 2)
    o_o = T.sum(ro * ro, axis = 2)
    a = d_d
    b = 2*d_o
    o_o_ = T.reshape(o_o, (640, 480, 1))
    c = T.tile(o_o_, nprims) - sphere_radii**2
    a_ = T.reshape(a, (width, height, 1))
    b_ = T.reshape(b, (width, height, 1))
    b__ = T.tile(b_, nprims)
    inner = b_ * b_ - 4*a_* c

    ## Case 1
    does_intersect = inner > 0.0
    does_not_intersect = T.reshape(inner < 0.0, (640, 480, nprims, 1))
    closest_root = -d_o / d_d
    closest_root = T.tile(T.reshape(closest_root, (640, 480, 1)), nprims)

    ## Calculate Roots
    two_a = 2.0*a
    minus_b = -b_
    sqrt_inner = T.sqrt(inner)
    root1 = (minus_b - sqrt_inner)/adddim(two_a)
    root2 = (minus_b + sqrt_inner)/adddim(two_a)
    root1 = T.reshape(root1, (width, height, nprims, 1))
    root2 = T.reshape(root2, (width, height, nprims, 1))

    ## Cases
    one_pos = root1 > 0.0
    two_pos = root2 > 0.0
    only_one_pos = T.xor(one_pos, two_pos)
    both_pos = T.and_(one_pos, two_pos)

    # Of it does not intersect return blank.
    # if its behind the screen
    # then return background_dist = 100.0
    background_dist = 100
    maxes = np.full((640, 480, nprims, 1), background_dist)
    # unclamped = T.switch(does_intersect, maxes,
    #                          T.switch(b__ > 0, root2,
    #                                          T.switch(root1 < 0, root2, root1)))
    # intersect_behind = T.and_(root1 < 0.0, root2 < 0.0)
    depth = T.switch(does_not_intersect, maxes,
                             T.switch(root1 > 0, root1,
                                             T.switch(root2 > 0, root2, maxes)))
    # root = T.maximum(0.0, unclamped)
    # union = T.min(root, axis=2)
    depth = T.reshape(depth, (640, 480, nprims))
    global ro_capture
    ro_capture = ro
    global rd_capture
    rd_capture = rd
    global params_capture
    params_capture = params
    i = T.min(depth, axis = 2)
    return [i, rd, d_d, d_o, o_o, a, b, c, o_o, o_o_, innerm sphere_radii]
    #return T.min(depth, axis = 2)

def adddim(img):
    return T.reshape(img, (640, 480, 1))

def castray(ro, rd, shape_params, nprims, width, height):
    return mapedit(ro, rd, shape_params, nprims, width, height)

## Render with ray at ray origin ro and direction rd
def renderrays(ro, rd, shape_params, nprims, width, height):
    # col = np.array([0.7, 0.9, 1.0]) + T.reshape(rd[:,:,1], (width, height, 1)) * 0.8
    return castray(ro, rd, shape_params, nprims, width, height)

# Normalise a vector
def normalize(v):
    return v / np.linalg.norm(v)

def set_camera(ro, ta, cr):
    cw = normalize(ta - ro)
    cp = np.array([np.sin(cr), np.cos(cr),0.0])
    cu = normalize(np.cross(cw,cp))
    cv = normalize(np.cross(cu,cw))
    return (cu, cv, cw)

# Append an image filled with scalars to the back of an image.
def stack(intensor, width, height, scalar):
    scalars = np.ones([width, height, 1]) * scalar
    return T.concatenate([intensor, scalars], axis=2)

def make_render(nprims, width, height):
    # Shape params
    shape_params = T.matrix('shape')
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
    ro_ = np.tile(ro, [width, height, 1])
    res = renderrays(ro_, rd, shape_params, nprims, width, height)
    render = function([fragCoords, shape_params], res)
    return render

def gen_fragcoords(width, height):
    fragCoords = np.zeros([width, height, 2])
    for i in range(width):
        for j in range(height):
            fragCoords[i,j] = np.array([i,j]) + 0.5
    return fragCoords

## example
##########
def go():
    return np.random.rand()*4 - 2

def gogo():
    return np.random.rand()*0.1

width = 640
height = 480
exfragcoords = gen_fragcoords(width, height)
nprims = 50
render = make_render(nprims, width, height)

shapes = []
for i in range(nprims):
    shapes.append([go(), go(), go(), gogo()])

shapes = np.array(shapes)
#
#
# shape = np.array([[-0.0, -0.25, -1.0, 0.25, 0.1, 0.1, 2.9],
#                   [-1.0, -0.25, -1.0, 0.25, 0.1, 3.1, 0.9],
#                   [-1.0, -1.25, -0.5, 0.21, 0.3, 0.5, 0.5],
#                   [go(), go(), go(), gogo(), gogo(), gogo(), gogo()]])
# array([[-1.4989805 ,  0.61595596, -0.07049085,  0.01204426]])
img = render(exfragcoords, shapes)
plt.imshow(img[0])
plt.show()
