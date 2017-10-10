using NamedTuples
using JLD

# For repeatability
# STD_ROTATION_MATRIX = rand_rotation_matrices(nviews)
const STD_ROTATION_MATRIX = [0.94071758  -0.33430171 -0.05738258
                             -0.33835238 -0.91297877 -0.2280076
                             0.02383425  0.2339063 -0.97196698]


"(width, height, 2) array, res[i,j] = [i,j] - generate ray directions based on an increment"
function gen_fragcoords(width::Integer, height::Integer)
  raster_space = zeros(width, height, 2)
  for i = 1:width
    for j = 1:height
      raster_space[i, j, :] = [i, j] - 0.5
    end
  end
  return raster_space
end


"""Render rays starting with raster_space according to geometry"""
function make_ro(r, raster_space, width, height)
  nmatrices = 1
  resolution = [width, height]
  # Normalise it to be bound between 0 1
  norm_raster_space = raster_space ./ reshape(resolution, 1, 1, 2)
  # Put it in NDC space, -1, 1
  screen_space = -1.0 + 2.0 * norm_raster_space
  screen_space[51,1,1]
  # Make pixels square by mul by aspect ratio
  aspect_ratio = resolution[1] / resolution[2]
  ndc_space = screen_space .* reshape([aspect_ratio, 1.0], (1, 1, 2))
  # Ray Direction

  # Position on z-plane
  scalars = ones(width, height, 1) * 1.0
  ndc_xyz = cat(3, ndc_space, scalars) * 0.5  # Change focal length

  # Put the origin farther along z-axis
  ro = [0, 0, 1.5]

  # Rotate both by same rotation matrix
  ro_t = reshape(ro, (1, 3)) * r
  ndc_t = Array{Float64}(width, height, nmatrices, 3)
  for w = 1:width, h = 1:height
    ndc_t[w, h, 1, :] = ndc_xyz[w, h, :]' * r
  end
  ndc_t = reshape(ndc_t, (width, height, nmatrices, 3))
  ndc_t = permutedims(ndc_t, (3, 1, 2, 4))
  println("Done")

  # Increment by 0.5 since voxels are in [0, 1]
  ro_t = ro_t + 0.5
  ndc_t = ndc_t + 0.5
  # Find normalise ray dirs from origin to image plane
  unnorm_rd = ndc_t .- reshape(ro_t, (nmatrices, 1, 1, 3))
  norms = [norm(unnorm_rd[:,w,h,:]) for w = 1:size(unnorm_rd, 2), h = 1:size(unnorm_rd, 3)]

  rd = unnorm_rd ./ reshape(norms, (nmatrices, width, height, 1))
  return rd, ro_t
end

function innerloop(left_over, orig, rd, step_sz, i)
  # Find the position (x,y,z) of ith step
  pos = orig + rd * step_sz * i

  # convert to indices for voxel cube
  voxel_indices = floor(pos * res)
  pruned = clip(voxel_indices, 0, res - 1)
  p_int = Int(pruned)
  indices = reshape(p_int, (nmatrices * width * height, 3))

  # convert to indices in flat list of voxels
  flat_indices = indices[:, 0] + res * (indices[:, 1] + res * indices[:, 2])

  # tile the indices to repeat for all elements of batch
  # import pdb; pdb.set_trace()
  tiled_indices = np.tile(flat_indices, opt.batch_size)
  batched_indices = np.transpose([x_tiled, tiled_indices])
  batched_indices = batched_indices.reshape(opt.batch_size, len(flat_indices), 2)
  attenuation = tf.gather_nd(voxels, batched_indices)
  left_over * tf.exp(-attenuation * opt.density * step_sz_flat)
end

