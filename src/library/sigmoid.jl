# Sigmoid Functiosn #

"Standard Logistic"
logistic(x) = 1 / (1 + exp(-x))

# We want a function which is zero at zero
# function smootherstep(x)
#   if x <= zero(0)
#     zero(x)
#   elseif x >= one(x)
#     one(x)
#   else
#     6x^5 - 15x^4 + 10x^3
#   end
# end

"Smooth step with zero 1st and 2nd order derivatives at x=0 and x=1"
smootherstep(x) = ifthenelse(x <= 0, 0, ifthenelse(x >= 1, 1.0, 6x^5 - 15x^4 + 10x^3))

"""
Sigmoid with tanh
src: https://www.j-raedler.de/2010/10/smooth-transition-between-functions-with-tanh/""
"""
tanhsig(x, a = 1.0, b = 1.0) = 0.5 + 0.5tanh((x - a) / b)
