"A 3 point vector"
Vec3{T} = Vector{T}
Point{T} = Vector{T}

"A ray with origin `orig` and "
struct Ray{T}
  orig::Vec3{T}
  dir::Vec3{T}
end

"A sphere"
struct Sphere{T}
  center::Point{T} # position of center the sphere
  radius::T     # radius of sphere
  surface_color::Vec3{T}  # color of surface
  reflection::T
  transparency::T
  emission_color::T
end

"Result of intersection between ray and object"
struct Intersection{T}
  doesintersect::T
  t0::T
  t1::T
end

"Linear interpolation between `a` and `b` by factor `mix`"
mix(a, b, mix::AbstractFloat) = b * mix + a * (1 - mix)

"norm(x)^2"
dot_self(x) = dot(x, x)

"normalized x: `x/norm(x)`"
normalize(x::Vector) = x / sqrt(dot_self(x))

function rayintersect(r::Ray, s::Sphere)::Intersection
  l = s.center - r.orig
  tca = dot(l, r.dir)
  radius2 = s.radius^2

  if tca < 0
    return Intersection(tca, 0.0, 0.0)
  end

  d2 = dot(l, l) - tca * tca
  if d2 > radius2
    return Intersect(radius - d2, 0.0, 0.0)
  end

  thc = sqrt(radius2 - d2)
  t0 = tca - thc
  t1 = tca + thc
  Intersection(radius2 - d2, t0, t1)
end


function trace(r::Ray, spheres::Vector{Sphere}, depth::Integer)
  tnear = Inf
  areintersections = false
  for sphere in spheres
    inter = rayintersect(r, sphere)
    if inter.doesintersect > 0
    end
  end

  # If no sphere, then output 1,
end

function render(spheres::Vector{Spehere}, width::Integer. height::Integer,
                fov::AbstractFloat)
  inv_width = 1 / width
  inv_height = 1 / height
  aspect_ratio = width / height
  angle = tan(pi * 0.5 * fov / 100.0)
  image = zeros(width, height)
end

"Render an example scene and display it"
function example()
