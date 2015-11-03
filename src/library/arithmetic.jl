## Primitive Tensor Functions
## ==========================

const arith_dimtype = @dimtype [n, n] [n]
const a = @shape a [x_i for i = 1:n]
"a:{x_i for i = 1:n}, a:{x_i for i = 1:n} >> a:{x_i for i = 1:n}"
const arith_typ = @arrtype2 arith_dimtype [a, a] [a]

"Class of arrows for primitive unary arithmetic operations"
immutable ArithArrow <: PrimArrow{2, 1}
  name::Symbol
end

dimtyp(x::ArithArrow) = arith_dimtype
typ(x::ArithArrow) = arith_typ
name(a::ArithArrow) = a.name

## Primitive Arithmetic Arrows
## ===========================

const addarr = ArithArrow(:+)
const minusarr = ArithArrow(:-)
const divsarr = ArithArrow(:/)
const mularr = ArithArrow(:*)
const powarr = ArithArrow(:^)
const logarr = ArithArrow(:log)

export addarr, minusarr, divsarr, mularr, powarr, logarr

## Unary Binary operations
## =======================

"Unary arithmetic arrow - partially applied ArithArrow"
immutable UnaryArithArrow{T} <: PrimArrow{1, 1}
  name::Symbol
  value::T
  isnumfirst::Bool # is the number first, .e.g f(x) = (+)(3,x) => true
end
