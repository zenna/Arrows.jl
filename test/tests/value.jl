using Arrows
using Base.Test
using Arrows.TestArrows
using Base.Test


function test_src_value()
  x,y,z = ⬨(TestArrows.xy_plus_x_arr())
  @test same(Arrows.SrcValue.(Arrows.out_neighbors(x)))
end


function test_const_1()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = ⬨(carr)
  is_const = Dict(z => known_const)
  propagate!(carr, is_const, const_propagator!)
  @test haskey(is_const, x) == false
  @test haskey(is_const, y) == false
  @test is_const[z] == known_const
end
function test_const_2()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = ⬨(carr)
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
  x, y =  ▹(c, 1), ▹(c, 2)
  (one, 1) ⥅ y
  is_const = Dict{SubPort, Const}()
  propagate!(c, is_const, const_propagator!)
  @test haskey(is_const, y)
  @test haskey(is_const, x) == false
end

function test_const_recursive()
  arr = fibonnaci_arr()
  is_const = Dict{SubPort, Const}()
  propagate!(arr, is_const, const_propagator!)
  wrap, one, min, ite, eq, add = sub_arrows(arr)
  @test length(is_const) == 4
  @test haskey(is_const, ▹(eq, 2))
  @test haskey(is_const, ◂(one, 1))
  @test haskey(is_const, ▹(ite, 2))
  @test haskey(is_const, ▹(min, 2))
end

test_src_value()
test_const_1()
test_const_2()
test_const_srcarrow()
test_const_recursive()
