# using Arrows
include("test_arrows.jl")

arr = xy_plus_x()
weakly_connected_components(arr)
sh = Props(in_port(arr, 1)=>Dict(:Shape=>(1,2,3)))
propagate(arr, sh)
