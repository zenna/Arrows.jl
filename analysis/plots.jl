using ProgressMeter
using NLopt
using Plots
pyplot()
using NamedTuples
using Arrows

## Plotting ##

function plot_spec(data::Matrix)
  heatmap(data,
          title = "Spectogram plot of errors",
          xaxis = "Time",
          yaxis = "Primitive loss terms ordered by ")
end

function test_plot_spec()
  ntimesteps = 10000
  nerrors = 100
  fake_data = rand(nerrors, ntimesteps)
  plot_spec(fake_data)
end

"Plot a loss of the histogram"
function plot_loss_hist(::Vector{Vector{}}, )
end

"Plot loss vs time"
function plot_loss_vs_time(losses::Vector)
end

"Minimize `arr` w.r.t to `loss`"
function loss_stats(arr::Arrow)
  # 1. Randomly initialize theta
  # 2. Compute loss
  # 3. Optimize
  # 4. Return minimum

  # Randomly chosen theta, from what distribution
  θ_init =
  @NT(init_θ = rand(2),
      init_loss = rand(),
      losses = rand(100),
      min_loss = rand())
end

function hist_compare(fwd, invloss, nparams; nsamples=100)
  minlosses = Float64[]

  losses = Float64[]
  @showprogress 1 "Optimizing..." for i = 1:nsamples
    θs = rand(nparams) # FIXME: Not general How to generate random parameter init
    # FIXME: (1) Derive number of parametric inputs
    # FIXME 2. Get gradients=
    opt = Opt(:LN_COBYLA, nparams)

    # FIXME: Do we have any bounds on parameters?
    # lower_bounds!(opt, [-Inf, 0.])
    xtol_rel!(opt, 1e-4)

    min_objective!(opt, invloss)

    # FIXME, save parameter values
    (minf, minx, ret) = optimize(opt, θs)
    println("got $minf at $minx after $count iterations (returned $ret)")
  end
  losses
end
