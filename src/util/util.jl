module Util
import LightGraphs; const LG = LightGraphs
using Spec

export splitdim,
       same,
       finditems,
       hasduplicates,
       uniquename,
       partition,
       cell_membership,
       switch,
       rev,
       conjoin,
       ∧,
       ∨,
       pred_conjunct,
       disjoin,
       accumapply,
       product,
       firstparam,
       invvcat,
       splitdim,
       splat,
       curly,
       parens,
       square,
       uid,
       same,
       allin_f

include("misc.jl")             # miscelleneous utilities
include("lightgraphs.jl")      # methods that should be in LightGraphs
end