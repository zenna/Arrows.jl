using Luxor

Point = Vector
Vec = Vector
Mat = Matrix

"A geometric entity of N dimensions"
abstract type Shape{N} end

"2D Rectangle"
immutable Rectangle <: Shape{2}
  bounds::Mat
end

"Circle"
immutable Circle <: Shape{2}
  center::Vec
  r
end

"Edge between defined by start and end points"
immutable Edge
  points::Mat
end

"Edge defined by origin and direction vector"
immutable ParametricEdge
  coords::Mat
end

function ParametricEdge(e::Edge)
  origin = e.points[:,1]
  dir = e.points[:,2] - e.points[:,1]
  ParametricEdge(hcat(origin,dir))
end

dot(a::Vector{<:SubPort}, b) = sum(a .* b)
dot(a, b::Vector{<:SubPort}) = sum(a .* b)
dot(a::Vector{<:SubPort}, b::Vector{<:SubPort}) = sum(a .* b)

"Where - if anywhere - along `p` does it intersect segment"
function intersect_segments(ppos::Point, pdir::Vec, qpos::Point, qdir::Vec)
  @show ppos
  @show qpos
  w = ppos - qpos
  u = pdir
  v = qdir
  (v[2] * w[1] - v[1] * w[2]) / (v[1] * u[2] - v[2] * u[1])
end

"Do edges `e1` and `e2` not intersect?"
function intersects(e1::ParametricEdge, e2::ParametricEdge)
  s = intersect_segments(e1.coords[:,1], e1.coords[:,2],
                         e2.coords[:,1], e2.coords[:,2])
  (s < 0) | (s > 1)
end

"Parametric Edges from angles"
function anglestoedge(angles::Vector)
  ps = vertices(angles)
  dirs = directions(ps)
  ps = ps[:, 1:end-1]
  @assert length(ps) == length(dirs)
  ps, dirs
  [ParametricEdge(hcat(ps[:, i], dirs[:, i])) for i = 1:size(ps, 2)]
end

"Does edge `e1` intersect with `circle`?"
function intersects(e1::ParametricEdge, circle::Circle)
  rayorig = e1.coords[:,1]
  raydir = e1.coords[:,2]
  r = circle.r
  f = rayorig - circle.center # Vector from center sphere to ray start
  @show raydir
  @show f
  a = dot(raydir, raydir)
  b = 2.0 * dot(f, raydir)
  c = dot(f, f) - r*r

  # discriminant
  constraint = b * b - 4 * a * c < 0
  Arrows.assert!(constraint)
end

intersects(e1::ParametricEdge, e2::Edge) = intersects(e1, ParametricEdge(e2))

"Do `points` avoid `obs`tacles?"
function pairwisecompare!(edges::Vector, obs)
  @show edges
  @show obs
  @show conditions = [intersects(e, o) for e in edges, o in obs]
  # (&)(conditions...)
end

function to_param_edge(points)
  [ParametricEdge([points[:,i] (points[:,i+1] - points[:,i])])
           for i = 1:size(points,2)-1]
end

function validpath(points, obstacles)
  param_edges = to_param_edge(points)
  avoids_obstacles = pairwisecompare!(param_edges, obstacles)
  avoids_obstacles
end

"Forward kinematics of 2D robot arm"
function fwd_2d_linkage(nlinks::Integer)
  inp_names = [Symbol(:ϕ_, i) for i=1:nlinks]
  carr = CompArrow(:fwd_kin, inp_names, [:x, :y])
  angles = in_sub_ports(carr)
  curr_angle = first(angles)
  sum_angles = [curr_angle]
  for i = 2:nlinks
    addarr = add_sub_arr!(carr, AddArrow())
    link_ports!(curr_angle, (addarr, 1))
    link_ports!(angles[i], (addarr, 2))
    curr_angle = out_sub_port(addarr, 1)
    push!(sum_angles, curr_angle)
  end

  total_sin = add_sub_arr!(carr, addn(length(sum_angles)))
  for (i, angle) in enumerate(sum_angles)
    sinarr = add_sub_arr!(carr, SinArrow())
    link_ports!(angle, (sinarr, 1))
    link_ports!((sinarr, 1), (total_sin, i))
  end

  total_cos = add_sub_arr!(carr, addn(length(sum_angles)))
  for (i, angle) in enumerate(sum_angles)
    cosarr = add_sub_arr!(carr, CosArrow())
    link_ports!(angle, (cosarr, 1))
    link_ports!((cosarr, 1), (total_cos, i))
  end

  x, y = out_sub_ports(carr)
  link_ports!((total_sin, 1), x)
  link_ports!((total_cos, 1), y)
  carr
