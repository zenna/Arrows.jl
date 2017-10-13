"Const specifies whether a given value is constant or not"
abstract type Const end
struct IsConst <: Const end
struct NotConst <: Const end
const known_const = IsConst()
const known_not_const = NotConst()
