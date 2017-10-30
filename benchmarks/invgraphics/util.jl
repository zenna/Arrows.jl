import JLD: load

"Default datadir"
function datadir()
  if "DATADIR" in keys(ENV)
    joinpath(ENV["DATADIR"])
  else
    joinpath("~./")
  end
end

"Load ModelNet from file"
function modelnet(path=joinpath(datadir(), "ModelNet40", "voxels.jld"))
  voxels = load(path)["voxels"]
end

"Load ModelNet from file"
function smallmodelnet(path=joinpath(datadir(), "ModelNet40", "smallvoxels.jld"))
  voxels = load(path)["smallvoxels"]
end

"Random Slice of size `batch_size` from `voxel_data`"
function randslice(batch_size, voxel_data=load_modelnet())
  res = 32  # FIXME: Determine res from data
  voxel_data = reshape(voxel_data, (:, res * res * res))
  rand_indices = rand(1:size(voxel_data)[1], batch_size)
  slice = voxel_data[rand_indices, :]
end
