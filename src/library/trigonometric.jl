## Primitive Trigonometric Arrows
## ==============================

const trig_typ = ArrowType{1,1}([ArrayType(:N)], [ArrayType(:N)],[])

"Class of arrows for primitive binary arithmetic operations, + / + ^"
immutable TrigArrow <: PrimArrow{1, 1}
  name::Symbol
end

typ(x::TrigArrow) = arith_typ
name(x::TrigArrow) = x.name

## Primitive Arithmetic Arrows
## ===========================

const exparr = TrigArrow(:exp)
const logarr = TrigArrow(:log)
const sinarr = TrigArrow(:sin)
const cosarr = TrigArrow(:cos)
const tanarr = TrigArrow(:tan)
const asinarr = TrigArrow(:asin)
const acosarr = TrigArrow(:acos)
const atanarr = TrigArrow(:atan)
const sinharr = TrigArrow(:sinh)
const cosharr = TrigArrow(:cosh)
const tanharr = TrigArrow(:tanh)
const atan2arr = TrigArrow(:atan2)
const sqrtarr = TrigArrow(:sqrt)

name(a::TrigArrow) = a.name

export exparr
export logarr
export sinarr
export cosarr
export tanarr
export asinarr
export acosarr
export atanarr
export sinharr
export cosharr
export tanharr
export atan2arr
export sqrtarr
