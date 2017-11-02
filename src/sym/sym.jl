SymUnion = Union{Expr, Array, Number, Symbol}


"Refined Symbol {x | pred}"
struct RefnSym
  var::SymUnion
  preds::Set{} # Conjunction of predicates
end

"Unconstrained Symbol"
RefnSym(sym::SymUnion) = RefnSym(sym, Set{SymUnion}())

function Sym(prps::Props)
  # TODO: Add Type assumption
  ustring = string(name(prps))
  Symbol(ustring)
end
Sym(prt::Port) = Sym(props(prt))
RefnSym(prt::Port) = RefnSym(Sym(prt))


domainpreds(::Arrow, args...) = Set{SymUnion}()
function domainpreds{N}(::InvDuplArrow{N}, xs::Vararg{SymUnion, N})
  x1 = first(xs)
  f = x-> :($(x) == $(x1))
  Set{SymUnion}(map(f, xs[2:end]))
end

+(x::SymUnion, y::SymUnion) = :($(x) + $(y))
-(x::SymUnion, y::SymUnion) = :($(x) - $(y))
/(x::SymUnion, y::SymUnion) = :($(x) / $(y))
*(x::SymUnion, y::SymUnion) = :($(x) * $(y))

prim_sym_interpret(::SubtractArrow, x, y) = [x .- y,]
prim_sym_interpret(::MulArrow, x, y) = [x .* y,]
prim_sym_interpret(::AddArrow, x, y) = [x .+ y,]
prim_sym_interpret(::DivArrow, x, y) = [x ./ y,]
prim_sym_interpret(::LogArrow, x) = [log.(x),]
function prim_sym_interpret{N}(::InvDuplArrow{N},
                                xs::Vararg{SymUnion, N})::Vector{SymUnion}
  [first(xs)]
end


function sym_interpret(parr::PrimArrow, args::Vector{RefnSym})::Vector
  vars = [arg.var for arg in args]
  preds = Set[arg.preds for arg in args]
  @show outputs = prim_sym_interpret(parr, vars...)
  @show dompreds = domainpreds(parr, vars...)
  @show allpreds = union(dompreds, preds...)
  map(var -> RefnSym(var, allpreds), outputs)
end


sym_interpret(sarr::SubArrow, args) = sym_interpret(deref(sarr), args)
sym_interpret(carr::CompArrow, args) =
  interpret(sym_interpret, carr, args)
