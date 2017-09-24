using ProgressMeter
using NLopt
using Plots
pyplot()
using NamedTuples
using Arrows

function plot_domain_loss(data::Matrix)
  heatmap(data,
          title = "Spectogram plot of errors",
          xaxis = "Time",
          yaxis = "Primitive loss terms ordered by ")
end
