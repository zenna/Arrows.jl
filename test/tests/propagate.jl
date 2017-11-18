using Arrows
using Base.Test
import Arrows: AbValues, hasarrtype, traceprop!, ConcreteValue

nosources = filter(arr->!hasarrtype(arr, SourceArrow), TestArrows.plain_arrows())

function pre_test(arr::Arrow)
  println("Testing arrow ", name(arr))
  arr
end

function test_prop()
  carr = TestArrows.xy_plus_x_arr()
  x,y,z = ⬨(carr)
  initprops = Dict{SubPort, Arrows.AbValues}(x=>Arrows.AbValues(:size=>Arrows.Size([nothing, 10])),
                                             y=>Arrows.AbValues(:size=>Arrows.Size([10, nothing])))
  vals = Arrows.traceprop!(carr, initprops)
end

test_prop()

function test_shape_prop(carr)
  sprts = ▹(carr)
  initprops = Dict{SubPort, Arrows.AbValues}(sprt => AbValues(:size=>Size([nothing, 10])) for sprt in sprts)
  vals = Arrows.traceprop!(carr, initprops)
end

foreach(test_shape_prop ∘ pre_test, nosources)

function test_value_prop()
  carr = TestArrows.xy_plus_x_arr()
  x, y, z = ⬨(carr)
  res = traceprop!(carr, Dict(x => Arrows.AbValues(:value => ConcreteValue(3.2)),
                              y => Arrows.AbValues(:value => ConcreteValue(2.3))))
  # @show res
  @test get(res, z)[:value].value == 3.2 * 2.3 + 3.2
end

test_value_prop()
