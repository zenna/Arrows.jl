"This file contains the pgfs of primitive arrows."

# FIXME: at the moment all of the pgfs are manually constructed.
# at least want to just add the parameter part to the arrow and
# not have to construct the arrow along with the parameter.

function pgf(arr::MulArrow)
  "As f^(-1)(z; θ) = (z/θ, θ), then the pgf becomes r(x, y) = (x*y, y)."
  carr = CompArrow(Symbol(:pgf_, :mul), [:x, :y], [:z, :θmul])
  x, y, z, θ = sub_ports(carr)
  x * y ⥅ z
  y ⥅ θ
  carr
end

function pgf(arr::AddArrow)
  "As f^(-1)(z; θ) = (z-θ, θ), then the pgf becomes r(x, y) = (x+y, y)."
  carr = CompArrow(Symbol(:pgf_, :add), [:x, :y], [:z, :θadd])
  x, y, z, θ = sub_ports(carr)
  x + y ⥅ z
  y ⥅ θ
  carr
end

function pgf(arr::SubtractArrow)
  "As f^(-1)(z; θ) = (z+θ, θ), then the pgf becomes r(x, y) = (x-y, y)."
  carr = CompArrow(Symbol(:pgf_, :sub), [:x, :y], [:z, :θsub])
  x, y, z, θ = sub_ports(carr)
  x - y ⥅ z
  y ⥅ θ
  carr
end

function pgf(arr::SinArrow)
  "As f^(-1)(y; θ) = , then the pgf becomes "
  # carr = CompArrow(Symbol(:pgf_, :sin), [:x], [:y, :θsin])
  # x, y, θ = sub_ports(carr)
  # sinarr = add_sub_arr!(carr, SinArrow())
  # link_ports!(x, (sinarr, 1))
  # link_ports!((sinarr, 1), y)
  # zero = add_sub_arr!(carr, SourceArrow(0))
  # link_ports!((zero, 1), θ)
  # carr
  newarr = deepcopy(arr)
  newarr
end

function pgf(arr::CosArrow)
  "As f^(-1)(y; θ) = 2πθ + (-1)^θ * acos(y), then the pgf becomes "
  # carr = CompArrow(Symbol(:pgf_, :cos), [:x], [:y, :θcos])
  # x, y, θ = sub_ports(carr)
  # cosarr = add_sub_arr!(carr, CosArrow())
  # link_ports!(x, (cosarr, 1))
  # link_ports!((cosarr, 1), y)
  # zero = add_sub_arr!(carr, SourceArrow(0))
  # link_ports!((zero, 1), θ)
  # carr
  newarr = deepcopy(arr)
  newarr
end

function pgf(arr::SourceArrow)
  "The parametric inverse of SourceArrow has no parameters, so return the same arrow renamed."
  newarr = deepcopy(arr)
  #rename!(newarr, Symbol(:pgf_, :source))
  newarr
end

function pgf(arr::IdentityArrow)
  "The parametric inverse of IdentityArrow has no parameters, so return the same arrow renamed."
  newarr = deepcopy(arr)
  #rename!(newarr, Symbol(:pgf_, :identity))
  newarr
end

function pgf(arr::LessThanArrow)
  "As f^(-1)(z; θ1, θ2) = (θ1, [θ1+θ2, θ1-θ2]^z), then the pgf becomes r(x, y) = (x<y, x, abs(x-y))."
  carr = CompArrow(Symbol(:pgf_, :lessthan), [:x, :y], [:z, :θ1, :θ2])
  x, y, z, θ1, θ2 = sub_ports(carr)
  abs = add_sub_arr!(carr, AbsArrow())
  x < y ⥅ z
  x ⥅ θ1
  x - y ⥅ (abs, 1)
  link_ports!((abs, 2), θ2)
  carr
end
