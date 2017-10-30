"Benchmark arrows"
module BenchmarkArrows
using Arrows
import Arrows: add_sub_arr!,
               in_sub_port,
               out_sub_port,
               inv_add,
               inv_mul
include("kinematics/kinematics.jl")
include("invgraphics/voxel_render.jl")
include("invgraphics/util.jl")

all_benchmark_arrows() = [fwd_2d_linkage()]

export fwd_2d_linkage,
       all_example_arrows,
       drawscene
end
