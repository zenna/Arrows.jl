The problem as I see it I need to replace outer and make all the inner connections.

Modifying Graph

With the solver we get solutions.  These may say that one variable is a function of another.
We therefore want to eliminite, either explicitly or implicitly the redundant port.
We may also need to add this functional relationship to the arrow

- There are changes you might want to to make to every copy of a CompArrow
- And there are changes you might want to make to just one instance

A couple things aren't clear to me
- If I have an arrow it is multiple nested sub arrows which reference the same
cokmp.
Are they really the same as in will mutating one change another

The problem with removing a port by mutation is that
- All the parent arrows are now broken
- So then maybe I should walk the thing

Bbut there's a question of what am I fixing.
Currently: I am deriving all the constraints for all the parameters



is▹
using ForwardDiff-
using ReverseDiff
using MNIST
using TestImages
# using PyPlot
using Plots
pyplot()
mnistdata = traindata()
blobs = testimage("jetplane")
blobs = map(x->Float64(x.val), blobs)
δ(x, y) = abs(x-y)
δ(x1, y1, x2, y2) = sqrt((x1 - x2)^2 + (y1 - y2)^2)
g(x, y) = exp(-δ(x, y)/5)
g(x1, y1, x2, y2) = exp(-δ(x1, y1, x2, y2))

function field(p::Real, x::Vector)
  sum([x[i]g(p, i) for i = 1:length(x)])
end

function field2d(px::Real, py::Real, m::Array)
  sum = 0.0
  for i = 1:size(m, 1)
    for j = 1:size(m, 2)
      sum += m[i, j]g(px, py, i, j)
    end
  end
  sum
end

function make_surf(x, y, m)
  out = zeros(x, y)
  for i = 1:x
    for j = 1:y
      out[i, j] = field2d(Float64(i), Float64(j), m)
    end
  end
  out
end


# Reshape the data into a batch of images
flat_images = transpose(mnistdata[1])
images = reshape(flat_images, (60000, 28, 28))
img1 = images[1, :, :]

# randomly permute the images
rand_perm = shuffle(1:784)
flat_shuffle_images = zeros(flat_images)
for b = 1:size(flat_images, 1)
   flat_shuffle_images[b, :] = flat_images[b, rand_perm]
end
shuffle_images = reshape(flat_shuffle_images, (60000, 28, 28))

# plot(x->field(x, shuffle_images[1,:]), linspace(1, 50, 50))
# scatter!(1:50, shuffle_images[1, 1:50], c=:red)
# gui()

## The neural network
function p_layer{T}(input_batch, Θ::AbstractArray{T})
  output_batch = zeros(T, batch_size, 28, 28)
  for b = 1:size(input_batch, 1)
    for i = 1:size(Θ, 1)
      for j =1:size(Θ, 2)
        output_batch[b, i, j] = field(Θ[i, j], input_batch[b, :])
      end
    end
  end
  output_batch
end


Θ_1 = rand(28, 28) * 784
batch_size = 2
input_batch = flat_shuffle_images[1:batch_size, :]
function nnet(params::AbstractArray)
  l2 = p_layer(input_batch, params)
  mean(l2)
end

Δop, time1, _ = @timed ReverseDiff.gradient(nnet, Θ_1)
Δop2, time2, _ = @timed ForwardDiff.gradient(nnet, Θ_1)
time2
