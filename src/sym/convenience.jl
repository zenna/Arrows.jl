# Some functions for dealing with symbolic execution conveniently
# remove/reorder when sym.jl is restructured

"Derive all symbolic constraints on domain of `arr`"
function all_constraints(arr::Arrow, initprop::XAbValues = SprtAbValues())
  outs = sym_interpret_all(arr, initprop)
  union_constraints(outs)
end

"Union constraints from all the outputs of `sym_interpret_all`"
union_constraints(xs::Vector{Arrows.RefnSym}) = union([x.preds for x in xs]...)

"Symbolic Interpretation of `arr` to derive constraints"
function sym_interpret_all(arr::Arrow, initprop::XAbValues = SprtAbValues())
  info = Arrows.ConstraintInfo()
  Arrows.symbol_in_ports!(arr, info, initprop)
  interpret(Arrows.sym_interpret, arr, info.inp)
end
