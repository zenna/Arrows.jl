## Domain Predicates

"If inputs satisfy `domainpred`icates then then `arr` is well defined on them"
domainpreds(::Arrow, args...) = Set{SymbolicType}() # by default assume no constraints

function domainpreds{N}(::InvDuplArrow{N}, x1::SymbolicType, xs::Vararg)
  # All inputs to invdupl must be equal
  symbols = map(xs) do x
    :($(x) == $(x1))
  end
  Set{SymbolicType}(symbols)
end

"""each element of the first array must be equal to each element of each of the
other arrays"""
function domainpreds(::InvDuplArrow, x1::Array, xs::Vararg)
  answer = Array{SymbolicType, 1}()
  for x in xs
    for (left, right) in zip(x1, x)
      e = :($(left) == $(right))
      push!(answer, e)
    end
  end
  Set{SymbolicType}(answer)
end

## Primitive Symbolc Interpretation

# Zen: What is this?
var(xs::Array{SymUnion}) = SymUnion(:())

# function ifelse(i::SymbolicType, t::SymbolicType, e::SymbolicType)
#   :(ifelse($(i), $(t), $(e)))
# end

# Zen: what is thi?
"[:a, :b, :c] -> `name([:a, :b, :c])`"
function s_arrayed(xs::Array{SymUnion}, name::Symbol)
  @show values = [x.value for x in xs]
  @assert false
end

s_mean(xs::Array{SymUnion}) = s_arrayed(xs, :mean)
function s_var(xs::Vararg{<:Array})
  map(xs |> first |> eachindex) do iter
    s_arrayed([x[iter] for x in xs], :var)
  end
end


"Generic Symbolic Interpret of `parr`"
function prim_sym_interpret(parr::PrimArrow, args::SymbolicType...)::Vector{SymbolicType}
  @show typeof(args)
  @show parr
  @assert num_out_ports(parr) == 1
  ## TODO: only for scalars
  @show :asdfaafsd
  f = (function_args...)-> Expr(:call, name(parr), function_args...)
  @show f.(args...)
  ex = [f.(args...),]
end

prim_sym_interpret(::BroadcastArrow, x::SymbolicType)::Vector{SymbolicType} = [x,]

function prim_sym_interpret{N}(::DuplArrow{N}, x::SymbolicType)
  [x  for _ in 1:N]
end

# prim_sym_interpret(::IfElseArrow, i::SymbolicType, t::SymbolicType,
#                    e::SymbolicType) =
#   [ifelse.(i, t, e)]

function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg{SymbolicType, N})::Vector{SymbolicType}
  ## XXX: What are the consequences of just taking the first?
  [first(xs)]
end

function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg)::Vector{SymbolicType}
  [xs |> first,]
end

function  prim_sym_interpret(::Arrows.ReshapeArrow,
                              data::Array{SymbolicType,2},
                              shape::Array{SymbolicType,1})
  [reshape(data, shape),]
end

function  prim_sym_interpret(::Arrows.ReshapeArrow, data::SymbolicType,
                            shape::SymbolicType)
  shape = sym_unsym(shape)
  expr = :(reshape($(data), $(shape)))
  [expr,]
end

function prim_sym_interpret(::ScatterNdArrow, z, indices, shape)
  arrayed_sym = prim_scatter_nd(SymbolProxy(z), indices, shape,
                          SymPlaceHolder())
  [arrayed_sym,]
end

function prim_sym_interpret{N}(::ReduceVarArrow{N}, xs::Vararg)
  [s_arrayed([sym_unsym(x) for x in xs], :reduce_var),]
end

function prim_sym_interpret{N}(::MeanArrow{N}, xs::Vararg)
  [s_arrayed([sym_unsym(x) for x in xs], :mean),]
end
