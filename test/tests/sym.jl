using Arrows
using Arrows.TestArrows
import Arrows: sym_interpret

function test_sym()
  arr = invert(TestArrows.xy_plus_x_arr())
  inp = map(RefnSym, ▸(arr))
  interpret(sym_interpret, arr, inp)
  sub_arrows(arr)
end
