import SymPy: Sym
using SymPy

"Refined Symbol {x | pred}"
struct RefnSym
  var::Sym
  preds::Set{Sym} # Conjunction of predicates
end

"Unconstrained Symbol"
RefnSym(sym::Sym) = RefnSym(sym, Set{Sym}())

sym_interpret{N}(::InvDuplArrow{N}, xs::Vararg{Sym, N}) = [first(xs)]
function domainpreds{N}(::InvDuplArrow{N}, xs::Vararg{Sym, N})
  preds = Set{Sym}()
  x1 = first(xs)
  for x in xs
    push!(preds, Eq(x1, xs))
  end
  preds
end

sym_interpret(::SubtractArrow, x, y) = [x - y,]
sym_interpret(::MulArrow, x, y) = [x * y,]
sym_interpret(::AddArrow, x, y) = [x + y,]
sym_interpret(::DivArrow, x, y) = [x / y,]
domainpreds(::DivArrow, x, y) = Set{Sym}([Ne(y, 0)])
domainpreds(::Arrow, args...) = Set{Sym}()

function sym_interpret(parr::PrimArrow, args::Vector{RefnSym})
  @show parr
  vars = [arg.var for arg in args]
  preds = [arg.preds for arg in args]
  outputs = sym_interpret(parr, vars...)
  dompreds = domainpreds(parr, vars...)
  allpreds = union(dompreds, preds...)
  map(var -> RefnSym(var, allpreds), outputs)
end

sym_interpret(sarr::SubArrow, args) = sym_interpret(deref(sarr), args)

function Sym(prps::Props)
  # TODO: Add Type assumption
  symbols(string(name(prps)))
end

Sym(prt::Port) = Sym(props(prt))
RefnSym(prt::Port) = RefnSym(Sym(prt))

# Recurse
sym_interpret(carr::CompArrow, args) =
  interpret(sym_interpret, carr, args)
