orig = [0, 0, 6.1]
r = 5.0
dir = [1.0, 1.0, -1.0]
dir = dir/norm(dir)

norma(x) = x / norm(x)

plot(d->minta(norma([1.0, 1.0, d]), orig, r), -10, 10)

function disttocirc(t, dir, orig, r)
  newpos = orig + dir * t
  @show norm(newpos) - r
end

function mints(dir, orig)
  a = dot(dir, dir)
  dirorig = dot(dir, orig)
  b = 2*dirorig
  c = dirorig^2
  inner = b^2 - 4*a*c
  [-b + inner/2a, -b - inner/2a]
end

function mintty(dir, orig, r)
  d_o = dot(dir, orig)
  o_o = dot(orig, orig)
  d_d = dot(dir, dir)
  inner = 2d_o - 4(d_d * o_o - r)
  [-2d_o - inner / (2d_d), -2d_o + inner / (2d_d)]
end

function deriv(t, dir, orig, r)
  dx = dir[1]
  dy = dir[2]
  dz = dir[3]
  ox = orig[1]
  oy = orig[2]
  oz = orig[3]
  (2dx*(ox + dx*t) + 2dy*(oy + dy*t) + 2dz*(oz + dz*t))*(-r +
     sqrt((ox + dx*t)^2 + (oy + dy*t)^2 + (oz + dz*t)^2))/(sqrt((ox +
      dx*t)^2 + (oy + dy*t)^2 + (oz + dz*t)^2))
end

function minta(d, o, r)
  d_d = dot(d, d)
  d_o = dot(d, o)
  o_o = dot(o, o)
  # Roots to cubic equation
  a = d_d
  b = 2*d_o
  c = dot(o,o) - r^2
  inner = b^2 - 4*a*c
  # Does not intersect
  t = if inner < 0
    max(0,-d_o / d_d)
  else
    inters = [(-b + sqrt(inner))/2a, (-b - sqrt(inner))/2a]
    if inters[1] < 0 && inters[2] < 0
      0
    elseif inters[1] < 0
      inters[2]
    elseif inters[2] < 0
      inters[1]
    else
      min(inters[1], inters[2])
    end
  end
  newpos = t*d + o
  sdf = dot(newpos, newpos) - r
  [t, sdf]
end

function minta2(dir, orig, r)
  dx = dir[1]
  dy = dir[2]
  dz = dir[3]
  ox = orig[1]
  oy = orig[2]
  oz = orig[3]
  b = 2*dx*ox + 2*dy*oy + 2*dz*oz
  a = dx^2 + dy^2 + dz^2
  @show c = ox^2 + oy^2 + oz^2 - r^2
  @show last = (-dx*ox - dy*oy - dz*oz)/(dx^2 + dy^2 + dz^2)
  second = (-2*dx*ox - 2*dy*oy - 2*dz*oz - sqrt((2*dx*ox + 2*dy*oy + 2*dz*oz)^2 - 4*(dx^2 + dy^2 + dz^2)*(ox^2 + oy^2 + oz^2 - r^2)))/
          (2*(dx^2 + dy^2 + dz^2))
  [last, second]
end
plot([t->(disttocirc(t, dir, orig, r))], -10, 10)
