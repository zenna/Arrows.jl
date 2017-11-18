"Failure to meet (intersect) different values of type `T`"
struct MeetError{T} <: Exception
  vals::Vector{T}
end

Base.showerror(io::IO, e::MeetError) = print(io, "Could not meet: ", e.vals)

"Meet of a single value is identity"
meet(val) = val

"Meet three+, assumes that `meet(val1::T, val::T)` is defined for T"
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
