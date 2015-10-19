using Arrows
using Images, ImageView
img = imread("examples/images/3wolfmoon.jpg")
A = reinterpret(Uint8, data(img))
B = map(Float64,A) / 256
C = permutedims(B, [3,1,2])
D = reshape(B, 1,3,516,639)

# Weights
w_bound = sqrt(3 * 9 * 9)
w_shp = (2, 3, 9, 9)
weights = rand(Float64, w_shp...) * 2w_bound - w_bound

# bias
b_shp = (2,)
b = rand(Float64, 2) - 0.5


cnet_lambda = Arrows.lambda(simple_cnet)
op = cnet_lambda(D, weights, b)
