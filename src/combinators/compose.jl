# "Right Composition - Wire outputs of `a` to inputs of `b`"
# function compose{I1, O1I2, O2}(c::CompArrow{I1, O2},
#                                a::Arrow{I1, O1I2},
#                                b::Arrow{O1I2, O2})::CompArrow{I1,O2}
#   # Connect up the inputs
#   for i = 1:I1
#     link_ports!(c, in_port(c, i), in_port(a, i))
#   end
#
#   # Connect up the outputs
#   for i = 1:O2
#     link_ports!(c, out_port(b, i), out_port(c, i))
#   end
#
#   # Connect the inputs to the outputs
#   for i = 1:O1I2
#     link_ports!(c, out_port(a, i), in_port(b, i))
#   end
#   c
# end
#
# "Compose two primitive arrows"
# function compose{I1, O1I2, O2}(a::PrimArrow{I1, O1I2},
#                                b::PrimArrow{O1I2, O2})::CompArrow{I1,O2}
#   c = CompArrow{I1,O2}(Symbol(name(a), :_, name(b)))
#   aa = add_sub_arr!(c, a)
#   bb = add_sub_arr!(c, b)
#   compose(c, aa, bb)
# end
#
# # compose(a::PrimArrow, b::CompArrow) = compose(wrap(a), b)
# # compose(a::CompArrow, b::PrimArrow) = compose(a, wrap(b))
# # compose(a::PrimArrow, b::PrimArrow) = compose(wrap(a), wrap(b))
# >>>(a::Arrow, b::Arrow) = compose(a, b)
