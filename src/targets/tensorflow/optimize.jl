
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
- `log_dir`: directory to store data/logs (used by callbacks)
- `optimize`: optimize? (compute grads/change weights)
- `start_i`: what index is this starting at (used by callbacks)
"""
function optimize(step!::Function,
                  writer=SummaryWriter(log_dir),
                  close_writer::Bool=False,
                  pre_callbacks=[]],
                  callbacks=[],
                  post_callbacks=[]],
                  maxiters=1000,
                  cont=partial(max_iters, maxiters=maxiters),
                  resetlog::Bool=True,
                  log_dir::String="",
                  optimize::Bool=True,
                  start_i::Integer=0)
  i = 0
  cb_data = @NT(start_i, i, writer, None, getlog(), optimizer, log_dir, TrainMode.PRE)

  # Called once before optimization
  foreach(cb->apl(cb, cb_data, pre_callbacks)

  while apl(cont, cb_data)
    loss = loss_gen()
    if optimize
      cur_loss, _ = step!()
    end

    cb_data = @NT(start_i, i, writer, loss.data[0], getlog(), optimizer,
                           log_dir, TrainMode.RUN)
    foreach(cb->apl(cb, cb_data), callbacks)
    i += 1
    resetlog && reset_log()
    end
  end

  # Post Callbacks
  cb_data = @NT(start_i, i, writer, None, getlog(), optimizer, og_dir, TrainMode.POST)
  foreach(cb->apl(cb, cb_data), callbacks)
  if close_writer
    writer.close()
  end
end


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
                  optim_args = @NT(tol=1e-5, alg=:LD_MMA),
                  target=Type{TFTarget})
  length(init) == length(▸(carr)) || throw(ArgumentError("Need init value ∀ ▸"))
  ▸idx = indexin(over, ▸(carr))
  @assert !(any(iszero.(▸idx)))
  tfarr = compile(carr, TFTarget)
  sess = tf.Session(tfarr.graph)
  tf.as_default(tfarr.graph) do
    run(sess, global_variables_initializer())
    optimizer = train.AdamOptimizer()
    minimize_op = train.minimize(optimizer, Loss)
    function step!()
      cur_loss, _ = run(sess, [Loss, minimize_op])
      cur_loss
    end
    return optimize(step!=step!)
  end
end

function test_tf_optimize()
  carr = Arrows.TestArrows.xy_plus_x_arr()
  invcarr = aprx_invert(carr)
  # L(x, y) is a
  # Minimize the domain loss
  lossarr = ...
  optimize(lossarr, over, ϵprt, init, callbacks, optim_args, target=TFTarget)
end
