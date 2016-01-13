from theano import tensor as T
from theano import function, config, shared
import numpy as np
import theano
import numpy
import pickle

## THe function will take as input
# theano.config.optimizer = 'None'
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

def features(img):
    import lasagne
    from lasagne.layers import InputLayer, DenseLayer, DropoutLayer
    from lasagne.layers import Conv2DLayer as ConvLayer
    from lasagne.layers import MaxPool2DLayer as PoolLayer
    from lasagne.layers import LocalResponseNormalization2DLayer as NormLayer
    from lasagne.utils import floatX

    img = T.tensor4('input_img')
    net = {}
    net['input'] = InputLayer((None, 3, 224, 224), input_var = img)
    net['conv1'] = ConvLayer(net['input'], num_filters=96, filter_size=7, stride=2)
    net['norm1'] = NormLayer(net['conv1'], alpha=0.0001) # caffe has alpha = alpha * pool_size
    net['pool1'] = PoolLayer(net['norm1'], pool_size=3, stride=3, ignore_border=False)
    net['conv2'] = ConvLayer(net['pool1'], num_filters=256, filter_size=5)
    net['pool2'] = PoolLayer(net['conv2'], pool_size=2, stride=2, ignore_border=False)
    net['conv3'] = ConvLayer(net['pool2'], num_filters=512, filter_size=3, pad=1)
    net['conv4'] = ConvLayer(net['conv3'], num_filters=512, filter_size=3, pad=1)
    net['conv5'] = ConvLayer(net['conv4'], num_filters=512, filter_size=3, pad=1)
    net['pool5'] = PoolLayer(net['conv5'], pool_size=3, stride=3, ignore_border=False)
    net['fc6'] = DenseLayer(net['pool5'], num_units=4096)
    net['drop6'] = DropoutLayer(net['fc6'], p=0.5)
    net['fc7'] = DenseLayer(net['drop6'], num_units=4096)
    net['drop7'] = DropoutLayer(net['fc7'], p=0.5)
    net['fc8'] = DenseLayer(net['drop7'], num_units=1000, nonlinearity=lasagne.nonlinearities.softmax)
    output_layer = net['fc8']

    model = pickle.load(open('vgg_cnn_s.pkl'))
    CLASSES = model['synset words']
    MEAN_IMAGE = model['mean image']

    lasagne.layers.set_all_param_values(output_layer, model['values'])
    params = lasagne.layers.get_all_params(output_layer)
    conv1_th = lasagne.layers.get_output(net['conv1'])
    norm1_th = lasagne.layers.get_output(net['norm1'])
    pool1_th = lasagne.layers.get_output(net['pool1'])
    conv2_th = lasagne.layers.get_output(net['conv2'])
    pool2_th = lasagne.layers.get_output(net['pool2'])
    conv3_th = lasagne.layers.get_output(net['conv3'])
    conv4_th = lasagne.layers.get_output(net['conv4'])
    conv5_th = lasagne.layers.get_output(net['conv5'])
    pool5_th = lasagne.layers.get_output(net['pool5'])
    fc6_th = lasagne.layers.get_output(net['fc6'])
    drop6_th = lasagne.layers.get_output(net['drop6'])
    fc7_th = lasagne.layers.get_output(net['fc7'])
    output_layer_th = lasagne.layers.get_output(output_layer)
    return (conv1_th norm1_th, pool1_th, conv2_th, pool2_th, conv3_th, conv4_th,
            conv5_th, pool5_th, fc6_th, drop6_th, fc7_th, output_layer_th)

def draw(img):
    import pylab
    import matplotlib.pyplot as plt
    from PIL import Image
    plt.imshow(img)
    plt.show()

def main():
    width = 224
    height = 224
    # Generate initial rays
    exfragcoords = gen_fragcoords(width, height)
    nprims = 2000
    render = make_render(nprims, width, height)
    shapes = []
    for i in range(nprims):
        shapes.append([go(), go(), go(), gogo()])

    shapes = np.array(shapes, dtype=config.floatX)
    img = render(exfragcoords, shapes)

#
# f = theano.function([inp_var], [conv1_th, pool1_th, fc6_th, output_layer_th])
