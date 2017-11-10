## PureSymbolic = Union{Expr, Symbol}
##SymUnion = Union{PureSymbolic, Array, Tuple, Number}
mutable struct SymUnion
  value
  hsh::UInt
end
token_name = :τᵗᵒᵏᵉⁿ
SymUnion(value) = SymUnion(value, hash(value))
SymPlaceHolder() = SymUnion(token_name)
hash(x::SymUnion, h) = hash(x.hsh, h)

"Refined Symbol {x | pred}"
struct RefnSym
  var::SymUnion
  preds::Set{} # Conjunction of predicates
end

struct SymbolPrx
  var::SymUnion
end

getindex(s::SymbolPrx, i::Int) = SymUnion(Expr(:ref, s.var.value, i))

"Unconstrained Symbol"
RefnSym(sym::SymUnion) = RefnSym(sym, Set{SymUnion}())

function Sym(prps::Props)
  # TODO: Add Type assumption
  ustring = string(name(prps))
  SymUnion(Symbol(ustring))
end
Sym(prt::Port) = Sym(props(prt))
RefnSym(prt::Port) = RefnSym(Sym(prt))


domainpreds(::Arrow, args...) = Set{SymUnion}()
# function domainpreds{N}(::InvDuplArrow{N}, xs::Vararg{SymUnion, N})
#   x1 = first(xs)
#   f = x-> :($(x) == $(x1))
#   Set{SymUnion}(map(f, xs[2:end]))
# end

function domainpreds(::InvDuplArrow, x1::Array,
                        xs::Vararg)
  answer = Array{SymUnion, 1}()
  for x in xs
    for (left, right) in zip(x1, x)
      e = :($(left.value) == $(right.value))
      push!(answer, SymUnion(e))
    end
  end
  @show answer[end]
  @show length(answer)
  Set{SymUnion}(answer)
end


+(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) + $(y.value)))
-(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) - $(y.value)))
/(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) / $(y.value)))
*(x::SymUnion, y::SymUnion) = SymUnion(:($(x.value) * $(y.value)))
log(x::SymUnion)::SymUnion = SymUnion(:(log($(x.value))))
neg(x::SymUnion)::SymUnion = SymUnion(:(-$(x.value)))
var(xs::Array{SymUnion}) = SymUnion(:())

function s_arrayed(xs::Array{SymUnion}, name)
  values = [x.value for x in xs]
  SymUnion(:($(name)($(values))))
end
s_mean(xs::Array{SymUnion}) = s_arrayed(xs, :mean)
function s_var(xs::Vararg{<:Array})
  x1 = xs[1]
  answer = Array()
  f = iter-> s_arrayed([x[iter] for x in xs], :var)
  [f(iter) for iter in eachindex(x1)]
end


prim_sym_interpret(::SubtractArrow, x, y) = [x .- y,]
prim_sym_interpret(::MulArrow, x, y) = [x .* y,]
prim_sym_interpret(::AddArrow, x, y) = [x .+ y,]
prim_sym_interpret(::DivArrow, x, y) = [x ./ y,]
prim_sym_interpret(::LogArrow, x) = [log.(x),]
prim_sym_interpret(::NegArrow, x) = [neg.(x),]
prim_sym_interpret{N}(::DuplArrow{N}, x) = [x  for _ in 1:N]
function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg{SymUnion, N})::Vector{SymUnion}
  [first(xs)]
end

function prim_sym_interpret(::ScatterNdArrow, z, indices, shape)
  arrayed_sym = prim_scatter_nd(SymbolPrx(z), indices.value, shape.value,
                          SymPlaceHolder())
  expr = map(sym->sym.value, arrayed_sym)
  [SymUnion(expr),]
end

function prim_sym_interpret{N}(::ReduceVarArrow{N}, xs::Vararg{SymUnion, N})
  [s_arrayed([xs...], :reduce_var),]
end

function prim_sym_interpret{N}(::MeanArrow{N}, xs::Vararg{SymUnion, N})
  [s_arrayed([xs...], :mean),]
end

function  prim_sym_interpret(::Arrows.ReshapeArrow, data::Arrows.SymUnion,
                            shape::Arrows.SymUnion)
  expr = :(reshape($(data.value), $(shape.value)))
  [SymUnion(expr),]
end

function sym_interpret(x::SourceArrow, args)::Vector{RefnSym}
  @show args
  @show typeof(args)
  @show typeof(x.value)
  [RefnSym(SymUnion(x.value))]
end


function sym_interpret(parr::PrimArrow, args::Vector{RefnSym})::Vector
  vars = [arg.var for arg in args]
  preds = Set[arg.preds for arg in args]
  outputs = prim_sym_interpret(parr, vars...)
  dompreds = domainpreds(parr, vars...)
  allpreds = union(dompreds, preds...)
  f = var -> RefnSym(var, allpreds)
  if length(outputs) > 0 && isa(outputs[1], Array)
    answer = Array{Any, ndims(outputs)}(size(outputs)...)
    for iter in eachindex(outputs)
      answer[iter] = map(f, outputs[iter])
    end
  else
    answer = map(f, outputs)
  end
  answer
end


sym_interpret(sarr::SubArrow, args) = sym_interpret(deref(sarr), args)
sym_interpret(carr::CompArrow, args) =
  interpret(sym_interpret, carr, args)
