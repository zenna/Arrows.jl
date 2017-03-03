using Base.Test
import Arrows: PrimArrow, CompArrow, add_port!, num_ports, port, link_ports!
import Arrows

addarr = Arrows.AddArrow()
ports(addarr)
sqrtarr = Arrows.SqrtArrow()
add_sqrt = Arrows.compose(addarr, sqrtarr)
