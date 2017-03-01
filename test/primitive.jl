using Base.Test
using Arrows


plus = PrimArrow(:+)
c = CompArrow(:xyx)
p = add_port!(c)
num_ports(c)
port(c, 1)
p2 = add_port!(c)
link_ports!(c, p, p2)
