# Order alphabetically
"x + y"
struct AddArrow <: PrimArrow end
name(::AddArrow)::Symbol = :+
props(::AddArrow) = bin_arith_props()

"x / y"
struct DivArrow <: PrimArrow end
name(::DivArrow)::Symbol = :/
props(::DivArrow) = bin_arith_props()

"x - y"
struct SubtractArrow <: PrimArrow end
name(::SubtractArrow)::Symbol = :-
props(::SubtractArrow) = bin_arith_props()

"x * y"
struct MulArrow <: PrimArrow end
name(::MulArrow)::Symbol = :*
props(::MulArrow) = bin_arith_props()


"exp(x)"
struct ExpArrow <: PrimArrow end
name(::ExpArrow)::Symbol = :exp
props(::ExpArrow) = unary_arith_props()

"log(x)"
struct LogArrow <: PrimArrow end
name(::LogArrow)::Symbol = :log
props(::LogArrow) = unary_arith_props()

"asin(x)"
struct ASinArrow <: PrimArrow end
name(::ASinArrow)::Symbol = :asin
props(::ASinArrow) = unary_arith_props()
domain_bounds(::ASinArrow) = [-1, 1]

"sin(x)"
struct SinArrow <: PrimArrow end
name(::SinArrow)::Symbol = :sin
props(::SinArrow) = unary_arith_props()

"cos(x)"
struct CosArrow <: PrimArrow end
name(::CosArrow)::Symbol = :cos
props(::CosArrow) = unary_arith_props()

"acos(x)"
struct ACosArrow <: PrimArrow end
name(::ACosArrow)::Symbol = :acos
props(::ACosArrow) = unary_arith_props()
domain_bounds(::ACosArrow) = [-1, 1]

"sqrt(x)"
struct SqrtArrow <: PrimArrow end
name(::SqrtArrow)::Symbol = :sqrt
props(::SqrtArrow) = unary_arith_props()

"sqr(x)"
struct SqrArrow <: PrimArrow end
name(::SqrArrow)::Symbol = :sqr
props(::SqrArrow) = unary_arith_props()

"abs(x)"
struct AbsArrow <: PrimArrow end
name(::AbsArrow)::Symbol = :abs
props(::AbsArrow) = unary_arith_props()

sqr(x) = (x^2,)

"log(b, x)"
struct LogBaseArrow <: PrimArrow end
name(::LogBaseArrow)::Symbol = :logbase
props(::LogBaseArrow) = unary_arith_props()

"-x"
struct NegArrow <: PrimArrow end
name(::NegArrow)::Symbol = :-
props(::NegArrow) = unary_arith_props()

"min(x, y)"
struct MinArrow <: PrimArrow end
name(::MinArrow)::Symbol = :min
props(::MinArrow) = bin_arith_props()

"max(x, y)"
struct MaxArrow <: PrimArrow end
name(::MaxArrow)::Symbol = :max
props(::MaxArrow) = bin_arith_props()

"x % y"
struct ModArrow <: PrimArrow end
name(::ModArrow)::Symbol = :%
props(::ModArrow) = bin_arith_props()
