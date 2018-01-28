"Duplicates input `O` times dupl_n_(x) = (x,...x)"
struct DuplArrow{O} <: PrimArrow end

props(::DuplArrow{O}) where O=
  [Props(true, :x, Any),
   [Props(false, Symbol(:y, i), Any) for i=1:O]...]

name(::DuplArrow{O}) where O = Symbol(:dupl_, O)
DuplArrow(n::Integer) = DuplArrow{n}()
abinterprets(::DuplArrow) = [sizeprop]

function constprop(arr::DuplArrow, idabv::IdAbVals)::IdAbVals
  # If any re constant all are constant!
  if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
    # @assert false
    IdAbVals(pid => AbVals(:isconst => true) for pid in port_id.(◂(arr)))
  else
    IdAbVals()
  end
end

# FIXME: implement valueprop for dupl

function inv(arr::DuplArrow{O}, sarr::SubArrow, idabv::IdAbVals) where O
  if any([isconst(pid, idabv) for pid in port_id.(⬧(arr))])
    DuplArrow(O), Dict(i => i for i=1:O + 1)
  else
    (InvDuplArrow(O), merge(Dict(1 => O + 1), Dict(i => i - 1 for i = 2:O+1)))
  end
end

"`(x, x, ..., x)` `n` times"
dupl(x, n)::Tuple = tuple((x for i = 1:n)...)

"f(x) = (x,)"
struct IdentityArrow <: PrimArrow end

props(::IdentityArrow) =
  [Props(true, :x, Any), Props(false, :y, Any)]

name(::IdentityArrow) = :identity
