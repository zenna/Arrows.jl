"Testing and specification"
module Spec

"""
Short circuit implication predicate
"""
macro →(a, b)
  quote
    if $a
      $b
    else
      true
    end
  end
end


include("src/pre.jl")      # preconditions

export @pre,
       @with_pre,
       @invariant

end
