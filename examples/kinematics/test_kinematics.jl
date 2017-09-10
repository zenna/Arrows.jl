
### Testing Drawing
function example_data_angles(path_length::Integer)
  angles = rand(path_length) * 2π
  obstacles = [Circle([0.5, 1.5], 0.7)
               Circle([2.0, 1.8], 0.7)]
  x_target = 2.4
  y_target = 1.5
  angles, obstacles, x_target, y_target
end

function test_draw()
  angles, obstacles, x_target, y_target = example_data_angles(3)
  drawscene(angles, obstacles, x_target, y_target)
end

# Tests #
function example_data(path_length::Integer)
  # obstacles = [Circle([5.0, 5.0], 3.0)]
  obstacles = [Circle([5.0, 5.0], 1.0)]
  points = mvuniform(0, 10, 2, path_length)
  origin = Rectangle([0.0 0.0
                      0.2 0.2])
  dest = Rectangle([9.9 9.9
                    10.0 10.0])
  points, origin, dest, obstacles
end

function test_mp2d(path_length = 4, nsamples = 1)
  points, origin, dest, obstacles = example_data(path_length)
  good_path = validpath(points, obstacles, origin, dest)
  sample = rand(points, good_path, nsamples; precision = 0.01, parallel = true, ncores = nprocs() - 1) / 10.0
end
