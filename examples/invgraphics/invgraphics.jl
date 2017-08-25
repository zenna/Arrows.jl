using Arrows


"A scalar field"
immutable Field
  data::Matrix{Float64}
end

"A dense voxel grid"
immutable VoxelGrid
  data::Array
end

function s(grid::VoxelGrid, xyz::Vector{Float64})
  ...
end

"Evalaute the scalar `field` at position `xyz`"""
function s(field::Field, xyz::Vector{Float64})
  ...
end

"Encode a voxel grid into a field"
function encode(grid::VoxelGrid)::Field
end

"Encode a voxel grid into a field"
function decode(grid::VoxelGrid)::Field
end

function main()
  model_net = model_net_40()
  image = render(model_net[0], 128, 128)
end

"Render a scalar `field` into an image `width` x `height` pixels"
function render(field::Field, width::Int, height::Int)
  raster_space = gen_fragcoords(width, height)
  rd, ro = make_ro(rotation_matrix, raster_space, width, height)
  a = 0 - ro  # c = 0
  b = 1 - ro  # c = 1
  nmatrices = rotation_matrix.shape[0]
  tn = np.reshape(a, (nmatrices, 1, 1, 3)) / rd
  tff = np.reshape(b, (nmatrices, 1, 1, 3)) / rd
  tn_true = np.minimum(tn, tff)
  tff_true = np.maximum(tn, tff)
  # do X
  tn_x = tn_true[:, :, :, 0]
  tff_x = tff_true[:, :, :, 0]
  tmin = 0.0
  tmax = 10.0
  t0 = tmin
  t1 = tmax
  t02 = np.where(tn_x > t0, tn_x, t0)
  t12 = np.where(tff_x < t1, tff_x, t1)
  # y
  tn_x = tn_true[:, :, :, 1]
  tff_x = tff_true[:, :, :, 1]
  t03 = np.where(tn_x > t02, tn_x, t02)
  t13 = np.where(tff_x < t12, tff_x, t12)
  # z
  tn_x = tn_true[:, :, :, 2]
  tff_x = tff_true[:, :, :, 2]
  t04 = np.where(tn_x > t03, tn_x, t03)
  t14 = np.where(tff_x < t13, tff_x, t13)

  # Shift a little bit to avoid numerial inaccuracies
  t04 = t04 * 1.001
  t14 = t14 * 0.999

  left_over = np.ones((batch_size, nmatrices * width * height,))
  step_size = (t14 - t04) / nsteps
  orig = np.reshape(ro, (nmatrices, 1, 1, 3)) + rd * np.reshape(t04,(nmatrices, width, height, 1))
  xres = yres = res

  orig = np.reshape(orig, (nmatrices * width * height, 3))
  rd = np.reshape(rd, (nmatrices * width * height, 3))
  step_sz = np.reshape(step_size, (nmatrices * width * height, 1))
  # step_sz = np.exp(-step_sz)
  step_sz_flat = step_sz.reshape(nmatrices * width * height)

  # For batch rendering, we treat each voxel in each voxel independently,
  nrays = width * height
  x = np.arange(batch_size)
  x_tiled = np.repeat(x, nrays)
  # voxels = tf.exp(-voxels)
  # voxels = tf.Print(voxels, [tf.reduce_sum(voxels)], message="VOXEL SUM TF")
  # 998627.56
  for i in range(nsteps):
      # Find the position (x,y,z) of ith step
      pos = orig + rd * step_sz * i

      # convert to indices for voxel cube
      voxel_indices = np.floor(pos * res)
      pruned = np.clip(voxel_indices, 0, res - 1)
      p_int = pruned.astype('int64')
      indices = np.reshape(p_int, (nmatrices * width * height, 3))

      # convert to indices in flat list of voxels
      flat_indices = indices[:, 0] + res * (indices[:, 1] + res * indices[:, 2])

      # tile the indices to repeat for all elements of batch
      tiled_indices = np.tile(flat_indices, batch_size)
      batched_indices = np.transpose([x_tiled, tiled_indices])
      batched_indices = batched_indices.reshape(batch_size, len(flat_indices), 2)
      attenuation = tf.gather_nd(voxels, batched_indices)
      if phong:
          grad_samples = tf.gather_nd(gdotl_cube, batched_indices)
          attenuation = attenuation * grad_samples
      # left_over = left_over * -attenuation * density * step_sz_flat
      left_over = left_over * tf.exp(-attenuation * density * step_sz_flat)
      # left_over = left_over * attenuation

  img = left_over
  return img
end


"Load the ModelNet40 dataset"
function model_net_40()
  ...
end

# Questions
## am I doing some kind of symbolic computation like in tensorlow and Sigma
## or something else

# How to deal with batching
# Float64 or General

# How to deal with batching?

# Use convert instead of encode

# Encode the for loop in the graph?
