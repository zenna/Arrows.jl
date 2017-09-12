ArrowColors = PriorityQueue{SubArrow, Int}

"Priority queue of each `SubArrow` to number of already evaluated inputs"
function colors(carr::CompArrow)
  # priority is the number of inputs each arrrow has which have been 'seen'
  # seen inputs are inputs to the composition, or outputs of arrows that
  # have already been sub_interpreterted into
  ArrowColors(sarr => num_in_ports(sarr) for sarr in sub_arrows(carr))
end

"Decrement priortiy of `sprt`"
  lower!(pq::ArrowColors, sarr::SubArrow) = if !self_parent(sarr) pq[sarr] -= 1 end

"Decrement SubArrows "
function known_colors(carr::CompArrow)::ArrowColors
  pq = colors(carr)
  foreach(out_neighbors(in_sub_ports(carr))) do dst_sprt
    lower!(pq, sub_arrow(dst_sprt))
  end
  pq
end

"Propagate inputs to `carr` to `sprt::SubPort =>  value` where `is_dst(sprt)`"
function dst_sub_port_values(carr::CompArrow, inputs::Vector)::Dict{SubPort, Any}
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
function inner_interpret(sub_interpret,
                         carr::CompArrow,
                         inputs::Vector,
                         arrcolors::ArrowColors,
                         dst_val::Dict{SubPort, Any})
  @assert length(inputs) == num_in_ports(carr) "wrong # inputs"
  @assert all(sarr ∈ keys(arrcolors) for sarr in sub_arrows(carr))
  @assert is_wired_ok(carr)
  seen = Set{SubArrow}()
  while length(arrcolors) > 0
    # Highest priority sarr ready to be evaluated
    @assert peek(arrcolors)[2] == 0 peek(arrcolors)[2]
    sarr = dequeue!(arrcolors)
    push!(seen, sarr)
    inputs = [dst_val[sprt] for sprt in in_sub_ports(sarr)]
    outputs = sub_interpret(sarr, inputs)

    # @show arrcolors
    # @show inputs
    # @show outputs
    # @show sarr

    @assert length(outputs) == length(out_ports(sarr)) "diff num outputs"

    # Decrement the priority of each subarrow connected to this arrow
    # Unless of course it is connected to the outside word
    for (i, sprt) in enumerate(out_sub_ports(sarr))
      for dst_sprt in out_neighbors(sprt)
        dst_val[dst_sprt] = outputs[i]
        # @assert sub_arrow(dst_sprt) ∈ keys(arrcolors)
        lower!(arrcolors, sub_arrow(dst_sprt))
      end
    end
    # foreach(enumerate(out_neighbors(out_sub_ports(sarr)))) do i_dst_sprt
    #   i, dst_sprt = i_dst_sprt
    #   lower!(arrcolors, sub_arrow(dst_sprt))
    #   dst_val[dst_sprt] = outputs[i]
    # end
  end

  [dst_val[sprt] for sprt in out_sub_ports(carr)]
end

"""
Interpret a composite arrow on inputs
Args:
  sub_interpret:
  carr: Composite Arrow to execute
  inputs: list of inputs to composite arrow
Returns:
  List of outputs
"""
function interpret(sub_interpret,
                   carr::CompArrow,
                   inputs::Vector)
  colors = known_colors(carr)
  dst_val = dst_sub_port_values(carr, inputs)
  result = inner_interpret(sub_interpret,
                           carr,
                           inputs,
                           colors,
                           dst_val)
end
