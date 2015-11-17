## Networks: a library of standard neural networks and network constructors
## ========================================================================

## Convolutional Neural Network
## ============================

"A simple convolutional neural network with type"
const simple_cnet = stack(conv2darr, dimshuffle(["x", 0, "x", "x"])) >>> addarr >>> sigmoidarr
