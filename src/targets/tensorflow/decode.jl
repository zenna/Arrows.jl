# Convert an arrow to a tensorflow graph
Args = Vector{<:tf.AbstractTensor}

conv(::PowArrow, args::Args)::Vector{Tensor} = [tf.pow(args...)]
conv(::LogArrow, args::Args)::Vector{Tensor} = [tf.log(args...)]
# FIXME Deal with me in a better way
# with tf.name_scope("Safe_Log"):
#     arg = args[1]
#     safe_arg = arg + 1e-4
#     return [tf.log(safe_arg)]
conv(::LogBaseArrow, args::Args)::Vector{Tensor} =
  [tf.log(args[1]) / tf.log(args[1])] # no logbase, use: log _{b}(x)=log _{k}(x)}/log _{k}(b)

conv(::AddArrow, args::Args)::Vector{Tensor} = [tf.add(args...)]
conv(::MulArrow, args::Args)::Vector{Tensor} = [tf.multiply(args...)]
conv(::DivArrow, args::Args)::Vector{Tensor} = [args[1] / args[2]]
# FIXME Deal with me in a better way
# with tf.name_scope("Safe_Divide"):
#     num = args[1]
#     den = args[1]
#     safe_den = den + 1e-4
#     return [tf.div(num, safe_den)]

conv(::MeanArrow, args::Args)::Vector{Tensor} = [tf.reduce_mean(tf.stack(args), axis=1)]
conv(::Arrows.ReduceVarArrow, args::Args)::Vector{Tensor} = [reduce_var(args)]
conv(::SinArrow, args::Args)::Vector{Tensor} = [tf.sin(args...)]
conv(::SubtractArrow, args::Args)::Vector{Tensor} = [args[1] - args[2]]
conv(::CosArrow, args::Args)::Vector{Tensor} = [tf.cos(args...)]
conv(::ASinArrow, args::Args)::Vector{Tensor} = [tf.asin(args...)]
conv(::ACosArrow, args::Args)::Vector{Tensor} = [tf.acos(args...)]
conv{N}(arr::DuplArrow{N}, args::Args)::Vector{Tensor} = [args[1] for i = 1:N]
conv(::IdentityArrow, args::Args)::Vector{Tensor} = [tf.identity(args...)]
conv(::InvDuplArrow, args::Args)::Vector{Tensor} =
  return [args[1]]
# conv(::AddNArrow, args::Args)::Vector{Tensor} = [tf.add_n(args)]
# conv(a::CastArrow, args::Args)::Vector{Tensor} =
#   [tf.cast(args[1], dtype=a.to_dtype)]
# conv(::ClipArrow, args::Args)::Vector{Tensor} =
#   [tf.clip_by_value(args...)]
# conv(a::SliceArrow, args::Args)::Vector{Tensor} = [tf.slice(args...)]
# conv(a::ReshapeArrow, args::Args)::Vector{Tensor} = [tf.reshape(args...)]
# conv(a::SqueezeArrow, args::Args)::Vector{Tensor} = [tf.squeeze(args...)]
# conv(a::SelectArrow, args::Args)::Vector{Tensor} = tf.select(args...)]
# conv(a::FloorDivArrow, args::Args)::Vector{Tensor} = [tf.floordiv(args...)]
# conv(a::AbsArrow, args::Args)::Vector{Tensor} = [tf.abs(args[1])]
# conv(a::SquareArrow, args::Args)::Vector{Tensor} = [tf.square(args[1])]
# conv(a::MaxArrow, args::Args)::Vector{Tensor} = [tf.maximum(args[1], args[1])]
# conv(a::RankArrow, args::Args)::Vector{Tensor} = [tf.rank(args[1])]
# conv(a::RangeArrow, args::Args)::Vector{Tensor} = [tf.range(args[1], args[1])]
# conv(a::ReduceMeanArrow, args::Args)::Vector{Tensor} =
#   return [tf.reduce_mean(args[1], reduction_indices=args[1])]


