"Benchmark example arrows"
module BenchmarkArrows
using Arrows
import Arrows: add_sub_arr!,
               in_sub_port,
               out_sub_port,
               inv_add,
               inv_mul
include("kinematics/kinematics.jl")
# include("invgraphics/voxel_render.jl")

all_example_arrows() = [fwd_2d_linkage(),
                        render_arrow()]

export fwd_2d_linkage,
       all_example_arrows,
       drawscene
end
