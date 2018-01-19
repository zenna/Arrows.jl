using Arrows
using Base.Test
using Arrows.TestArrows
using AlioZoo

function test_SBOX()
  sbox = Arrows.wrap(Arrows.MD2SBoxArrow
  sbox_inv = sbox |> Arrows.invert
  foreach(0:0xFF) do i
    @test (i |> sbox |> sbox_inv) == i
  end
end

test_SBOX()

function test_pipeline()
  carr = AlioZoo.md2hash(2)
  inv_carr = carr |> invert
  wired, wirer = Arrows.solve_md2(inv_carr)
  context = Dict{Symbol, Any}()
  solved, unsolved, context = Arrows.find_unsolved_constraints(carr, inv_carr,
                                                              wirer, context)
  newcontext = Dict{Symbol, Any}([:θi => false, :θi1 => false])
  extra_wirers = solve_with_ifelse(unsolved, newcontext, wirer)
  unified = compose_by_name([wirer, extra_wirers...])
  [ensure_link_to_parent(sprt) for sarr in sub_arrows(unified)
                               for sprt in ◃(sarr)]
  solved, unsolved, context = find_unsolved_constraints(carr, inv_carr,
                                                        unified, newcontext)
  @show unsolved
end