sanitizeconst(value::Tuple) = [value...]
sanitizeconst(value) = value
conv(::Arrows.ReshapeArrow, args)::Vector{Tensor} = [tf.reshape(args...)]
conv(::GatherNdArrow, args)::Vector{Tensor} = [tf.gather_nd(args...)]
conv(::NegArrow, args)::Vector{Tensor} = [tf.neg(args...)]
conv(::ExpArrow, args)::Vector = [tf.exp(args...)]
conv(arr::SourceArrow, args)::Vector{Tensor} = [tf.constant(sanitizeconst(arr.value))]

# conv(a::GreaterArrow, args::Args)::Vector{Tensor} = [tf.greater(args[1], args[1])]
# conv(a::IfArrow, args::Args)::Vector{Tensor} = [tf.where(args...)]
# conv(a::GatherArrow, args::Args)::Vector{Tensor} = [tf.gather(args...)]

# function conv(a::GatherNdArrow, args::Args)::Vector{Tensor}
#   return [tf.gather_nd(args...)]
# end

# function conv(a::ScatterNdArrow, args::Args)::Vector{Tensor}
#   return [tf.scatter_nd(args...)]
# end

# function conv(a::SparseToDenseArrow, args::Args)::Vector{Tensor}
#   return [tf.sparse_to_dense(args..., validate_indices=False)]
# end

# function conv(a::SquaredDifference, args::Args)::Vector{Tensor}
#   return [tf.squared_difference(args...)]
# end

# function conv(a::TfArrow, args::Args)::Vector{Tensor}
#   # import pdb; pdb.set_trace()
#   # FIXME: Is the correspondance correct here?
#   port_prop = state['port_prop']
#   inp_shapes = [get_port_shape(p, port_prop) for p in a.in_ports()]
#   out_shapes = [get_port_shape(p, port_prop) for p in a.out_ports()]
#   with tf.name_scope("TfArrow"):
#       template = a.template
#       options = a.options
#       r, p = template(args, inp_shapes=inp_shapes, out_shapes=out_shapes,
#                       **options)
#   return r
# end

# function conv(a::TfLambdaArrow, args::Args)::Vector{Tensor}
#   with tf.name_scope(a.name):
#   if 'seen_tf' in state and a.name in state['seen_tf']:
#     return a.func(args, reuse=True)
#   else:
#     state['seen_tf'] = set([a.name])
#     return a.func(args, reuse=False)
#   end
# end

# function conv(a::StackArrow, args::Args)::Vector{Tensor}
#   [tf.stack(args, axis=a.axis)]
# end

# function conv(a::TransposeArrow, args::Args)::Vector{Tensor}
#   inp = args[1]
#   inp = tf.transpose(inp, a.perm)
#   # inp = tf.Print(inp, [inp[0, 0, 0], inp[0, 0, 1]], message="transpose")
#   return [inp]
# end

# function conv(a::IgnoreInputArrow, args::Args)::Vector{Tensor}
#   inp = args[1]
#   return [inp]
# end
conv(sarr::SubArrow, xs::Vector) = conv(deref(sarr), xs)

function conv(carr::CompArrow, args::Args)::Vector{Tensor}
  @assert length(args) == num_in_ports(carr)
  interpret(conv, carr, args)
end

"""
Construct `Graph` from `arr`
# Arguments:
- `intens`: tensors (typically placeholders) to act as inputs to arro
                 intens[i] = in_port(arrow, i)
  port_grab:
# Returns
- `graph`: `TensorFlow` `Graph` equivalent to `arr`
"""
function Graph(carr::CompArrow,
               graph,
               intens::Vector{<:Tensor})
  # inputs need to be wrapped in identiy
  intens_wrapped = tf.identity(intens)
  out = interpret(conv, carr, intens_wrapped)
  return @NT(in=intens, out=out, graph=graph)
end

function Graph(carr::CompArrow,
               graph=Graph())
  # inputs need to be wrapped in identiy
  tf.as_default(graph) do
    intens = [placeholder(prt, graph) for prt in ▸(carr)]
    Graph(carr, graph, intens)
  end
end

"Converts a port to a placeholder"
placeholder(prt::Port, graph=tf.get_def_graph()) =
  tf.placeholder(Float32, name="inp_$(prt.port_id)")
  # tf.placeholder(Float32, name=name(prt).name)

# FIXME: Get the type for the placeholder from the type of the port
