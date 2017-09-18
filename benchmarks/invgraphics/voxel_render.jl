using Arrows
using Arrows.TensorFlowTarget
import Arrows.TensorFlowTarget: graph_to_arrow
using PyCall
using Images
using JLD
load_data() = load("/home/zenna/repos/Arrows.jl/data/voxels.jld")["voxels"]

"Generates an arrow which renders voxels to images"
function render_arrow()
  @pyimport reverseflow.vr as vrr
  model = vrr.main()
  voxels, _, image, graph = model
  input_tens = PyTensor[voxels]
  output_tens = PyTensor[image]
  graph = PyGraph(graph)
  arrow = graph_to_arrow(:voxel_render, input_tens, output_tens, graph)
  arrow
end

"Render voxels to an image"
function render_images(pol::Arrows.Policy, slice)
  flat_images = Arrows.interpret(vpol, slice)[1]
  images = reshape(flat_images, batch_size, 128, 128)
end

"Random Slice"
function random_slice(batch_size)
  res = 32
  voxel_data = load_data()
  voxel_data = reshape(voxel_data, (:, res * res * res))
  rand_indices = rand(1:size(voxel_data)[1], batch_size)
  slice = voxel_data[rand_indices, :]
end

"invert renderer"
function invert_render(renderarr::Arrows.Arrow)
  inv_render = invert(renderarr)
end

function render()
  batch_size = 128
  arr = render_arrow()
  @assert Arrows.is_valid(vpol)
  slice = random_slice(batch_size)
  img_batch = render_images(vpol, slice)
  colorview(Gray, img_batch[rand(1:128),:,:])
end
