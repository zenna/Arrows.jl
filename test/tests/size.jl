import Arrows: meet, Size, MeetError
using Test

function test_meet_size()
  @test meet(Size(nothing), Size([10, 10])) == Size([10, 10])
  @test meet(Size([nothing, 10]), Size([10, nothing])) == Size([10, 10])
  @test meet(Size([10, nothing, 10, nothing]), Size([10, 10, nothing, nothing])) == Size([10, 10, 10, nothing])
  @test_throws MeetError meet(Size([10, nothing]), Size([3]), Size([3, 4]))
end

test_meet_size()
