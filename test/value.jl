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
  is_const = Dict(z => isconst)
  propagate!(carr, is_const)
  @test haskey(is_const, x) == false
  @test haskey(is_const, y) == false
  @test is_const[z] == isconst
end
function test_const_2()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = sub_ports(carr)
  is_const = Dict(x => isconst, y => isconst)
  propagate!(carr, is_const)
  @test haskey(is_const, x) == true
  @test haskey(is_const, y) == true
  @test is_const[x] == isconst
  @test is_const[y] == isconst
  @test is_const[z] == isconst
end

test_src_value()
test_const_1()
