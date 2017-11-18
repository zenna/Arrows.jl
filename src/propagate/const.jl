"Is port `i` known to be constant (may be constant but we cant infer it)"
function isconst(i::Integer, idabv::IdAbValues)::Bool
  if i ∈ keys(idabv)
    if :value in keys(idabv[i])
      return true
    elseif :isconst in keys(idabv[i]) && idabv[i][:isconst]
      return true
    end
  end
  false
end

function const_in(arr::Arrow, idabv::IdAbValues)::Vector{Bool}
  [isconst(pid, idabv) for pid in port_id.(▸(arr))]
end

"Constant Propagation"
function constprop(arr::Arrow, idabv::IdAbValues)::IdAbValues
  if all([isconst(pid, idabv) for pid in port_id.(▸(arr))])
    IdAbValues(pid => AbValues(:isconst => true) for pid in port_id.(◂(arr)))
  else
    IdAbValues()
  end
end
