import LightGraphs: Graph, add_edge!, add_vertex!

abstract Arrow{I, O}

"""An entry or exit to an Arrow, analogous to argument position of multivariate function.

  A port is uniquely determined by the arrow it belongs to and a pin.
  By convention, a port which is on the parent arrow will have `arrowid = 1`.
  `pinid`s are contingous from `1:I` or `1:O` for inputs and outputs respectively.

  On the boundary of a composite arrow, ports are simultaneously inports (since they take
  input from outside world) and outputs (since inside they project outward to
"""
immutable Port
  arrow::Arrow
  index::Integer
end

abstract PortAttribute
