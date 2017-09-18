import Base: getindex

function getindex(aarr::AbstractArrow, pred::Function)::Vector{SubPort}
  filter(pred, sub_ports(aarr))
end

function getindex(aarr::AbstractArrow, pred::Function, inds...)::Vector{SubPort}
  filter(pred, sub_ports(aarr)[inds...])
end

function getindex(aarr::AbstractArrow, inds...)::Vector{SubPort}
  sub_ports(aarr)[inds...]
end

getindex(aarr::AbstractArrow, i::Integer)::SubPort = sub_port(aarr, i)

isϵ = is_error_port
isθ = is_parameter_port
is▹ = is_in_port
is◃ = is_out_port
