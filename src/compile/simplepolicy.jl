ArrowColors = PriorityQueue{SubArrow, Int}

"Priority queue of each `SubArrow` to number of already evaluated inputs"
function colors(carr::CompArrow)
  # priority is the number of inputs each arrrow has which have been 'seen'
  # seen inputs are inputs to the composition, or outputs of arrows that
  # have already been converted into
  ArrowColors(sarr => num_in_ports(sarr) for sarr in sub_arrows(carr))
end

"Decrement priortiy of `sprt`"
lower!(pq::ArrowColors, sarr::SubArrow) = if !self_parent(sarr) pq[sarr] -= 1 end

"Decrement SubArrows "
function known_colors(carr::CompArrow, sprts::Vector{SubPort})::ArrowColors
  pq = colors(carr)
  foreach(lower!(pq, sub_arrow(dst_sprt)), out_neighbors(in_sub_ports(carr)))
  pq
end

"out_neighbors"
function out_neighbors(sprts::Vector{SubPort})::Vector{SubPort}
  neighs = SubPort[]
  for sprt in sprts
    for dst_sprt in out_neighbors(sprt)
      push!(neighs, dst_sprt)
    end
  end
  neighs
end

function sub_port_values(carr::CompArrow, inputs::Vector)::Dict{SubPort, Any}
  length(inputs) == num_in_ports(carr) || throw(DomainError())
  dst_val = Dict{SubPort, Any}()

  for (i, sprt) in enumerate(in_sub_ports(carr))
    for dst_sprt in out_neighbors(sprt)
      dst_val[dst_sprt] = inputs[i]
    end
  end
  dst_val
end

"""Convert an comp_arrow to a tensorflow graph and add to graph"""
function inner_interpret(conv,
                         carr::CompArrow,
                         inputs::Vector,
                         arrcolors::ArrowColors,
                         dst_val::Dict{SubPort, Any})
  @assert length(inputs) == num_in_ports(carr) "wrong # inputs"
  while length(arrcolors) > 0
    # Highest priority sarr ready to be evaluated
    sarr = dequeue!(arrcolors)
    inputs = [dst_val[sprt] for sprt in in_sub_ports(sarr)]
    outputs = conv(sarr, inputs)

    @assert peek(arrcolors)[2] == 0
    @assert length(outputs) == length(out_ports(sarr)) "diff num outputs"

    # Decrement the priority of each subarrow connected to this arrow
    # Unless of course it is connected to the outside word
    foreach(enumerate(out_neighbors(out_sub_ports(sarr)))) do i_dst_sprt
      i, dst_sprt = i_dst_sprt
      lower!(arrcolors, sub_arrow(dst_sprt))
      dst_val[dst_sprt] = outputs[i]
    end
  end

  [dst_val[sprt] for sprt in out_sub_ports(carr)]
end

"""
Interpret a composite arrow on inputs
Args:
  conv:
  carr: Composite Arrow to execute
  inputs: list of inputs to composite arrow
Returns:
  List of outputs
"""
function interpret(conv,
                   carr::CompArrow,
                   inputs::Vector)
  colors = known_colors(carr)
  dst_val = sub_port_values(carr, inputs)
  result = inner_interpret(conv,
                           carr,
                           inputs,
                           colors,
                           dst_val)
end
