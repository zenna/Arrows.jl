# "Lifts a primitive function to an arrow"
# lift{I,O}(a::PrimFunc{I,O}) = PrimArrow{I,O}(a.typ, a)

"Wrap primitive arrow in composite arrow - behaves identically to original arrow"
function encapsulate{I,O}(a::PrimArrow{I,O})
  c = CompositeArrow{I,O}()
  addnodes!(c, [a])
  for i = 1:I
    addedge!(c, OutPort(1, i), InPort(2, i))
  end

  for i = 1:O
    addedge!(c, OutPort(2, i), InPort(1, i))
  end
  @assert iswellformed(c)
  c
end

"Increment the arrowid of a port by `offset`. Usful when combining arrows, where some arrowids need to be offset"
offsetarrowid{P <: Port}(p::P, offset::ArrowId) = P(p.arrowid + offset, p.pinid)

"Offset only if it is a boundary port"
safeoffsetarrowid(p::Port, offset::ArrowId) =
  isboundary(p) ? p : offsetarrowid(p, offset)

"Wire outputs of `a` to inputs of `b`, i.e. a_out_1 --> b_in_1, a_out_2 --> b_in_1"
function compose{I1, O1I2, O2}(a::CompositeArrow{I1,O1I2}, b::CompositeArrow{O1I2,O2})
  c = CompositeArrow{I1,O2}()
  addnodes!(c, nodes(a))
  addnodes!(c, nodes(b))

  arrowidoffset = nnodes(a)

  for (outp, inp) in Arrows.edges(a)
    # @show outp, inp
    # if p2 is an output boundary and p1 not input boundary
    # if p1 is an input boundary and p2 is output |---------------|
    # |     |*****|-----------|
    if Arrows.isboundary(inp)
      p3 = b.edges[nthinneroutport(b, inp.pinid)]
      p3shifted = safeoffsetarrowid(p3, arrowidoffset)
      # @show p3, p3shifted
      Arrows.addedge!(c, outp, p3shifted)

    # inner edge
    # |------|*****|        |
    # |        |*****|------|*****|        |
    else
      Arrows.addedge!(c, outp, inp)
    end
  end

  for (outp, inp) in Arrows.edges(b)
    # @show outp, inp
    # inputs will already be connected from loop above
    if !Arrows.isboundary(outp)
      Arrows.addedge!(c, Arrows.safeoffsetarrowid(outp, arrowidoffset), Arrows.safeoffsetarrowid(inp, arrowidoffset))
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
  addedges!(c, edges(a))
  addedge!(c, OutPort(1,2), InPort(1,2))
  @assert iswellformed(c)
  c
end

"Place `a` over an identity wire.  Like `first` but for multiple in/out puts"
function over{I,O}(a::CompositeArrow{I,O})
  c = CompositeArrow{I+1, O+1}()
  addnodes!(c, nodes(a))
  addedges!(c, edges(a))
  addedge!(c, OutPort(1,I+1), InPort(1,O+1))
  c
end

over(a::PrimArrow) = over(encapsulate(a))

"Union two composite arrows into the same arrow"
function stack{I1, O1, I2, O2}(a::CompositeArrow{I1,O1}, b::CompositeArrow{I2,O2})
  c = CompositeArrow{I1 + I2, O1 + O2}()
  # @show a.edges
  # @show b.edges
  # A can be added pretty much unchanged
  addnodes!(c, nodes(a))
  addedges!(c, edges(a))
  addnodes!(c, nodes(b))
  arrowidoffset = nnodes(a)

  for (outp, inp) in edges(b)
    newoutp = isboundary(outp) ? OutPort(1, outp.pinid + I1) : OutPort(outp.arrowid + arrowidoffset, outp.pinid)
    newinp = isboundary(inp) ? InPort(1, inp.pinid + O1) : InPort(inp.arrowid + arrowidoffset, inp.pinid)
    addedge!(c, newoutp, newinp)
  end
  @show c.edges
  @assert iswellformed(c)
  c
end

stack(a::PrimArrow, b::CompositeArrow) = stack(encapsulate(a), b)
stack(a::PrimArrow, b::PrimArrow) = stack(encapsulate(a), encapsulate(b))
stack(a::CompositeArrow, b::PrimArrow) = stack(a, encapsulate(b))

first(a::PrimArrow{1, 1}) = first(encapsulate(a))
multiplex{I,O}(a::CompositeArrow{I,O}, b::CompositeArrow{I,O}) = lift(clone1dfunc) >>> stack(a,b)
