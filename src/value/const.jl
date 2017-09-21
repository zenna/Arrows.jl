"Const specifies whether a given value is constant or not"
abstract type Const end
struct IsConst <: Const end
struct NotConst <: Const end
const isconst = IsConst()
const notconst = NotConst()
