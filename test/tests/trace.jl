using Base.Test
using Arrows

function test_dept(nlayers = 5)
  carr = TestArrows.nested_core(nlayers)
  sarrs = [sub_arrow(carr)]
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
  @test same(xtvals)
  @test same(ytvals)
  @test first(xtvals) != first(ytvals)
end

test_dept()
