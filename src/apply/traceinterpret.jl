function tracemaybedown(sub_interpret,
                   sarr::SubArrow{CompArrow},
                   inputs,
                   tabv::TraceAbValues,
                   tparent::TraceParent)
  tparent = down(tparent, sarr)
  interpret(sub_interpret, carr, inputs, tabv, tparent)
end

function tracemaybedown(sub_interpret,
                   sarr::SubArrow{<:PrimArrow},
                   inputs,
                   tabv::TraceAbValues,
                   tparent::TraceParent)
  sub_interpret(sarr, inputs, tabv, tparent)
end

function traceinner_interpret(sub_interpret,
                              carr::CompArrow,
                              inputs::Vector,
                              arrcolors::ArrowColors,
                              dst_val::Dict{SubPort, Any},
                              tabv::TraceAbValues,
                              tparent::TraceParent)
  @assert length(inputs) == num_in_ports(carr) "wrong # inputs"
  @assert all(sarr ∈ keys(arrcolors) for sarr in sub_arrows(carr))
  @assert is_valid(carr)
  seen = Set{SubArrow}()
  while length(arrcolors) > 0
    # Highest priority sarr ready to be evaluated
    @assert peek(arrcolors)[2] == 0 peek(arrcolors)[2]
    sarr = dequeue!(arrcolors)
    push!(seen, sarr)
    inputs = [dst_val[sprt] for sprt in ▹(sarr)]
    outputs = maybedown(sub_interpret, sarr, inputs, tabv, tparent)
    @assert length(outputs) == length(◂(sarr)) "diff num outputs"

    # Decrement the priority of each subarrow connected to this arrow
    # Unless of course it is connected to the outside word
    for (i, sprt) in enumerate(◃(sarr))
      for dst_sprt in out_neighbors(sprt)
        dst_val[dst_sprt] = outputs[i]
        # @assert sub_arrow(dst_sprt) ∈ keys(arrcolors)
        lower!(arrcolors, sub_arrow(dst_sprt))
      end
    end
  end

  [dst_val[sprt] for sprt in ◃(carr)]
end

@pre inner_interpret same(length.(inputs, sub_arrows(carr))...)
@pre inner_interpret length(inputs) == num_in_ports(carr)
"""
Interpret `carr` on `inputs`
# Arguments:
  `sub_interpret`: Function
  `carr`: Composite Arrow to execute
  `inputs`: list of inputs to composite arrow
# Returns:
  List of outputs
"""
function traceinterpret(sub_interpret,
                   carr::CompArrow,
                   inputs::Vector,
                   tabv::TraceAbValues=traceprop!(carr),
                   tparent::TraceParent=TraceParent(carr))
  colors = known_colors(carr)
  dst_val = dst_sub_port_values(carr, inputs)
  result = inner_interpret(sub_interpret,
                           carr,
                           inputs,
                           colors,
                           dst_val,
                           tabv,
                           tparent)
end
