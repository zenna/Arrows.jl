"Mean"
struct MeanArrow{I} <: PrimArrow end
props{I}(::MeanArrow{I}) =
  [[Props(true, Symbol(:x, i), Any) for i=1:I]...,
    Props(false, :y, Any)]

name(::MeanArrow) = :mean
MeanArrow(n::Integer) = MeanArrow{n}()
mean(args...) = sum(args)/length(args)

"Variance"
struct VarArrow{I} <: PrimArrow end
name(::VarArrow) = :var
VarArrow(n::Integer) = VarArrow{n}()
props{I}(::VarArrow{I}) =
  [[Props(true, Symbol(:x, i), Any) for i=1:I]...,
    Props(false, :y, Any)]
var(args::Vararg{SubPort}) = var([args...])
var(xs::Vararg{<:Real}) = var(xs)


struct ReduceVarArrow{I} <: PrimArrow end
name(::ReduceVarArrow) = :reduce_var
ReduceVarArrow(n::Integer) = ReduceVarArrow{n}()
props{I}(::ReduceVarArrow{I}) =
  [[Props(true, Symbol(:x, i), Any) for i=1:I]...,
    Props(false, :y, Any)]

# FIXME `reduce_var` and `var` dont handle combinations of ports and numbers 
reduce_var(args::Vararg{SubPort}) = var([args...])
reduce_var(xs::Vararg{<:Real}) = var(xs)
