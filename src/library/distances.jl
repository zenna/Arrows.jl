"Distance to the interval `[a, b]`"
function δinterval(x, a, b)
  ifelse(x > b,
         x - b,
         ifelse(x < a,
                a - x,
                0))
end

# Sigmoid Functiosn #

"Standard Logistic Function"
logistic(x) = 1 / (1 + exp(-x))
logistic(0)

# We want a function which is zero at zero
function smootherstep(x)
  if x <= zero(0)
    zero(x)
  elseif x >= one(x)
    one(x)
  else
    6x^5 - 15x^4 + 10x^3
  end
end

function smootherstep(x)
  ifelse(x <= 0, 0, ifelse(x >= 1, 1.0, 6x^5 - 15x^4 + 10x^3))
end
