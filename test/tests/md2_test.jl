using Arrows
using Base.Test
using Arrows.TestArrows

function test_SBOX()
  sbox = Arrows.wrap(Arrows.MD2SBoxArrow())
  sbox_inv = sbox |> Arrows.invert
  foreach(0:0xFF) do i
    @test (i |> sbox |> sbox_inv) == i
  end
end

test_SBOX()
