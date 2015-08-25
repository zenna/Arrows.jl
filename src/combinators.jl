"Lifts a primitive function to an arrow"
lift{I,O}(a::PrimFunc{I,O}) = PrimArrow{I,O}(a.typ, a)

"Wire outputs of `a` to inputs of `b`, i.e. a_out_1 --> b_in_1, a_out_2 --> b_in_1"
function compose{I1, O1I2, O2}(a::CompositeArrow{I1,O1I2}, b::CompositeArrow{O1I2,O2})
  c = CompositeArrow{I1,O2}()
  addnodes!(c, nodes(a))
  addnodes!(c, nodes(b))

  new_edges = Dict{Port, Port}()
  idshift = nnodes(a)

  for (p1, p2) in edges(a)
    @show p1, p2
    # if p2 is an output boundary and p1 not input boundary
    # if p1 is an input boundary and p2 is output |---------------|
    # |     |*****|-----------|
    if isboundary(p2)
      p3 = b.edges[Port(1,relativepinid(a, p2.pin))]
      addedge!(c, p1, isboundary(p3) ? Port(1, I1 + relativepinid(b, p3.pin)) : Port(p3.arrow + idshift, p3.pin))

    # inner edge
    # |------|*****|        |
    # |        |*****|------|*****|        |
    else
      addedge!(c, p1, p2)
    end
  end

  for (p1, p2) in edges(b)


    if !isboundary(p1)
      addedge!(c, Port(p1.arrow + idshift, p1.pin),
                  isboundary(p2) ? Port(1, I1 + relativepinid(b, p2.pin)) : Port(p2.arrow + idshift, p2.pin))
    end
  end
  @assert iswellformed(c)
  c
end

compose(a::PrimArrow, b::CompositeArrow) = compose(encapsulate(a), b)
compose(a::CompositeArrow, b::PrimArrow) = compose(a, encapsulate(b))
compose(a::PrimArrow, b::PrimArrow) = compose(encapsulate(a), encapsulate(b))

>>>(a::Arrow, b::Arrow) = compose(a, b)

"""Takes two inputs side by side. The first one is modified using an arrow `a`,
  while the second is left unchanged."""
function first(a::CompositeArrow{1,1})
  c = CompositeArrow{2, 2}()
  addnodes!(c, nodes(a))

  for (p1, p2) in edges(a)
    # If the edge is going to output, then readjust for new inputs/outputs
    if isboundary(p2)
      addedge!(c, p1, Port(1,3))
    else
      addedge!(c, p1, p2)
    end
  end

  addedge!(c, Port(1,2), Port(1,4))
  @assert iswellformed(c)
  c
end

"Union two composite arrows into the same arrow"
function stack{I1, O1, I2, O2}(a::CompositeArrow{I1,O1}, b::CompositeArrow{I2,O2})
  c = CompositeArrow{I1 + I2, O1 + O2}()
  addnodes!(c, nodes(a))
  addnodes!(c, nodes(b))
  for (p1, p2) in edges(a)
    if isboundary(p2)
      addedge!(c, p1, Port(1, I2 + p2.pin))
    else
      addedge!(c, p1, p2)
    end
  end

  idshift = nnodes(a)
  for (p1, p2) in edges(b)
    addedge!(c, isboundary(p1) ? Port(1, p1.pin + I1) : Port(p1.arrow + idshift, p1.pin),
                isboundary(p2) ? Port(1, p2.pin + I1 + O1) : Port(p2.arrow + idshift, p2.pin))

  end
  @assert iswellformed(c)
  c
end

first(a::PrimArrow) = first(encapsulate(a))
multiplex{I,O}(a::CompositeArrow{I,O}, b::CompositeArrow{I,O}) = lift(clonefunc) >>> stack(a,b)
