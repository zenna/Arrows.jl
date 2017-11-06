using Arrows
using Base.Test
import Arrows: PropType

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end

function test_prop()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = ⬨(carr)
  initprops = Dict{SubPort, Arrows.PropType}(x=>Arrows.PropType(:size=>Arrows.Size([nothing, 10])),
                                             y=>Arrows.PropType(:size=>Arrows.Size([10, nothing])))
  vals = Arrows.traceprop!(carr, initprops)
end

test_prop()

function test_shape_prop(carr)
  sprts = ▹(carr)
  initprops = Dict{SubPort, Arrows.PropType}(sprt => PropType(:size=>Size([nothing, 10])) for sprt in sprts)
  vals = Arrows.traceprop!(carr, initprops)
end

foreach(test_shape_prop ∘ pre_test, TestArrows.plain_arrows())

function test_value_prop()
  carr = TestArrows.xy_plus_x_carr()
  x, y, z = ⬨(carr)
  res = traceprop!(carr, Dict(x => Arrows.PropType(:value => ConcreteValue(3.2)), y => Arrows.PropType(:value => ConcreteValue(2.3))))
  @test get(resa, z)[:value].value == 3.2 * 2.3 + 3.2
end

test_value_prop()
