# using Base.Test
# using Arrows
#
# function test_assert()
#   carr = CompArrow(:xyx20, [:x, :y], [:z])
#   x, y, z = ⬨(carr)
#   a = (2x + y)
#   assert!(y > 100)
#   a ⥅ z
#   carr
# end
#
# function test_invert_assert()
#   carr = test_assert()
#   invert(carr)
# end
#
# test_assert()
# test_invert_assert()
