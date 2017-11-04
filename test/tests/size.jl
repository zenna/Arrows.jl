import Arrows: unify, Size, UnificationError
using Base.Test

function test_unify_size()
  @test unify(Size, Size(nothing), Size([10, 10])) == Size([10, 10])
  @test unify(Size, Size([nothing, 10]), Size([10, nothing])) == Size([10, 10])
  @test unify(Size, Size([10, nothing, 10, nothing]), Size([10, 10, nothing, nothing])) == Size([10, 10, 10, nothing])
  @test_throws UnificationError unify(Size, Size([10, nothing]), Size([3]), Size([3, 4]))
end

test_unify_size()
