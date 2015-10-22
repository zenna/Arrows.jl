using Arrows
using Images, ImageView
img = imread("examples/images/3wolfmoon.jpg")
A = reinterpret(Uint8, data(img))
B = map(Float64,A) / 256

# reshape into 3 height width
C = permutedims(B, [1,3,2])

# make minibatch of size 1
D = reshape(C, 1, 3,639, 516)

# Weights
w_bound = sqrt(3 * 9 * 9)
w_shp = (2, 3, 9, 9)
weights = rand(Float64, w_shp...) * 2w_bound - w_bound

# bias
b_shp = (2,)
b = rand(Float64, 2) - 0.5

result = Arrows.Library.simple_cnet(D,weights,b)
view(reshape(result[1][1,1,:,:], 631, 508))
