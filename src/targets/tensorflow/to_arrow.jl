conv_Add(add_op::AbstractOperation) = AddArrow()

conv_Sub(sub_op::AbstractOperation) = SubtractArrow()

conv_AddN(addm_op::AbstractOperation) = AddNArrow(length(addm_op.inputs))

conv_Const(const_op::AbstractOperation) = SourceArrow(get_const_op_value(const_op))

conv_Cos(sin_op::AbstractOperation) = CosArrow()

conv_Exp(exp_op::AbstractOperation) = ExpArrow()

conv_Gather(gather_op::AbstractOperation) = GatherArrow()

conv_GatherNd(gathernd_op::AbstractOperation) = GatherNdArrow()

conv_Mul(mul_op::AbstractOperation) = MulArrow()

conv_Neg(neg_op::AbstractOperation) = NegArrow()

conv_Sin(sin_op::AbstractOperation) = SinArrow()

conv_Reshape(res_op::AbstractOperation) = ReshapeArrow()

conv_Greater(gt_op::AbstractOperation) = GreaterArrow()

conv_Identity(id_op::AbstractOperation) = IdentityArrow()

conv_Abs(id_op::AbstractOperation) = AbsArrow()

conv_Mod(mod_op::AbstractOperation) = ModArrow()

conv_Floor(floor_op::AbstractOperation) = FloorArrow()

conv_Ceil(ceil_op::AbstractOperation) = CeilArrow()

# Mapping between op types and arrows
# Cannot use multimethods because different ops not distinguished by type
Op_Type_To_Arrow = Dict{String, Function}(
  "Add" => conv_Add,
  "AddN" => conv_AddN,
  "Abs" => conv_Abs,
  "Sub" => conv_Sub,
  "Gather" => conv_Gather,
  "GatherNd" => conv_GatherNd,
  "Exp" => conv_Exp,
  "Mul" => conv_Mul,
  "Neg" => conv_Neg,
  "Sin" => conv_Sin,
  "Cos" => conv_Cos,
  "Reshape" => conv_Reshape,
  "Const" => conv_Const,
  "Greater" => conv_Greater,
  "Identity" => conv_Identity,
  "VariableV2" => conv_Const,
  "Mod" => conv_Mod,
  "Floor" => conv_Floor,
  "Ceil" => conv_Ceil)

"""Return an arrow from a list or create one if haven't done already"""
function arrow_from_op(c::CompArrow,
                       op::AbstractOperation,
                       op_to_arrow::Dict{AbstractOperation, SubArrow})::SubArrow

  if op in keys(op_to_arrow)
    # println("RECALLING")
    op_to_arrow[op]
  else
    # println("MAKING NEW ", op_type_name(op))
    # tf.get_def(op).op
    conv_op = Op_Type_To_Arrow[op_type_name(op)]
    arrow = conv_op(op)
    arrowref = add_sub_arr!(c, arrow)
    op_to_arrow[op] = arrowref
    arrowref
    # @assert length(in_ports(arrow)) == length(op.inputs)
  end
end

function update_seen!(op::AbstractOperation,
                      seen_tens::Set{<:AbstractTensor},
                      to_see_tens::Vector{<:AbstractTensor})
  for ten ∈ get_inputs(op)
    if ten ∉ seen_tens
      push!(to_see_tens, ten)
    end
  end
end

"is `ten` an input?"
is_input_ten(ten::AbstractTensor)::Bool =
  op_type_name(get_op(ten)) == "Placeholder"

"""Convert a tenflow graph into an arrow.
Assume inputs are 'Placeholder' tens
Args:
  out_tens: Tensors designated as outputs
  inp_tens: Tensors designated as inputs.  If not given then
                   we assume any placeholder tens connected (indrectly)
                   to the outputs are input tens
  name: Name of the composite arrow
Returns:
  A `CompArrow` equivalent to graph which computes 'out_tens'
"""
function graph_to_arrow(name::Symbol,
                        inp_tens::Vector{<:AbstractTensor},
                        out_tens::Vector{<:AbstractTensor},
                        graph::AbstractGraph)::CompArrow
  op_to_arrow = Dict{AbstractOperation, SubArrow}()
  seen_tens = Set{AbstractTensor}()
  I, O = length(inp_tens), length(out_tens)
  c = CompArrow(name, I, O)

  # Make an in_port for every input ten
  ten_in_port = Dict{AbstractTensor, SubPort}(zip(inp_tens, ▹(c)))
  for inp in inp_tens
    ten_in_port[inp]
  end
  # set_port_shape(in_port, const_to_tuple(ten.get_shape().as_list()))

  # Make an out_port for every output ten
  for (id, ten) in enumerate(out_tens)
    arrow = arrow_from_op(c, get_op(ten), op_to_arrow)
    left = out_sub_port(arrow, value_index(ten) + 1)
    link_ports!(left, out_sub_port(c, id))
  end

  # Starting from outputs
  to_see_tens = copy(out_tens)

  while !isempty(to_see_tens)
    ten = pop!(to_see_tens)
    # println("TENATTR ", ten.op.graph, "\n")
    push!(seen_tens, ten)
    if is_input_ten(ten)
      # print(ten_in_port)
      left_port = ten_in_port[ten]
      # set_port_shape(left_port, const_to_tuple(ten.get_shape().as_list()))
    else
      out_port_id = value_index(ten) + 1
      left_arrow = arrow_from_op(c, get_op(ten), op_to_arrow)
      left_port = out_sub_port(left_arrow, out_port_id)
      update_seen!(get_op(ten), seen_tens, to_see_tens)
    end

    for rec_op in consumers(ten)
      the_inputs = get_inputs(rec_op)
      for (i, input_ten) in enumerate(the_inputs)
        if ten == input_ten
          in_port_id = i
          right_arrow = arrow_from_op(c, rec_op, op_to_arrow)
          link_ports!(left_port, in_sub_port(right_arrow, in_port_id))
        end
      end
    end
  end

  # @assert is_valid(c)
  return c
end
