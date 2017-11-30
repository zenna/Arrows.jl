"Wrapper for data passed between nodes"
struct Singleton{T}
  value::T
end

"All arrows can do constant propagation and value propagation"
abinterprets(::Arrow) = [valueprop, constprop]

function meet(x::Bool, y::Bool)
  x == y || throw(MeetError, [x, y])
end

function meet(x::Singleton, y::Singleton)
  x == y || throw(MeetError, [x, y])
  x
end

function valueprop(arr::Arrow, idabv::IdAbValues)::IdAbValues
  # Does every _inport_ have the property
  if allhave(idabv, :value, ▸(arr)...)
    # args = [prop[:value] for prop in values(idabv)]
    args = [idabv[prt.port_id][:value].value for (i, prt) in enumerate(▸(arr))]
    res = interpret(arr, args...)
    cres = Singleton.(res)
    IdAbValues(prt.port_id => AbValues(:value => cres[i]) for (i, prt) in enumerate(◂(arr)))
  else
    IdAbValues()
  end
end
