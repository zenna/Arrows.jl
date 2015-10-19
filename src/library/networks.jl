## Networks
## ========

# This is a library of standard neural networks and network constructors

## Convolutional Neural Network
## ============================

"""
The input to a convolutional layer is a m x m x r image here m is the height and
width of the image and r is the number of channels.
A convolutional neural network is composed of a sequence of layers where a layers
is either
- a convolutional layer: convolves an imput image with a kernel whose values are learned
- activation layer -

"""

"This is a simple convolutional neural network with type"
simple_cnet = Arrows.over(Arrows.lift(Arrows.conv2dfunc)) >>> Arrows.lift(Arrows.addfunc) >>> Arrows.lift(Arrows.relu1dfunc)

cnet_lambda = Arrows.lambda(simple_cnet)
op = cnet_lambda(D, weights, b)
