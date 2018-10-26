"Distance from `x` to the interval `[a, b]`"
function δinterval(x, a, b)
  ifthenelse(x > b,
         x - b,
         ifthenelse(x < a,
                a - x,
                0))
end
