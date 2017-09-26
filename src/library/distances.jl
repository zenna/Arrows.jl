"Distance from `x` to the interval `[a, b]`"
function δinterval(x, a, b)
  ifelse(x > b,
         x - b,
         ifelse(x < a,
                a - x,
                0))
end
