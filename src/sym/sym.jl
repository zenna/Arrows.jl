import SymPy: Sym, symbols, Eq, Ne, SympyTRUE

"Refined Symbol {x | pred}"
struct RefnSym
  var::Sym
  preds::Set{Sym} # Conjunction of predicates
end

"Unconstrained Symbol"
RefnSym(sym::Sym) = RefnSym(sym, Set{Sym}())

prim_sym_interpret{N}(::InvDuplArrow{N}, xs::Vararg{Sym, N})::Vector{Sym} =
  [first(xs)]

function domainpreds{N}(::InvDuplArrow{N}, xs::Vararg{Sym, N})
  preds = Set{Sym}()
  x1 = first(xs)
  for (i, x) in enumerate(xs)
    if i > 1
      push!(preds, Eq(x, x1))
    end
  end
  preds
end

function sym_interpret(x::SourceArrow, args)::Vector{RefnSym}
  @show args
  @show typeof(args)
  [RefnSym(Sym(x.value))]
end

prim_sym_interpret(::SubtractArrow, x, y)::Vector{Sym} = [x - y,]
prim_sym_interpret(::MulArrow, x, y)::Vector{Sym} = [x * y,]
prim_sym_interpret(::AddArrow, x, y)::Vector{Sym} = [x + y,]
prim_sym_interpret(::DivArrow, x, y)::Vector{Sym} = [x / y,]
# SymPy doesnt support it
# domainpreds(::DivArrow, x, y) = Set{Sym}([Ne(y, 0)])
domainpreds(::Arrow, args...) = Set{Sym}()

function sym_interpret(parr::PrimArrow, args::Vector{RefnSym})::Vector{RefnSym}
  vars = Sym[arg.var for arg in args]
  preds = Set{Sym}[arg.preds for arg in args]
  @show preds
  outputs = prim_sym_interpret(parr, vars...)
  dompreds = domainpreds(parr, vars...)
  allpreds = union(dompreds, preds...)
  map(var -> RefnSym(var, allpreds), outputs)
end

sym_interpret(sarr::SubArrow, args) = sym_interpret(deref(sarr), args)

function Sym(prps::Props)
  # TODO: Add Type assumption
  symbols(string(name(prps)))
end

Sym(prt::Port) = symbols("x$(prt.port_id)")
RefnSym(prt::Port) = RefnSym(Sym(prt))

# Recurse
sym_interpret(carr::CompArrow, args) =
  interpret(sym_interpret, carr, args)

"Constraints on inputs to `carr`"
function constraints(carr::CompArrow, remove=[SympyTRUE])
  inp = map(RefnSym, ▸(carr))
  outs = interpret(sym_interpret, carr, inp)
  allpreds = Set{Sym}()
  foreach(out -> union!(allpreds, out.preds), outs)
  filter(pred -> pred ∉ remove, allpreds)
end
