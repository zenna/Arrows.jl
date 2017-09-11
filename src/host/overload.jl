promote_constant(carr::CompArrow, sport::SubPort) = sport
function promote_constant(carr::CompArrow, x::Number)
  sarr = add_sub_arr!(carr, SourceArrow(x))
  out_sub_port(sarr, 1)
end

function inner(ArrType, xs::Vararg{SubPort})
  # xs = map(x -> promote_constant(carr, x), xs)
  carr = anyparent(xs...)
  sarr = add_sub_arr!(carr, ArrType())
  length(xs) == num_in_ports(deref(sarr)) || throw(DomainError())
  for (i, x) in enumerate(xs)
    link_ports!(x, (sarr, i))
  end
  output = out_sub_ports(sarr)
  if length(output) == 1
    output[1]
  else
    output
  end
end

const ignoretyp = Set([DuplArrow,
                      SourceArrow,
                      ClipArrow,
                      CondArrow,
                      InvDuplArrow,
                      EqualArrow,
                      MeanArrow])
for parrtyp in filter(arrtyp -> arrtyp ∉ ignoretyp, subtypes(PrimArrow))
  opa = name(parrtyp())
  # @show arrowname = Symbol(parrtyp)
  eval(
  quote
  ($opa)(xs::Vararg{SubPort}) = inner($parrtyp, xs...)
  ($opa)(x::SubPort, y) = ($opa)(x, promote_constant(parent(x), y))
  ($opa)(x, y::SubPort) = ($opa)(promote_constant(parent(y), x), y)
  ($opa)(x::SubPort, y::SubPort) = inner($parrtyp, x, y)
  end)
end

# 1 + 1

# @show Arrows.MulArrow
# ```
# for Typ in subtypes(MyType)
#   typname = Symbol(Typ)
#   eval(
#   quote
#   function f(x)
#     x = $typname()
#   end
#   end)
# end
# ```
