import NLopt
import NLopt: optimize
import ReverseDiff

@enum Stage Pre Run Post

apl(f, data) = f(data)
take!(x::Real) = x
take!(x::Array{<:Real}) = x
take!(f::Function) = f()
take1(rep) = collect(Base.Iterators.take(rep, 1))[1]

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
function optimize(step!::Function;
                  pre_callbacks=[],
                  callbacks=[],
                  post_callbacks=[],
                  cont=data -> data.i < 100000,
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

"Construct loss julia function"
function lossjl(▸idx, init, ϵprt::Port, callbacks)
  carrjl = julia(ϵprt.arrow)
  ∇carrjl = gradient(ϵprt)
  input = copy(init)
  ϵid = findfirst(◂(ϵprt.arrow), ϵprt)
  @assert ϵid != 0
  iter = 0
  function invlossf(θs::Vector, grad::Vector)
    @assert length(θs) == length(▸idx)
    for (i, id) in enumerate(▸idx)
      input[id] = θs[i]
    end
    output = carrjl(input...)
    if length(grad) > 0
      grads = ∇carrjl(input...)
      for (i, id) in enumerate(▸idx) # Update gradients
        grad[i] = grads[id]
      end
    end
    loss = output[ϵid]
    for cb in callbacks # Call all callbacks
      cb(@NT(input = input,
             output = output,
             loss = loss,
             iter = iter))
    end
    iter = iter + 1
    loss
  end
end

"Construct optimization object"
function gen_opt(loss, nparams, optim_args)
  opt = NLopt.Opt(optim_args.alg, nparams)
  NLopt.xtol_rel!(opt, optim_args.tol)
  NLopt.min_objective!(opt, loss)
  opt
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
                  init::Vector;
                  callbacks=[],
                  optim_args = @NT(tol=1e-5, alg=:LD_MMA))
  length(init) == length(▸(carr)) || throw(ArgumentError("Need init value ∀ ▸"))
  ▸idx = indexin(over, ▸(carr)) # ids of ports we're optimizing over
  @assert !(any(iszero.(▸idx)))
  loss = lossjl(▸idx, init, ϵprt::Port, callbacks)
  opt = gen_opt(loss, length(over), optim_args)
  init_over = [init[i] for i in ▸idx]
  (min, argmin, ret) = NLopt.optimize(opt, init_over)
  @NT(min = min, argmin = argmin, ret = ret)
end
