using Arrows
using Base.Test
using Arrows.TestArrows
using Base.Test


function test_src_value()
  x,y,z = sub_ports(TestArrows.xy_plus_x_arr())
  @test same(Arrows.SrcValue.(Arrows.out_neighbors(x)))
end


function test_const_1()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = sub_ports(carr)
  is_const = Dict(z => known_const)
  propagate!(carr, is_const, const_propagator!)
  @test haskey(is_const, x) == false
  @test haskey(is_const, y) == false
  @test is_const[z] == known_const
end
function test_const_2()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = sub_ports(carr)
  is_const = Dict(x => known_const, y => known_const)
  propagate!(carr, is_const, const_propagator!)
  @test haskey(is_const, x) == true
  @test haskey(is_const, y) == true
  @test is_const[x] == known_const
  @test is_const[y] == known_const
  @test is_const[z] == known_const
end

function test_const_srcarrow()
  c = AddArrow() >> SinArrow()
  one = add_sub_arr!(c, SourceArrow(1))
  x, y =  in_sub_port(c, 1), in_sub_port(c, 2)
  link_ports!(out_sub_port(one, 1), y)
  is_const = Dict{SubPort, Const}()
  propagate!(c, is_const, const_propagator!)
  @test haskey(is_const, y)
  @test haskey(is_const, x) == false
end

test_src_value()
test_const_1()
test_const_2()
test_const_srcarrow()