"""
Renders `batch_size` voxel grids
# Arguments
- voxels : (batch_size, res, res, res)
- rotation_matrix : (m, 4)
- width: width in pixels of rendered image
- height: height in pixels of rendered image
- nsteps: number of points along each ray to sample voxel grid
- res: voxel resolution 'voxels' should be res * res * res
- batch_size: number of voxels to render in batch
- gdot_cube: dot product of gradient and light, can be computed offline
- used only in phond shading
- phong: do phong shading

# Returns
- (n, m, width, height) - from voxel data from functions in voxel_helpers
"""
function gen_img(voxels, rotation_matrix, opt)
  width, height, res = opt.width, opt.height, opt.res
  raster_space = gen_fragcoords(width, height)
  rd, ro = make_ro(rotation_matrix, raster_space, width, height)
  a = 0 - ro  # c = 0
  b = 1 - ro  # c = 1
  nmatrices = 1
  tn = reshape(a, (nmatrices, 1, 1, 3)) ./ rd
  tff = reshape(b, (nmatrices, 1, 1, 3)) ./ rd
  tn_true = min(tn, tff)
  tff_true = max(tn, tff)

  # do X
  tn_x = tn_true[:, :, :, 1]
  tff_x = tff_true[:, :, :, 1]
  tmin = 0.0
  tmax = 10.0
  t0 = fill(tmin, size(tn_x))
  t1 = fill(tmax, size(tn_x))

  t02 = ifelse(tn_x .> t0, tn_x, t0)
  t12 = ifelse(tff_x .< t1, tff_x, t1)

  # y
  tn_x = tn_true[:, :, :, 2]
  tff_x = tff_true[:, :, :, 2]
  t03 = ifelse(tn_x .> t02, tn_x, t02)
  t13 = ifelse(tff_x .< t12, tff_x, t12)
  # z
  tn_x = tn_true[:, :, :, 3]
  tff_x = tff_true[:, :, :, 3]
  t04 = ifelse(tn_x .> t03, tn_x, t03)
  t14 = ifelse(tff_x .< t13, tff_x, t13)

  # Shift a little bit to avoid numerial inaccuracies
  t04 = t04 * 1.001
  t14 = t14 * 0.999

  left_over = ones((opt.batch_size, nmatrices * width * height,))
  step_size = (t14 - t04) / opt.nsteps

  orig = reshape(ro, (nmatrices, 1, 1, 3)) .+ rd .* reshape(t04, (nmatrices, width, height, 1))
  xres = yres = res

  orig = reshape(orig, (nmatrices * width * height, 3))
  rd = reshape(rd, (nmatrices * width * height, 3))
  step_sz = reshape(step_size, (nmatrices * width * height, 1))
  step_sz_flat = reshape(step_sz, (1, nmatrices * width * height))

  # For batch rendering, we treat each voxel in each voxel independently,
  nrays = width * height
  x = 0:opt.batch_size
  x_tiled = repeat(x, nrays)
  for i = 1:opt.nsteps
    left_over = innerloop(left_over, orig, rd, step_sz, i)
  end
  left_over
end

function test_render()
  voxels = load("/home/zenna/repos/Arrows.jl/data/voxels.jld")["voxels"]
  opt = @NT(width = 128, height = 128, nsteps = 6, res = 32, batch_size = 4,
            phong = false, density = 1.0)
  gen_img(voxels, STD_ROTATION_MATRIX, opt)
end

img = test_render()
#
# width = 128
# height = 128
# nsteps = 6
# res = 32
#
# opt = @NT(width = 128, height = 128, nsteps = 6, res = 32, batch_size = 4,
#           phong = false, density = 1.0)
#
# width, height, res = opt.width, opt.height, opt.res
# raster_space = gen_fragcoords(width, height)
# rd, ro = make_ro(STD_ROTATION_MATRIX, raster_space, width, height)
# a = 0 - ro  # c = 0
# b = 1 - ro  # c = 1
# nmatrices = 1
# tn = reshape(a, (nmatrices, 1, 1, 3)) ./ rd
# tff = reshape(b, (nmatrices, 1, 1, 3)) ./ rd
# tn_true = min(tn, tff)
# tff_true = max(tn, tff)
#
# # do X
# tn_x = tn_true[:, :, :, 1]
# tff_x = tff_true[:, :, :, 1]
# tmin = 0.0
# tmax = 10.0
# t0 = fill(tmin, size(tn_x))
# t1 = fill(tmax, size(tn_x))
#
# t02 = ifelse(tn_x .> t0, tn_x, t0)
# t12 = ifelse(tff_x .< t1, tff_x, t1)
#
# # y
# tn_x = tn_true[:, :, :, 2]
# tff_x = tff_true[:, :, :, 2]
# t03 = ifelse(tn_x .> t02, tn_x, t02)
# t13 = ifelse(tff_x .< t12, tff_x, t12)
# # z
# tn_x = tn_true[:, :, :, 3]
# tff_x = tff_true[:, :, :, 3]
# t04 = ifelse(tn_x .> t03, tn_x, t03)
# t14 = ifelse(tff_x .< t13, tff_x, t13)
#
# # Shift a little bit to avoid numerial inaccuracies
# t04 = t04 * 1.001
# t14 = t14 * 0.999
#
# left_over = ones((opt.batch_size, nmatrices * width * height,))
# step_size = (t14 - t04) / opt.nsteps
#
# orig = reshape(ro, (nmatrices, 1, 1, 3)) .+ rd .* reshape(t04, (nmatrices, width, height, 1))
# xres = yres = res
#
# orig = reshape(orig, (nmatrices * width * height, 3))
# rd = reshape(rd, (nmatrices * width * height, 3))
# step_sz = reshape(step_size, (nmatrices * width * height, 1))
# step_sz_flat = reshape(step_sz, (1, nmatrices * width * height))
#
# # For batch rendering, we treat each voxel in each voxel independently,
# nrays = width * height
# x = 0:opt.batch_size
# x_tiled = repeat(x, nrays)
# for i = 1:opt.nsteps
#   innerloop(left_over)
# end
#
# img = left_over
# return img
