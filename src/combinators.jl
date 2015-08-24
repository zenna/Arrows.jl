"Lifts a primitive function to an arrow"
lift{I,O}(a::PrimFunc{I,O}) = PrimArrow{I,O}(a.typ, a)

"Wire outputs of `a` to inputs of `b`, i.e. a_out_1 --> b_in_1, a_out_2 --> b_in_1"
function compose{I1, O1I2, O2}(a::CompositeArrow{I1,O1I2}, b::CompositeArrow{O1I2,O2})
  c = CompositeArrow{I1,O2}()
  addnodes!(c, nodes(a))
  addnodes!(c, nodes(b))

  new_edges = Dict{Port, Port}()
  for (p1, p2) in edges(a)
    @show p1, p2
    # if p2 is an output boundary and p1 not input boundary
    # if p1 is an input boundary and p2 is output |---------------|
    # |     |*****|-----------|
    if isboundary(p2)
      p3 = b.edges[Port(1,relativepinid(a, p2.pin))]
      addedge!(c, p1, shift(p3, a))

    # inner edge
    # |------|*****|        |
    # |        |*****|------|*****|        |
    else
      addedge!(c, p1, p2)
    end
  end

  println("outputs\n")

  for (p1, p2) in edges(b)
    if !isboundary(p1)
      # Shift
      @show p1, p2
      @show shift(p1, a)
      @show shift(p2, a)
      addedge!(c, shift(p1, a), shift(p2, a))
    end
  end
  @assert iswellformed(c)
  c
end


compose(a::PrimArrow, b::CompositeArrow) = compose(encapsulate(a), b)
compose(a::CompositeArrow, b::PrimArrow) = compose(a, encapsulate(b))
compose(a::PrimArrow, b::PrimArrow) = compose(encapsulate(a), encapsulate(b))

"""Takes two inputs side by side. The first one is modified using an arrow `a`,
  while the second is left unchanged."""
function first(a::Arrow{1,1})
  c = CompositeArrow{2, 1}()

  addnodes!(c, nodes(a))

  ## Add inner edges from a and b (where they exist)
  addedges!(c, inneredges(a))

  in_a = ingateports(a)
  @assert length(in_a) == 1

  out_a = outgateports(a)
  @assert length(out_a) == 1

  # Connet compposite input ot content input
  addedge!(c, Port(1, 1), in_a)

  # Connet compposite input ot content input
  addedge!(c, out_a, Port(1, 3))

  # Connect the pass-through edge
  addedge!(c, Port(1, 2), Port(2, 4))
  return c
end
