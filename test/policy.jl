import Arrows
using Arrows.TestArrows
using Base.Test

function test_policy()
  for arr in Arrows.TestArrows.plain_arrows()
    println("Testing policy: ", name(arr))
    pol = Arrows.DetPolicy(arr)
    @test is_valid(pol)
  end
end

rand_input(arr) = rand(num_in_ports(arr))

function test_interpret()
  for arr in Arrows.TestArrows.plain_arrows()
    println("Testing interpret: ", name(arr))
    pol = Arrows.DetPolicy(arr)
    output = interpret(pol, rand_input(arr)...)
    println("Got: ", output)
  end
end

test_policy()
test_interpret()
