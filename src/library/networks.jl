## Networks: a library of standard neural networks and network constructors
## ========================================================================

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

"A simple convolutional neural network with type"
const simple_cnet = over(lift(conv2dfunc)) >>> lift(addfunc)
