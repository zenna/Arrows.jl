from theano import tensor as T
from theano import function, config, shared
import numpy as np
import theano
import numpy

## THe function will take as input
# theano.config.optimizer = 'None'

# ro_capture = 0
# rd_capture = 0
# params_capture = 0


# rd = img[1][0,0]
# ro = np.array([-3.96497374,  2.        ,  0.99392003])
def mindist(translate, radii, min_so_far, ro, rd, background):
    ro = ro + translate
    d_o = T.dot(rd, ro)     # 640, 480
    o_o = T.dot(ro, ro)   # scalar
    b = 2*d_o
    c = o_o - radii**2 #FIXME, remove this squaring
    inner = b **2 - 4 * c   # 640 480
    does_not_intersect = inner < 0.0
    minus_b = -b
    sqrt_inner = T.sqrt(inner)
    root1 = (minus_b - sqrt_inner)/2.0
    root2 = (minus_b + sqrt_inner)/2.0
    depth = T.switch(does_not_intersect, background,
                        T.switch(root1 > 0, root1,
                        T.switch(root2 > 0, root2, background)))
    return T.min([min_so_far, depth], axis=0)



def mapedit(ro, rd, params, nprims, width, height):
    # Translate ray origin by the necessary parameters
    translate_params = params[:, 0:3]
    sphere_radii = params[:, 3]
    background_dist = 10
    background = np.full((width, height), background_dist, dtype=config.floatX)
    init_depth = shared(background)
    results, updates = theano.scan(mindist, outputs_info=init_depth, sequences=[translate_params, sphere_radii], non_sequences = [ro, rd, init_depth])
    return results[-1], updates

def adddim(img):
    # LOL!
    global width
    global height
    return T.reshape(img, (width, height, 1))

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
    cp = np.array([np.sin(cr), np.cos(cr),0.0], dtype=config.floatX)
    cu = normalize(np.cross(cw,cp))
    cv = normalize(np.cross(cu,cw))
    return (cu, cv, cw)

# Append an image filled with scalars to the back of an image.
def stack(intensor, width, height, scalar):
    scalars = np.ones([width, height, 1], dtype=config.floatX) * scalar
    return T.concatenate([intensor, scalars], axis=2)

def make_render(nprims, width, height):
    # Shape params
    shape_params = T.matrix('shape')
    iResolution = np.array([width, height], dtype=config.floatX)
    fragCoords = T.tensor3()
    cat = T.matrix()
    q = fragCoords / iResolution
    p = -1.0 + 2.0 * q
    p2 = p * np.array([iResolution[0]/iResolution[1],1.0], dtype=config.floatX)
    # Ray Direction
    op = stack(p2, width, height, 2.0)
    outop = op / T.reshape(op.norm(2, axis=2), (width, height, 1))
    ro = np.array([-0.5+3.5*np.cos(3.0), 2.0, 0.5 + 3.5*np.sin(3.0)], dtype=config.floatX)
    ta = np.array([-0.5, -0.4, 0.5], dtype=config.floatX)
    (cu, cv, cw) = set_camera(ro, ta, 0.0)
    # setup Camera
    a = T.sum(cu * outop, axis=2)
    b = T.sum(cv * outop, axis=2)
    c = T.sum(cw * outop, axis=2)
    # Get ray direction
    rd = T.stack([a,b,c], axis=2)
    ro_ = np.tile(ro, [width, height, 1])
    res, updates = renderrays(ro, rd, shape_params, nprims, width, height)
    render = function([fragCoords, shape_params], res, updates=updates)
    return render

def gen_fragcoords(width, height):
    fragCoords = np.zeros([width, height, 2], dtype=config.floatX)
    for i in range(width):
        for j in range(height):
            fragCoords[i,j] = np.array([i,j], dtype=config.floatX) + 0.5
    return fragCoords

## example
##########
def go():
    return np.random.rand()*4 - 2

def gogo():
    return np.random.rand()*0.1

width = 300
height = 300
exfragcoords = gen_fragcoords(width, height)
nprims = 2000

render = make_render(nprims, width, height)

shapes = []
for i in range(nprims):
    shapes.append([go(), go(), go(), gogo()])

shapes = np.array(shapes, dtype=config.floatX)
#
#
# shape = np.array([[-0.0, -0.25, -1.0, 0.25, 0.1, 0.1, 2.9],
#                   [-1.0, -0.25, -1.0, 0.25, 0.1, 3.1, 0.9],
#                   [-1.0, -1.25, -0.5, 0.21, 0.3, 0.5, 0.5],
#                   [go(), go(), go(), gogo(), gogo(), gogo(), gogo()]])
# array([[-1.4989805 ,  0.61595596, -0.07049085,  0.01204426]])
img = render(exfragcoords, shapes)
#
# import pylab
# import matplotlib.pyplot as plt
# from PIL import Image
# plt.imshow(img)
# plt.show()
