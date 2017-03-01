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
  addedge!(c, OutPort(1,I+1), InPort(1,O+1)) # identity wire
  c
end

over(a::PrimArrow) = over(encapsulate(a))

"Place `a` under an identity wire.  Like `second` but for multiple in/out puts"
function under{I,O}(a::CompositeArrow{I,O})
  c = CompositeArrow{I+1, O+1}()
  addnodes!(c, nodes(a))
  # add edges of a but increment ports at boundaries by 1
  for (outp, inp) in edges(a)
    newinp = isboundary(inp) ? InPort(inp.arrowid, inp.pinid + 1) : inp
    newoutp = isboundary(outp) ? OutPort(outp.arrowid, outp.pinid + 1) : outp
    addedge!(c, newoutp, newinp)
  end
  addedge!(c, OutPort(1,1), InPort(1,1)) # identity wire
  c
end

under(a::PrimArrow) = under(encapsulate(a))


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

## Switch
## ======

"Switch inport `p1` and `p2`: usage inswitch(subarr, 1, 2)"
function inswitch{I, O}(a::CompositeArrow{I, O}, p1::Integer, p2::Integer)
  @assert 1 <= p1 <= I "Invalid switch range, violates 1 <= p1 <= $I"
  @assert 1 <= p2 <= I "Invalid switch range, violates 1 <= p2 <= $I"

  c = CompositeArrow{I, O}()
  addnodes!(c, nodes(a))
  for (outp, inp) in edges(a)
    if isboundary(outp) && outp.pinid == p1
      addedge!(c, OutPort(1, p2), inp)
    elseif isboundary(outp) && outp.pinid == p2
      addedge!(c, OutPort(1, p1), inp)
    else
      addedge!(c, outp, inp)
    end
  end

  @assert iswellformed(c)
  c
end

inswitch(a::PrimArrow, p1::Integer, p2::Integer) = inswitch(encapsulate(a),p1,p2)

## Recursion Combinators
## =====================
"""Constructs `InitArrow` with initial value as argument.
usage: loop(first(init(0)) >>> +) # Creates a counter that starts at 0"""
init(initval...) = InitArrow{length(initval)}(initval)


## Inversion
## =========
#
# "Invert an invertible arrow"
# function inv(a::UnaryArithArrow)
#   inverses = Dict(:* => :/, :/ => :*, :+ => :-, :- => :+, :^ => :log, :log => :^)
#   inverse_f = inverses(a.name)
#   if a.name == :- && a.isnumfirst == true
#     return a
#   elseif a.name == :- && a.isnumfirst == false
#     return UnaryArithArrow{T}(:+, a.value, false)
#   elseif a.name == :+
#     # y = x + 3 => x = y - 3
#     return UnaryArithArrow{T}(:-, a.value, false)
#   elseif a.name == :*
#     # y = x * 3 => x = y/3
#     return UnaryArithArrow{T}(:/, a.value, false)
#   elseif a.name == :/ && a.isnumfirst == true
#     # y = 3/x => x = 3/y
#     return UnaryArithArrow{T}(:/, a.value, true)
#   elseif a.name == :/ && a.isnumfirst == false
#     # y = x/3 => x = 3y
#     return UnaryArithArrow{T}(:*, a.value, true)
#   elseif a.name == :^ && a.isnumfirst == true
#     # y = 3 ^ x => x = log_3(y)
#     return UnaryArithArrow{T}(:log, a.value, true)
#   elseif a.name == :^ && a.isnumfirst == false
#     # y = x ^ 3 => x = log_y(3)
#     return UnaryArithArrow{T}(:log, a.value, false)
#   elseif a.name == :log && a.isnumfirst == true
#     # y = log_2(x) => x = 2^y
#     return UnaryArithArrow{T}(:^, a.value, true)
#   elseif a.name == :log && a.isnumfirst == false
#     # y = log_x(2) => x = 2^(1/y)
#     return invarrow >> UnaryArithArrow{T}(:^, a.value, true)
#   else
#     error("unsupported case")
#   end
# end
#
# "Invert a binary arithmetic arrow"
# function inv(a::ArithArrow)
#   if a.name == :+
#     over(clone(2)) >>> under(addarr)
#   end
# end