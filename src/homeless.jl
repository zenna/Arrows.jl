# Little functions without a home

"Comp"
arrsinside(arr::Arrow) = Set(simpletracewalk(Arrows.name ∘ deref, arr))

# testpi(fwd::Arrow, invarrow)

"nnet-enhanced parametric inverse of `fwd`"
function netpi(fwd::Arrow, nmabv::XAbValues)
  sprtabv = SprtAbValues(⬨(fwd, nm) => abv for (nm, abv) in nmabv)
  invcarr = invert(fwd, inv, sprtabv)
  traceprop!(invcarr, nmabv)
end


function isintabv(tabv::TraceAbValues, arr::Arrow)
  [tval in keys(tabv) for tval in in_trace_values(TraceSubArrow(arr))]
end
