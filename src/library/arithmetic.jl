# Order alphabetically
"x + y"
struct AddArrow <: PrimArrow end
name(::AddArrow)::Symbol = :+

"x / y"
struct DivArrow <: PrimArrow end
name(::DivArrow)::Symbol = :/

"x - y"
struct SubtractArrow <: PrimArrow end
name(::SubtractArrow)::Symbol = :-

"x * y"
struct MulArrow <: PrimArrow end
name(::MulArrow)::Symbol = :*


"exp(x)"
struct ExpArrow <: PrimArrow end
name(::ExpArrow)::Symbol = :exp

"log(x)"
struct LogArrow <: PrimArrow end
name(::LogArrow)::Symbol = :log

"asin(x)"
struct ASinArrow <: PrimArrow end
name(::ASinArrow)::Symbol = :asin
domain_bounds(::ASinArrow) = [-1, 1]

"sin(x)"
struct SinArrow <: PrimArrow end
name(::SinArrow)::Symbol = :sin

"cos(x)"
struct CosArrow <: PrimArrow end
name(::CosArrow)::Symbol = :cos

"acos(x)"
struct ACosArrow <: PrimArrow end
name(::ACosArrow)::Symbol = :acos
domain_bounds(::ACosArrow) = [-1, 1]

"sqrt(x)"
struct SqrtArrow <: PrimArrow end
name(::SqrtArrow)::Symbol = :sqrt

"sqr(x)"
struct SqrArrow <: PrimArrow end
name(::SqrArrow)::Symbol = :sqr

"abs(x)"
struct AbsArrow <: PrimArrow end
name(::AbsArrow)::Symbol = :abs

sqr(x) = x^2

"log(b, x)"
struct LogBaseArrow <: PrimArrow end
name(::LogBaseArrow)::Symbol = :logbase

"-x"
struct NegArrow <: PrimArrow end
name(::NegArrow)::Symbol = :-

"min(x, y)"
struct MinArrow <: PrimArrow end
name(::MinArrow)::Symbol = :min

"max(x, y)"
struct MaxArrow <: PrimArrow end
name(::MaxArrow)::Symbol = :max

"x % y"
struct ModArrow <: PrimArrow end
name(::ModArrow)::Symbol = :%

"ceil(x)"
struct CeilArrow <: PrimArrow end
name(::CeilArrow)::Symbol = :ceil

"floor(x)"
struct FloorArrow <: PrimArrow end
name(::FloorArrow)::Symbol = :floor

function expander_prop(prop_generator, typ)
  quote
    props(::$(typ)) = $(prop_generator())
  end
end


to_unary_functions = [ExpArrow, LogArrow, ASinArrow, SinArrow,
                      CosArrow, ACosArrow, SqrtArrow, SqrArrow,
                      AbsArrow, LogBaseArrow, NegArrow, CeilArrow,
                      FloorArrow,]
to_binary_functions = [AddArrow, DivArrow, SubtractArrow,
                      MulArrow, MinArrow, MaxArrow, ModArrow]
codes_unary = map(f -> expander_prop(unary_arith_props, f), to_unary_functions)
codes_binary = map(f -> expander_prop(bin_arith_props, f), to_binary_functions)
foreach(eval, vcat(codes_unary, codes_binary))
