"Is port `i` known to be constant (may be constant but we cant infer it)"
function isconst(i::Integer, idabv::IdAbVals)::Bool
  if i ∈ keys(idabv)
    if :value in keys(idabv[i])
      return true
    elseif :isconst in keys(idabv[i]) && idabv[i][:isconst]
      return true
    end
  end
  false
end

function const_in(arr::Arrow, idabv::IdAbVals)::Vector{Bool}
  [isconst(pid, idabv) for pid in port_id.(▸(arr))]
end

"Constant Propagation"
function constprop(arr::Arrow, idabv::IdAbVals)::IdAbVals
  if all([isconst(pid, idabv) for pid in port_id.(▸(arr))])
    IdAbVals(pid => AbVals(:isconst => true) for pid in port_id.(◂(arr)))
  else
    IdAbVals()
  end
end
