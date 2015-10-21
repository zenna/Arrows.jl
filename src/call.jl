## Call: apply an arrow to some input
## =================================
"Compiles the arrow `a` and applies it to input `x`"
function lambda{I,O}(a::Arrow{I,O}; compilation_target = Arrows.Theano.TheanoFunc)
  imperative_arrow = Arrows.compile(Arrows.NamedArrow(:unnamed, a))
  convert(compilation_target, imperative_arrow[1])
end

"Compiles the arrow `a` and applies it to input `x`"
function call{I,O}(a::Arrow{I,O}, x...; args...)
  @assert length(x) == I "Tried to call arrow of $I inputs with $(length(x)) inputs"
  compiled_f = lambda(a; args...)
  compiled_f(x...)
end
