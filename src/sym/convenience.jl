# Some functions for dealing with symbolic execution conveniently
# remove/reorder when sym.jl is restructured

"Derive all symbolic constraints on domain of `arr`"
function all_constraints(arr::Arrow, initprop::XAbVals = SprtAbVals())
  outs = sym_interpret_all(arr, initprop)
  union_constraints(outs)
end

"Union constraints from all the outputs of `sym_interpret_all`"
union_constraints(xs::Vector{RefinedSym}) = union([x.preds for x in xs]...)

"Symbolic Interpretation of `arr` to derive constraints"
function sym_interpret_all(arr::Arrow, initprop::XAbVals = SprtAbVals())
  info = ConstraintInfo()
  symbol_in_ports!(arr, info, initprop)
  interpret(sym_interpret, arr, info.inp)
end
