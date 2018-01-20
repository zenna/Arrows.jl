## Domain Predicates

"If inputs satisfy `domainpred`icates then then `arr` is well defined on them"
domainpreds(::Arrow, args...) = Set{SymUnion}() # by default assume no constraints

function domainpreds{N}(::InvDuplArrow{N}, x1::SymUnion, xs::Vararg)
  # All inputs to invdupl must be equal
  symbols = map(xs) do x
    :($(x.value) == $(x1.value))
  end
  Set{SymUnion}(SymUnion.(symbols))
end

function domainpreds(::InvDuplArrow, x1::Array, xs::Vararg)
  answer = Array{SymUnion, 1}()
  for x in xs
    for (left, right) in zip(x1, x)
      e = :($(left.value) == $(right.value))
      push!(answer, SymUnion(e))
    end
  end
  Set{SymUnion}(answer)
end

## Primitive Symbolc Interpretation

# Zen: What is this?
var(xs::Array{SymUnion}) = SymUnion(:())

function ifelse(i::SymUnion, t::SymUnion, e::SymUnion)
  SymUnion(:(ifelse($(i.value), $( t.value), $(e.value))))
end

# Zen: what is thi?
"[:a, :b, :c] -> `name([:a, :b, :c])`"
function s_arrayed(xs::Array{SymUnion}, name::Symbol)
  @show values = [x.value for x in xs]
  @show SymUnion(:($(name)($(values))))
  @assert false
end

s_mean(xs::Array{SymUnion}) = s_arrayed(xs, :mean)
function s_var(xs::Vararg{<:Array})
  map(xs |> first |> eachindex) do iter
    s_arrayed([x[iter] for x in xs], :var)
  end
end


"Generic Symbolic Interpret of `parr`"
function prim_sym_interpret(parr::PrimArrow, args::SymUnion...)::Vector{SymUnion}
  @show typeof(args)
  @assert num_out_ports(parr) == 1
  ex = [SymUnion(Expr(:call, name(parr), args...)),]
end

prim_sym_interpret(::BroadcastArrow, x::SymUnion)::Vector{SymUnion} = [x,]

function prim_sym_interpret{N}(::DuplArrow{N}, x::SymUnion)
  [x  for _ in 1:N]
end

prim_sym_interpret(::IfElseArrow, i::SymUnion, t::SymUnion, e::SymUnion) =
  [ifelse.(i, t, e)]

function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg{SymUnion, N})::Vector{SymUnion}
  ## XXX: What are the consequences of just taking the first?
  [first(xs)]
end

function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg)::Vector{SymUnion}
  [xs |> first |> sym_unsym,]
end

function  prim_sym_interpret(::Arrows.ReshapeArrow,
                              data::Array{Arrows.SymUnion,2},
                              shape::Array{Arrows.SymUnion,1})
  data = as_expr(data)
  shape = as_expr(shape)
  [SymUnion(reshape(data, shape)),]

end

function prim_sym_interpret(::ScatterNdArrow, z, indices, shape)
  indices = as_expr(indices)
  shape = as_expr(shape)
  z = sym_unsym(z)
  arrayed_sym = prim_scatter_nd(SymbolProxy(z), indices, shape,
                          SymPlaceHolder())
  [sym_unsym(arrayed_sym),]
end

function prim_sym_interpret{N}(::ReduceVarArrow{N}, xs::Vararg)
  [s_arrayed([sym_unsym(x) for x in xs], :reduce_var),]
end

function prim_sym_interpret{N}(::MeanArrow{N}, xs::Vararg)
  [s_arrayed([sym_unsym(x) for x in xs], :mean),]
end

function  prim_sym_interpret(::Arrows.ReshapeArrow, data::Arrows.SymUnion,
                            shape)
  shape = sym_unsym(shape)
  expr = :(reshape($(data.value), $(shape.value)))
  [SymUnion(expr),]
end
