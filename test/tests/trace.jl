using Base.Test
using Arrows
import Arrows: TraceParent, TraceSubPort, TraceSubArrow, TraceValue, down

function test_dept(nlayers = 5)
  carr = TestArrows.nested_core(nlayers)
  sarrs = SubArrow[sub_arrow(carr)]
  parent = carr
  for i = 1:nlayers + 1
    sarr = sub_arrows(parent)[1]
    push!(sarrs, sarr)
    parent = deref(sarr)
  end
  root = TraceParent(carr)
  tparent = root
  tarrs = []
  for sarr in sarrs[2:end]
    tarr = TraceSubArrow(tparent, sarr)
    tparent = down(tparent, sarr)
    push!(tarrs, tarr)
  end

  xtprts = TraceSubPort[]
  ytprts = TraceSubPort[]
  for tarr in tarrs
    push!(xtprts, TraceSubPort(tarr, 1))
    push!(ytprts, TraceSubPort(tarr, 2))
  end
  xtvals = [TraceValue(xtprt) for xtprt in xtprts]
  ytvals = [TraceValue(ytprt) for ytprt in ytprts]

  @test same(xtvals)
  @test same(ytvals)
  @test first(xtvals) != first(ytvals)
end

test_dept()

function test_out_neighbors()
  carr = TestArrows.test_nested()
  tarrs = Arrows.inner_prim_trace_arrows(carr)
  idx = findfirst(tarr -> deref(sub_arrow(tarr)) isa SqrtArrow, tarrs)
  sqrttarr = tarrs[idx]
  tprt = Arrows.out_trace_ports(sqrttarr)[1]
  @test length(Arrows.out_neighbors(tprt)) == 3
  @test length(Arrows.trace_sub_arrows(Arrows.TraceValue(tprt))) == 4
end

test_out_neighbors()
