"Wrap an arrow in another arrow - behaves identically to original arrow"
function wrap{I,O}(arr::Arrow{I,O})
  arr_wrap = CompArrow{I,O}(Symbol(arr.name, :_wrap), arr.port_props)
  arrc = add_sub_arr!(arr_wrap, arr)

  for i = 1:num_ports(arrc)
    if is_in_port(port(arrc, i))
      # println("for ith port making edge from wrapping to inner")
      link_ports!(arr_wrap, port(arr_wrap, i), port(arrc, i))
    else
      # println("for ith port making edge from inner to wrapping")
      link_ports!(arr_wrap, port(arrc, i), port(arr_wrap, i))
    end
  end
  arr_wrap
end

"Right Composition - Wire outputs of `a` to inputs of `b`"
function compose{I1, O1I2, O2}(c::CompArrow{I1, O2},
                               a::Arrow{I1, O1I2},
                               b::Arrow{O1I2, O2})::CompArrow{I1,O2}
  # Connect up the inputs
  for i = 1:I1
    link_ports!(c, in_port(c, i), in_port(a, i))
  end

  # Connect up the outputs
  for i = 1:O2
    link_ports!(c, out_port(b, i), out_port(c, i))
  end

  # Connect the inputs to the outputs
  for i = 1:O1I2
    link_ports!(c, out_port(a, i), in_port(b, i))
  end
  c
end

"Compose two primitive arrows"
function compose{I1, O1I2, O2}(a::PrimArrow{I1, O1I2},
                               b::PrimArrow{O1I2, O2})::CompArrow{I1,O2}
  c = CompArrow{I1,O2}(Symbol(name(a), :_, name(b)))
  aa = add_sub_arr!(c, a)
  bb = add_sub_arr!(c, b)
  compose(c, aa, bb)
end

# compose(a::PrimArrow, b::CompArrow) = compose(wrap(a), b)
# compose(a::CompArrow, b::PrimArrow) = compose(a, wrap(b))
# compose(a::PrimArrow, b::PrimArrow) = compose(wrap(a), wrap(b))
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
# over(a::PrimArrow) = over(wrap(a))
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
# under(a::PrimArrow) = under(wrap(a))
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
# stack(a::PrimArrow, b::CompArrow) = stack(wrap(a), b)
# stack(a::PrimArrow, b::PrimArrow) = stack(wrap(a), wrap(b))
# stack(a::CompArrow, b::PrimArrow) = stack(a, wrap(b))
#
# first(a::PrimArrow{1, 1}) = first(wrap(a))
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
# inswitch(a::PrimArrow, p1::Integer, p2::Integer) = inswitch(wrap(a),p1,p2)
#
# ## Recursion Combinators
# ## =====================
# """Constructs `InitArrow` with initial value as argument.
# usage: loop(first(init(0)) >>> +) # Creates a counter that starts at 0"""
# init(initval...) = InitArrow{length(initval)}(initval)
