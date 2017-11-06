meet(val) = val

function meet{T}(val1::T, val2::T, val3::T, vals::T...)
  allvals = (val1, val2, val3, vals...)
  mostprecise = val1
  for val in allvals[2:end]
    mostprecise = meet(mostprecise, val)
  end
  mostprecise
end

function meetall(oldprops, props...)
  merge(meet, oldprops, props...)
end
