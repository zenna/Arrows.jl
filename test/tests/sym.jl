using Arrows
using Arrows.TestArrows
import Arrows: sym_interpret, RefnSym

function test_sym(arr)
  arr = invert(TestArrows.xy_plus_x_arr())
  inp = map(RefnSym, ▸(arr))
  constraints(sym_interpret, arr, inp)
end

foreach(test_sym, TestArrows.plain_arrows())

preds = constraints(invert(TestArrows.weird_arr()))