end

"Forward kinematics of 2D robot arm"
function fwd_2d_linkage_obs(nlinks::Integer)
  inp_names = [Symbol(:ϕ_, i) for i=1:nlinks]
  carr = CompArrow(:fwd_kin, inp_names, [:x, :y])
  angles = in_sub_ports(carr)
  curr_angle = first(angles)
  sum_angles = [curr_angle]
  for i = 2:nlinks
    addarr = add_sub_arr!(carr, AddArrow())
    link_ports!(curr_angle, (addarr, 1))
    link_ports!(angles[i], (addarr, 2))
    curr_angle = out_sub_port(addarr, 1)
    push!(sum_angles, curr_angle)
  end

  total_sin = add_sub_arr!(carr, Arrows.addn_accum_linke(length(sum_angles)))
  for (i, angle) in enumerate(sum_angles)
    sinarr = add_sub_arr!(carr, SinArrow())
    link_ports!(angle, (sinarr, 1))
    link_ports!((sinarr, 1), (total_sin, i))
  end

  midsumxs = out_sub_ports(total_sin)[2:end]

  total_cos = add_sub_arr!(carr, Arrows.addn_accum_linke(length(sum_angles)))
  for (i, angle) in enumerate(sum_angles)
    cosarr = add_sub_arr!(carr, CosArrow())
    link_ports!(angle, (cosarr, 1))
    link_ports!((cosarr, 1), (total_cos, i))
  end

  midsumys = out_sub_ports(total_cos)[2:end]

  @show midsumys, midsumxs

  x, y = out_sub_ports(carr)
  link_ports!((total_sin, 1), x)
  link_ports!((total_cos, 1), y)

  ## Assert constraints
  points = Matrix{SubPort}(2, nlinks)
  for i = 1:length(midsumxs)
    points[1, i] = midsumxs[i]
    points[2, i] = midsumys[i]
  end
  obstacles = [Circle([5.0, 5.0], 1.0)]
  constraint = validpath(points, obstacles)

  carr
end

arr = fwd_2d_linkage_obs(2)
invarr = Arrows.approx_invert(arr)
num_in_ports(invarr)
invarr(1.0, 1.0, rand(18)...)


adds = filter(sarr -> isa(Arrows.deref(sarr), CompArrow), Arrows.sub_arrows(arr))
map(Arrows.is_src_source, in_sub_ports(adds[2]))

Arrows.consadds[1]
1+1
## Drawing ##
"Draw a circle"
function draw(c::Circle)
  sethue("black")
  circle(Luxor.Point(c.center...), c.r, :fill)
end

"Draw the target at `x, y`"
function drawtarget(x, y)
  p1 = Luxor.Point(x, y)
  sethue("red")
  circle(p1, 0.1, :fill)
end

"Draw the path"
function drawpath(points)
  setline(3)
  curr = O
  for i = 1:size(points, 2)
    color = randomhue()
    sethue(color)
    x, y = points[1, i], points[2, i]
    point = Luxor.Point(x, y)
    line(curr, point, :stroke)
    curr = point
  end
end

"Draw all the obstacles"
drawobstacles(obstacles) = foreach(draw, obstacles)

"Draw the path, target and obstacles"
function drawscene(points, obstacles, x, y)
  Drawing(1000, 1000, "scenes.png")
  origin()
  scale(50.0, 50.0)
  background("white")

  drawpath(points)
  drawobstacles(obstacles)
  drawtarget(x, y)

  finish()
  preview()
end
