"Mean"
struct MeanArrow{I} <: PrimArrow end
port_props{I}(::MeanArrow{I}) =
  [[PortProps(true, Symbol(:x, i), Any) for i=1:I]...,
    PortProps(false, :y, Any)]

name(::MeanArrow) = :mean
MeanArrow(n::Integer) = MeanArrow{n}()
mean(args...) = sum(args)/length(args)

"Variance"
struct VarArrow{I} <: PrimArrow end
name(::VarArrow) = :var
port_props{I}(::VarArrow{I}) =
  [[PortProps(true, Symbol(:x, i), Any) for i=1:I]...,
    PortProps(false, :y, Any)]
var(args...) = var([args...])
