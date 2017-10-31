@enum Stage Pre Run Post

apl(f, data) = f(data)

"""
Optimization.
# Arguments
- `step!`: takes a gradient step and returns the loss
- `writer`: Summary writer to log results to tensorboardX
- `close_writer`: Close writer after finish?
- `pre_callbacks`: functions/generators called before optimization
- `callbacks`: functions called with data every iteration, e.g for viz
- `post_callbacks`: functions/generators called after optimization
- `maxiters`: num of iterations
- `cont`: function to determine when to stop (overrides maxiters)
- `resetlog`: reset log data after every iteration if true
- `logdir`: directory to store data/logs (used by callbacks)
- `optimize`: optimize? (compute grads/change weights)
- `start_i`: what index is this starting at (used by callbacks)
"""
function optimize(step!::Function,
                  pre_callbacks=[],
                  callbacks=[],
                  post_callbacks=[],
                  cont=data -> data.i < 100,
                  resetlog::Bool=true,
                  logdir::String="",
                  optimize::Bool=true,
                  start_i::Integer=0)
  i = 0
  cb_data = @NT(start_i=start_i, i=i, Stage=Pre)

  # Called once before optimization
  foreach(cb->apl(cb, cb_data), pre_callbacks)

  while cont(cb_data)
    if optimize
      @show cur_loss = step!()
    end

    cb_data = @NT(start_i=start_i, i=i, Stage=Run, loss=cur_loss)
    foreach(cb->apl(cb, cb_data), callbacks)
    i += 1
    # resetlog && reset_log()
  end
  # Post Callbacks
  cb_data = @NT(start_i=start_i, i=i, Stage=Post)
  foreach(cb->apl(cb, cb_data), post_callbacks)
end

take!(x::Real) = x
take!(x::Array{<:Real}) = x
take!(f::Function) = f()

"""
argmin_θ(ϵprt): find θ which minimizes ϵprt

# Arguments
- `callbacks`: functions to be called
- `over`: ports to optimize over
- `ϵprt`: out port to minimize
- `init`: initial input values
# Result
- `θ_optim`: minimal value of ϵprt found
- `argmin`: argmin of `over` found
"""
function optimize(carr::CompArrow,
                  over::Vector{Port},
                  ϵprt::Port,
                  init::Vector,
                  callbacks=[],
                  target=Type{TFTarget})
  length(init) == length(▸(carr)) || throw(ArgumentError("Need init value ∀ ▸"))
  graph = tf.Graph()
  tf.as_default(graph) do
    intens = Tensor[]
    phs = Dict{Tensor, Int}()
    for (i, prt) in enumerate(▸(carr))
      if prt ∈ over
        push!(intens, tf.Variable(take!(init[i]), name="varinp_$i"))
      else
        # FIXME: Specific type
        ph = tf.placeholder(Float64, name="inp_$i")
        push!(intens, ph)
        phs[ph] = i
      end
    end
    tfarr = Graph(carr, graph, intens)
    ϵid = findfirst(◂(ϵprt.arrow), ϵprt)
    loss = tfarr.out[ϵid]
    sess = tf.Session(graph)
    optimizer = train.AdamOptimizer()
    minimize_op = train.minimize(optimizer, loss)
    run(sess, global_variables_initializer())
    function step!()
      phsvalmap = Dict(ph => take!(init[id]) for (ph, id) in phs)
      cur_loss, _ = run(sess, [loss, minimize_op], phsvalmap)
      cur_loss
    end
    return optimize(step!)
  end
end
