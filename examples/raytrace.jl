## Normal Ray Tracing

# immutable Vec
#   x::Float64
#   y::Float64
#   z::Float64
# end
module RayTrace
  # Global Defs
  const MAX_RAY_DEPTH = 5

  # Utility Functions
  "Linearly interpolate between `a` and `b`"
  mix(a::Float64, b::Float64, mix::Float64) = b * mix + a * (1 - mix)

  typealias Vec Vector{Float64}
  Vec3(x::Float64) = Float64[x,x,x]
  Vec3(x::Float64, y::Float64, z::Float64) = Float64[x,y,z]

  typealias Point Vec

  "Normalize a vector so that its length is 1.0"
  normalize(x::Vec) = (factor = 1/norm(x); x*factor)

  "Parameteric Ray.  r(t) = o + td   0 ≤ t ≤ ∞"
  immutable Ray
    orig::Point
    dir::Vec
  end

  ## Geometry
  immutable Sphere
    center::Point             # position of the sphere
    radius::Float64           # radius
    surface_color::Vec        # surfae colour
    reflection::Float64
    transparency::Float64
    emission_color::Vec       # light
  end

  "Compute a ray-sphere intersection using the geometric solution"
  function rayintersect(r::Ray, s::Sphere)
    # println("Corrupted here?")
    # @show r
    l = s.center - r.orig
    tca = dot(l, r.dir)
    if (tca < 0)
      return (false, -Inf, -Inf)
    end
    d2 = dot(l,l) - tca * tca
    if (d2 > s.radius^2)
      return (false, -Inf, -Inf)
    end
    # println("What about here?")
    # @show r

    thc = sqrt(s.radius^2 - d2)
    t0 = tca - thc
    t1 = tca + thc

    return (true, t0, t1)
  end

  function trace(
      r::Ray,
      spheres::Vector{Sphere},
      depth::Int)

    areintersections = false
    tnear = Inf
    sphere = spheres[1]
    # println("NEWSPHERES\n\n\n\n")
    for s in spheres
      # @show depth
      doesintersect, t0, t1 = rayintersect(r, s)
      areintersections = areintersections || doesintersect
      !doesintersect && continue
      if t0 < 0
        t0 = t1
      end
      if t0 < tnear
        tnear = t0
        sphere = s
      end
    end

    # @show depth
    # @show areintersections
    # @show sphere

    !areintersections && return Vec3(0.0)

    # println("Go!")

    surface_color = Vec3(0.0)        # color of the ray/surfaceof the object intersected by the ray
    phit = r.orig + r.dir * tnear # point of intersection
    # @show r.orig, r.dir, tnear
    nhit = phit - sphere.center   # normal at the intersection point
    nhit = normalize(nhit)        # normalize normal direction

    # If the normal and the view direction are not opposite to each other
    # reverse the normal direction. That also means we are inside the sphere so set
    # the inside bool to true. Finally reverse the sign of IdotN which we want
    # positive.
    bias = 1e-4; # add some bias to the point from which we will be tracing
    inside = false
    if dot(r.dir, nhit) > 0
      nhit = -nhit
      inside = true
    end

    if (sphere.transparency > 0 || sphere.reflection > 0) && depth < MAX_RAY_DEPTH
      facingratio = dot(-r.dir, nhit)
      # change the mix value to tweak the effect
      fresneleffect = mix((1 - facingratio)^3, 1.0, 0.1)
      # @show facingratio, fresneleffect, -r.dir, nhit
      # compute reflection direction (not need to normalize because all vectors
      # are already normalized)
      refldir = r.dir - nhit * 2 * dot(r.dir,nhit)
      refldir = normalize(refldir)
      reflection = trace(Ray(phit + nhit * bias, refldir), spheres, depth + 1)
      refraction = Vec3(0.0)
      # if the sphere is also transparent compute refraction ray (transmission)
      # if sphere.transparency >= 0
      #   float ior = 1.1, eta = (inside) ? ior : 1 / ior; # are we inside or outside the surface?
      #   float cosi = -nhit.dot(r.dir);
      #   float k = 1 - eta * eta * (1 - cosi * cosi);
      #   Vec3f refrdir = r.dir * eta + nhit * (eta *  cosi - sqrt(k));
      #   refrdir.normalize();
      #   refraction = trace(phit - nhit * bias, refrdir, spheres, depth + 1);
      # end

      # the result is a mix of reflection and refraction (if the sphere is transparent)
      @assert !any(isnan, sphere.surface_color)
      @assert !any(isnan, reflection)
      @assert !any(isnan, refraction)
      @assert !isnan(fresneleffect)
      @assert !isnan(sphere.transparency)

      surface_color = (reflection * fresneleffect +
        refraction * (1 - fresneleffect) * sphere.transparency) .* sphere.surface_color
    else
      # it's a diffuse object, no need to raytrace any further
      for i = 1:length(spheres)
        if spheres[i].emission_color[1] > 0
          # this is a light
          transmission = 1.0
          lightDirection = spheres[i].center - phit
          lightDirection = normalize(lightDirection)

          for j = 1:length(spheres)
            if i != j
              # error("Here's an error")
              doesintersect, t0, t1 = rayintersect(Ray(phit + nhit * bias, lightDirection), spheres[j])
              if doesintersect
                transmission = 0
                break
              end
            end
          end
          @assert !any(isnan, sphere.surface_color)
          @assert !any(isnan, transmission)
          @assert !any(isnan, max(0.0, dot(nhit, lightDirection)))
          @assert !any(isnan, spheres[i].emission_color)

          surface_color += sphere.surface_color * transmission *
            max(0.0, dot(nhit, lightDirection)) .* spheres[i].emission_color
          @assert !any(isnan, surface_color)

        end
      end
    end
    @assert !any(isnan, sphere.emission_color)
    @assert !any(isnan, surface_color)


    # check(surface_color)
    # check(sphere.emission_color)
    return surface_color + sphere.emission_color
  end

  "Render a Vector of Spheres"
  function render(spheres::Vector{Sphere})
    width = 640
    height = 480
    image = Array(Vec, width, height)
    invWidth = 1 / Float64(width)
    invHeight = 1 / Float64(height)
    fov = 30.0
    aspectratio = width / Float64(height)
    angle = tan(pi * 0.5 * fov / 180.)

    # Trace rays
    for y = 1:height, x = 1:width
      xx = (2 * ((x + 0.5) * invWidth) - 1) * angle * aspectratio
      yy = (1 - 2 * ((y + 0.5) * invHeight)) * angle
      raydir = Vec3(xx, yy, -1.0)
      raydir = normalize(raydir)
      @show y, x
      primaryray = Ray(Vec3(0.0), raydir)
      image[x,y] = trace(primaryray, spheres, 0)
    end

    image
  end

  #     // Save result to a PPM image (keep these flags if you compile under Windows)
  #     std::ofstream ofs("./untitled.ppm", std::ios::out | std::ios::binary);
  #     ofs << "P6\n" << width << " " << height << "\n255\n";
  #     for (unsigned i = 0; i < width * height; ++i) {
  #         ofs << (unsigned char)(std::min(float(1), image[i].x) * 255) <<
  #                (unsigned char)(std::min(float(1), image[i].y) * 255) <<
  #                (unsigned char)(std::min(float(1), image[i].z) * 255);
  #     }
  #     ofs.close();
  #     delete [] image;
  # }

  function main()
    spheres = Sphere[]
    # position, radius, surface color, reflectivity, transparency, emission color
    push!(spheres,Sphere(Vec3( 0.0, -10004., -20.), 10000., Vec3(0.20, 0.20, 0.20), 0., 0.0, Vec3(0.0)))
    push!(spheres,Sphere(Vec3( 0.0,      0., -20.),     4., Vec3(1.00, 0.32, 0.36), 1., 0.5, Vec3(0.0)))
    push!(spheres,Sphere(Vec3( 5.0,     -1., -15.),     2., Vec3(0.90, 0.76, 0.46), 1., 0.0, Vec3(0.0)))
    push!(spheres,Sphere(Vec3( 5.0,      0., -25.),     3., Vec3(0.65, 0.77, 0.97), 1., 0.0, Vec3(0.0)))
    push!(spheres,Sphere(Vec3(-5.5,      0., -15.),     3., Vec3(0.90, 0.90, 0.90), 1., 0.0, Vec3(0.0)))
    # light
    push!(spheres,Sphere(Vec3( 0.0,     20., -30.),     3., Vec3(0.00, 0.00, 0.00), 0., 0.0, Vec3(3.)))
    render(spheres)
  end
end

using ImageView
op  = RayTrace.main()
view(map(sum, op))
