using Base.Test
using Arrows.TestArrows
import Arrows: name, is_valid

function test_valid()
  for arr in Arrows.TestArrows.all_test_arrows()
    println("Testing ", name(arr))
    @test is_valid(arr)
  end
end

test_valid()
