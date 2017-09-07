using Base.Test
using Arrows.TestArrows
import Arrows: name, is_wired_ok

function test_valid()
  for arr in Arrows.TestArrows.all_test_arrows()
    println("Testing ", name(arr))
    @test is_wired_ok(arr)
  end
end
