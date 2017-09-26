import NLopt

"Construct loss julia function"
function lossjl(▸idx, init, ϵprt::Port, callbacks)
  carrjl = julia(ϵprt.arrow)
  input = copy(init)
  ϵid = findfirst(◂(ϵprt.arrow), ϵprt)
  @assert ϵid != 0
  function invlossf(θs::Vector, grad::Vector)
    @assert length(θs) == length(▸idx)
    for (i, id) in enumerate(▸idx)
      input[id] = θs[i]
    end
    output = carrjl(input...)
    loss = output[ϵid]
    for cb in callbacks
      cb(@NT(input = input,
             output = output,
             loss = loss))
    end
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
- `θ_optim`: values for
"""
function optimize(carr::CompArrow,
                  over::Vector{Port},
                  ϵprt::Port,
                  init::Vector;
                  callbacks=[],
                  optim_args = @NT(tol=1e-4, alg=:LN_COBYLA))
  length(init) == length(▸(carr)) || throw(ArgumentError("Need init value ∀ ▸"))
  ▸idx = indexin(over, ▸(carr))
  @assert !(any(iszero.(▸idx)))
  loss = lossjl(▸idx, init, ϵprt::Port, callbacks)
  opt = gen_opt(loss, length(over), optim_args)
  init_over = [init[i] for i in ▸idx]
  (minf, minx, ret) = NLopt.optimize(opt, init_over)
end
