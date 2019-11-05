module ArrowMod
import LightGraphs; const LG = LightGraphs

export
  AbstractArrow,
  Arrow,
  AbstractPort,
  Port,
  SubPort,

  CompArrow,
  PrimArrow,
  SubArrow,
  UnknownArrow,
  Props,
  link_ports!,
  ⥅,
  ⥆,
  port_id,
  port_sym_name,
  add_sub_arr!,
  replace_sub_arr!,
  out_sub_port,
  out_sub_ports,
  inner_sub_ports,
  sub_arrow,
  sub_arrows,
  sub_port,
  sub_ports,
  in_sub_port,
  in_sub_ports,
  in_ports,
  in_port,
  out_port,
  out_ports,
  num_in_ports,
  num_out_ports,
  num_ports,
  port,
  ports,
  props,
  all_names,
  is_wired_ok,
  is_valid,
  deref

# Core Arrow Data structures #
include("core.jl")       # Properties
include("property.jl")       # Properties
include("port.jl")           # Ports
include("primarrow.jl")      # Pimritive Arrows
include("comparrow.jl")      # Composite Arrows
include("comparrowextra.jl") # functions on CompArrows that dont touch internals
include("unknown.jl")        # Unknown (uninterpreted) Arrows

end