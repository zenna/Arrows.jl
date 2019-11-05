# Traits
isscalar(::PrimArrow) = false
isscalar(::Type{<:PrimArrow}) = Val{false}

"x + y"
struct AddArrow <: PrimArrow end
name(::AddArrow)::Symbol = :+
lift(::typeof(+)) = AddArrow()

"x - y"
struct SubtractArrow <: PrimArrow end
name(::SubtractArrow)::Symbol = :-
lift(::typeof(-)) = SubtractArrow()

"x / y"
struct DivArrow <: PrimArrow end
name(::DivArrow)::Symbol = :/
lift(::typeof(/)) = DivArrow()

"x * y"
struct MulArrow <: PrimArrow end
name(::MulArrow)::Symbol = :*
lift(::typeof(*)) = MulArrow()

"exp(x)"
struct ExpArrow <: PrimArrow end
name(::ExpArrow)::Symbol = :exp
lift(::typeof(exp)) = ExpArrow()

"log(x)"
struct LogArrow <: PrimArrow end
name(::LogArrow)::Symbol = :log

"log(b, x)"
struct LogBaseArrow <: PrimArrow end
name(::LogBaseArrow)::Symbol = :logbase

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

sqr(x) = x^2

"abs(x)"
struct AbsArrow <: PrimArrow end
name(::AbsArrow)::Symbol = :abs

"x^y"
struct PowArrow <: PrimArrow end
name(::PowArrow)::Symbol = :^

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

"div(x, y) Integer division"
struct IntDivArrow <: PrimArrow end
name(::IntDivArrow)::Symbol = :div

"div(x, y) Integer multiplication"
struct IntMulArrow <: PrimArrow end
name(::IntMulArrow)::Symbol = :mul_arr

function mul_arr(x::AbstractPort, y::AbstractPort)
  IntMulArrow()(x, y)
end

mul_arr(x::Int, y::Int) = x * y

"ceil(x)"
struct CeilArrow <: PrimArrow end
name(::CeilArrow)::Symbol = :ceil

"floor(x)"
struct FloorArrow <: PrimArrow end
name(::FloorArrow)::Symbol = :floor

# Unions
ArithArrow = Union{AddArrow,
                  SubtractArrow,
                  DivArrow,
                  IntDivArrow,
                  IntMulArrow,
                  MulArrow,
                  ExpArrow,
                  LogArrow,
                  LogBaseArrow,
                  ASinArrow,
                  SinArrow,
                  CosArrow,
                  ACosArrow,
                  SqrtArrow,
                  SqrArrow,
                  AbsArrow,
                  PowArrow,
                  NegArrow,
                  MinArrow,
                  MaxArrow,
                  ModArrow,
                  CeilArrow,
                  FloorArrow}


abinterprets(::ArithArrow) = [sizeprop]
isscalar(::Type{<:ArithArrow}) = Val{true}
isscalar(::ArithArrow) = true

to_unary_functions = [ExpArrow, LogArrow, ASinArrow, SinArrow,
                      CosArrow, ACosArrow, SqrtArrow, SqrArrow,
                      AbsArrow, LogBaseArrow, NegArrow, CeilArrow,
                      FloorArrow]
to_binary_functions = [AddArrow, DivArrow, SubtractArrow, IntMulArrow,
                      MulArrow, MinArrow, MaxArrow, ModArrow, PowArrow,
                      IntDivArrow]
ArrowMod.props(::Union{to_unary_functions...}) = unary_arith_props()
ArrowMod.props(::Union{to_binary_functions...}) = bin_arith_props()

# function expander_prop(prop_generator, typ)
#   quote
#     props(::$(typ)) = $(prop_generator())
#   end
# end

# codes_unary = map(f -> expander_prop(unary_arith_props, f), to_unary_functions)
# codes_binary = map(f -> expander_prop(bin_arith_props, f), to_binary_functions)
# foreach(eval, vcat(codes_unary, codes_binary))

