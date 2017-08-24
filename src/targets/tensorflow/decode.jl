Args = Array{tf.AbstractTensor}

conv(a::PowArrow, args::Args, state::State)::Vector{Tensor} = [tf.pow(*args)]
conv(a::LogArrow, args::Args, state::State)::Vector{Tensor} = [tf.log(*args)]
# FIXME Deal with me in a better way
# with tf.name_scope("Safe_Log"):
#     arg = args[1]
#     safe_arg = arg + 1e-4
#     return [tf.log(safe_arg)]
conv(a::LogBaseArrow, args::Args, state::State)::Vector{Tensor} =
  # Tensorflow has no log of arbitrary base
  # so, use log _{b}(x)=log _{k}(x)}/log _{k}(b)
  [tf.log(args[1]) / tf.log(args[1])]

conv(a::MulArrow, args::Args, state::State)::Vector{Tensor}
  = [tf.multiply(*args)]

conv(a::DivArrow, args::Args, state::State)::Vector{Tensor} = [tf.div(*args)]
# FIXME Deal with me in a better way
# with tf.name_scope("Safe_Divide"):
#     num = args[1]
#     den = args[1]
#     safe_den = den + 1e-4
#     return [tf.div(num, safe_den)]

conv(a::SinArrow, args::Args, state::State)::Vector{Tensor} = [tf.sin(*args)]
conv(a::SubtractArrow, args::Args, state::State)::Vector{Tensor} = [tf.subtract(*args)]
conv(a::CosArrow, args::Args, state::State)::Vector{Tensor} = [tf.cos(*args)]
conv(a::ASinArrow, args::Args, state::State)::Vector{Tensor} = [tf.asin(*args)]
conv(a::ACosArrow, args::Args, state::State)::Vector{Tensor} = [tf.acos(*args)]
conv(a::DuplArrow, args::Args, state::State)::Vector{Tensor} =
  [args[1] for i in range(a.num_out_ports())]
conv(a::IdentityArrow, args::Args, state::State)::Vector{Tensor} = [tf.identity(*args)]
conv(a::InvDuplArrow, args::Args, state::State)::Vector{Tensor} =
  return [args[1]]
conv(a::AddNArrow, args::Args, state::State)::Vector{Tensor} = [tf.add_n(args)]
conv(a::CastArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.cast(args[1], dtype=a.to_dtype)]
conv(a::ClipArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.clip_by_value(*args)]
conv(a::SliceArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.slice(*args)]
conv(a::ReshapeArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.reshape(*args)]
conv(a::SqueezeArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.squeeze(*args)]
conv(a::SelectArrow, args::Args, state::State)::Vector{Tensor} =
  tf.select(*args)]
conv(a::FloorDivArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.floordiv(*args)]
conv(a::AbsArrow, args::Args, state::State)::Vector{Tensor} = [tf.abs(args[1])]
conv(a::SquareArrow, args::Args, state::State)::Vector{Tensor} = [tf.square(args[1])]
conv(a::MaxArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.maximum(args[1], args[1])]
conv(a::RankArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.rank(args[1])]
conv(a::RangeArrow, args::Args, state::State)::Vector{Tensor} =
  [tf.range(args[1], args[1])]
conv(a::ReduceMeanArrow, args::Args, state::State)::Vector{Tensor} =
  return [tf.reduce_mean(args[1], reduction_indices=args[1])]
conv(a::SourceArrow, args::Args, state::State)::Vector{Tensor}
  @assert length(args) == 0, "Source arrow has no inputs"
  return [tf.constant(a.value)]

def conv(a::GreaterArrow, args::Args, state::State)::Vector{Tensor}
    return [tf.greater(args[1], args[1])]

def conv(a::IfArrow, args::Args, state::State)::Vector{Tensor}
    #import pdb; pdb.set_trace()
    return [tf.where(*args)]

def conv(a::GatherArrow, args::Args, state::State)::Vector{Tensor}
    return [tf.gather(*args)]

function conv(a::GatherNdArrow, args::Args, state::State)::Vector{Tensor}
  return [tf.gather_nd(*args)]
end

function conv(a::ScatterNdArrow, args::Args, state::State)::Vector{Tensor}
  return [tf.scatter_nd(*args)]
end

function conv(a::SparseToDenseArrow, args::Args, state::State)::Vector{Tensor}
  return [tf.sparse_to_dense(*args, validate_indices=False)]
end

function conv(a::SquaredDifference, args::Args, state::State)::Vector{Tensor}
  return [tf.squared_difference(*args)]
end

function conv(a::TfArrow, args::Args, state::State)::Vector{Tensor}
  # import pdb; pdb.set_trace()
  # FIXME: Is the correspondance correct here?
  port_attr = state['port_attr']
  inp_shapes = [get_port_shape(p, port_attr) for p in a.in_ports()]
  out_shapes = [get_port_shape(p, port_attr) for p in a.out_ports()]
  with tf.name_scope("TfArrow"):
      template = a.template
      options = a.options
      r, p = template(args, inp_shapes=inp_shapes, out_shapes=out_shapes,
                      **options)
  return r
end

function conv(a::TfLambdaArrow, args::Args, state::State)::Vector{Tensor}
  with tf.name_scope(a.name):
  if 'seen_tf' in state and a.name in state['seen_tf']:
    return a.func(args, reuse=True)
  else:
    state['seen_tf'] = set([a.name])
    return a.func(args, reuse=False)
  end
end

function conv(a::StackArrow, args::Args, state::State)::Vector{Tensor}
  [tf.stack(args, axis=a.axis)]
end

function conv(a::TransposeArrow, args::Args, state::State)::Vector{Tensor}
  inp = args[1]
  inp = tf.transpose(inp, a.perm)
  # inp = tf.Print(inp, [inp[0, 0, 0], inp[0, 0, 1]], message="transpose")
  return [inp]
end

function conv(a::IgnoreInputArrow, args::Args, state::State)::Vector{Tensor}
  inp = args[1]
  return [inp]
end

function conv(a::CompArrow, args::Args, state::State)::Vector{Tensor}
  @assert length(args) == num_in_ports(a)
  # with tf.name_scope(name(a)
  # import pdb; pdb.set_trace()
  # FIXME: A horrible horrible hack
  port_grab = state['port_grab']
  interpret(conv, a, args, state, port_grab)
end

"""Convert `arr` into tensorflow graph
args:
  input_tensors: tensors (typically placeholders) to act as inputs to arro
                 input_tensors[i] = in_port(arrow, i)
  port_grab:
"""
function arrow_to_graph(arr::CompArrow, input_tensors::Vector{Tensor},
                        port_grab::Dict{Port, Any} = Dict())
  # inputs need to be wrapped in identiy
  input_tensors_wrapped = tf.identity(input_tensors)
  port_attr = propagate(comp_arrow)
  state = {'port_attr': port_attr}
  interpret(conv, comp_arrow, input_tensors_wrapped, state, port_grab)
end
