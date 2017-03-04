"Wrap an arrow in another arrow - behaves identically to original arrow"
function encapsulate{I,O}(arr::PrimArrow{I,O})
  c = CompArrow{I,O}()
  c
end

"Right Composition - Wire outputs of `a` to inputs of `b`"
function compose{I1, O1I2, O2}(a::Arrow{I1, O1I2},
                               b::Arrow{O1I2, O2})::Arrow{I1,O2}
  c = CompArrow{I1,O2}(Symbol(name(a), :_, name(b)))
  # Connect up the inputs
  for i = 1:num_in_ports(a)
    link_ports!(c, in_port(c, i), in_port(a, i))
  end

  # Connect up the outputs
  for i = 1:num_out_ports(a)
    link_ports!(c, out_port(b, i), out_port(c, i))
  end

  # Connect the inputs to the outputs
  for i = 1:num_out_ports(a)
    link_ports!(c, out_port(a, i), in_port(b, i))
  end
  c
end

# compose(a::PrimArrow, b::CompArrow) = compose(encapsulate(a), b)
# compose(a::CompArrow, b::PrimArrow) = compose(a, encapsulate(b))
# compose(a::PrimArrow, b::PrimArrow) = compose(encapsulate(a), encapsulate(b))
>>>(a::Arrow, b::Arrow) = compose(a, b)
# CompArrow{2, 1}(:hello, Graph(), Port[], [])
# CompArrow{3, 1}(:a)
# """Takes two inputs side by side. The first one is modified using an arrow `a`,
#   while the second is left unchanged."""
# function first(a::CompArrow{1,1})
#   c = CompArrow{2, 2}()
#   addnodes!(c, nodes(a))
#   addedges!(c, edges(a))
#   addedge!(c, OutPort(1,2), InPort(1,2))
#   @assert iswellformed(c)
#   c
# end
#
# "Place `a` over an identity wire.  Like `first` but for multiple in/out puts"
# function over{I,O}(a::CompArrow{I,O})
#   c = CompArrow{I+1, O+1}()
#   addnodes!(c, nodes(a))
#   addedges!(c, edges(a))
#   addedge!(c, OutPort(1,I+1), InPort(1,O+1)) # identity wire
#   c
# end
#
# over(a::PrimArrow) = over(encapsulate(a))
#
# "Place `a` under an identity wire.  Like `second` but for multiple in/out puts"
# function under{I,O}(a::CompArrow{I,O})
#   c = CompArrow{I+1, O+1}()
#   addnodes!(c, nodes(a))
#   # add edges of a but increment ports at boundaries by 1
#   for (outp, inp) in edges(a)
#     newinp = isboundary(inp) ? InPort(inp.arrowid, inp.pinid + 1) : inp
#     newoutp = isboundary(outp) ? OutPort(outp.arrowid, outp.pinid + 1) : outp
#     addedge!(c, newoutp, newinp)
#   end
#   addedge!(c, OutPort(1,1), InPort(1,1)) # identity wire
#   c
# end
#
# under(a::PrimArrow) = under(encapsulate(a))
#
#
# "Union two composite arrows into the same arrow"
# function stack{I1, O1, I2, O2}(a::CompArrow{I1,O1}, b::CompArrow{I2,O2})
#   c = CompArrow{I1 + I2, O1 + O2}()
#   # @show a.edges
#   # @show b.edges
#   # A can be added pretty much unchanged
#   addnodes!(c, nodes(a))
#   addedges!(c, edges(a))
#   addnodes!(c, nodes(b))
#   arrowidoffset = nnodes(a)
#
#   for (outp, inp) in edges(b)
#     newoutp = isboundary(outp) ? OutPort(1, outp.pinid + I1) : OutPort(outp.arrowid + arrowidoffset, outp.pinid)
#     newinp = isboundary(inp) ? InPort(1, inp.pinid + O1) : InPort(inp.arrowid + arrowidoffset, inp.pinid)
#     addedge!(c, newoutp, newinp)
#   end
#   @show c.edges
#   @assert iswellformed(c)
#   c
# end
#
# stack(a::PrimArrow, b::CompArrow) = stack(encapsulate(a), b)
# stack(a::PrimArrow, b::PrimArrow) = stack(encapsulate(a), encapsulate(b))
# stack(a::CompArrow, b::PrimArrow) = stack(a, encapsulate(b))
#
# first(a::PrimArrow{1, 1}) = first(encapsulate(a))
# multiplex{I,O}(a::CompArrow{I,O}, b::CompArrow{I,O}) = lift(clone1dfunc) >>> stack(a,b)
#
# ## Switch
# ## ======
#
# "Switch inport `p1` and `p2`: usage inswitch(subarr, 1, 2)"
# function inswitch{I, O}(a::CompArrow{I, O}, p1::Integer, p2::Integer)
#   @assert 1 <= p1 <= I "Invalid switch range, violates 1 <= p1 <= $I"
#   @assert 1 <= p2 <= I "Invalid switch range, violates 1 <= p2 <= $I"
#
#   c = CompArrow{I, O}()
#   addnodes!(c, nodes(a))
#   for (outp, inp) in edges(a)
#     if isboundary(outp) && outp.pinid == p1
#       addedge!(c, OutPort(1, p2), inp)
#     elseif isboundary(outp) && outp.pinid == p2
#       addedge!(c, OutPort(1, p1), inp)
#     else
#       addedge!(c, outp, inp)
#     end
#   end
#
#   @assert iswellformed(c)
#   c
# end
#
# inswitch(a::PrimArrow, p1::Integer, p2::Integer) = inswitch(encapsulate(a),p1,p2)
#
# ## Recursion Combinators
# ## =====================
# """Constructs `InitArrow` with initial value as argument.
# usage: loop(first(init(0)) >>> +) # Creates a counter that starts at 0"""
# init(initval...) = InitArrow{length(initval)}(initval)
