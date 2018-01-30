# Overload julia functions #
# import TakingBroadcastSeriously: @unfuse, broadcast_
# @unfuse SubPort

promote_constant(carr::CompArrow, sprt::SubPort) = sprt
function promote_constant(carr::CompArrow, x)
  sarr = add_sub_arr!(carr, SourceArrow(x))
  ◃(sarr, 1)
end

function inner(ArrType, xs::Vararg{SubPort})
  xs = map(src, xs)
  # xs = map(x -> promote_constant(carr, x), xs)
  carr = anyparent(xs...)
  sarr = add_sub_arr!(carr, ArrType())
  length(xs) == num_in_ports(deref(sarr)) || throw(DomainError())
  for (i, x) in enumerate(xs)
    link_ports!(x, (sarr, i))
  end
  output = ◃(sarr)
  if length(output) == 1
    output[1]
  else
    output
  end
end

":(xi)"
x_i(i) = Symbol(:x, i)

"xi::typ"
typ_x_i(i, typ) = Expr(:(::), x_i(i), typ)

"bit ? xi : x_i::typname"
inner_sigf(i, bit, typ) = bit ? x_i(i) : typ_x_i(i, typ)

"fname(x1, x2::typ, x3 ..."
sigf(fname, n, typ, smang) =
  Expr(:call, fname, map((i, bit) -> inner_sigf(i, bit, typ), 1:n, smang)...)

bodyf(i, bit) = bit ? :(promote_constant(parr, $(x_i(i)))) : x_i(i)

"Code Generation for Overloading"
function codegen_2(n::Integer, typ::Symbol, fname::Symbol, parrtyp::DataType)
  exprs = Expr[]
  sig = sigf(fname, n, typ, [false for i = 1:n])
  Expr(:function, sig, :(inner($parrtyp, $(x_i.(1:n)...))))
end

"Code Generation for Overloading"
function overload_codegen(n::Integer, typ::Symbol, fname::Symbol)
  exprs = Expr[]
  # Iterate through bitstrings of length n which have alteast one True, False
  for smang in Iterators.filter(allin_f((true, false)), product(Bool, n))
    sig = sigf(fname, n, typ, smang)
    body = Expr(:call, fname, map(bodyf, 1:n, smang)...)
    parr = :(parr = anyparent($(x_i.(find(.!(smang)))...)))
    block = Expr(:block, parr, body)
    expr = Expr(:function, sig, block)
    push!(exprs, expr)
  end
  exprs
end

# FIXME: functions on subports should only work if
# The values are src ndoes, if dst throw error or
# find its soruce
const ignoretyp = Set([DuplArrow,
                       SourceArrow,
                       CondArrow,
                       InvDuplArrow,
                       FirstArrow,
                       EqualArrow,
                       MeanArrow,
                       VarArrow,
                       ReduceVarArrow,
                       ReduceMeanArrow,
                       UnknownArrow,
                       ReduceSumArrow,
                       CatArrow,
                       InvCatArrow,
                       IntToOneHot,
                       OneHotToInt])
for parrtyp in filter(arrtyp -> arrtyp ∉ ignoretyp, subtypes(PrimArrow))
  arr = parrtyp()
  opa = name(arr)
  foreach(eval, overload_codegen(num_in_ports(arr), :SubPort, opa))
  eval(codegen_2(num_in_ports(arr), :SubPort, opa, parrtyp))
  # Generates code like:
  # +(x::SubPort, y) = +(x, promote_constant(parent(x), y))
  # +(x, y::SubPort) = +(promote_constant(parent(y), x), y)
  # +(x::SubPort, y::SubPort) = inner($parrtyp, x, y)
end
