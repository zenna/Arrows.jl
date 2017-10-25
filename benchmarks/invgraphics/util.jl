
"Random Slice"
function random_slice(batch_size)
  res = 32
  voxel_data = load_data()
  voxel_data = reshape(voxel_data, (:, res * res * res))
  rand_indices = rand(1:size(voxel_data)[1], batch_size)
  slice = voxel_data[rand_indices, :]
end
