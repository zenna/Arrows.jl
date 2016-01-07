

# Inversion
# =========

# - convert invertible function into its parameteric inverse
# -

function inv{I, O}(a::CompositeArrow{I, O})
  # Replace subarrows by inverse
  # undirect arrows.
end

"Invert an invertible arrow"
function inv(a::UnaryArithArrow)
  inverses = Dict(:* => :/, :/ => :*, :+ => :-, :- => :+, :^ => :log, :log => :^)
  inverse_f = inverses(a.name)
  if a.name == :- && a.isnumfirst == true
    return a
  elseif a.name == :- && a.isnumfirst == false
    return UnaryArithArrow{T}(:+, a.value, false)
  elseif a.name == :+
    # y = x + 3 => x = y - 3
    return UnaryArithArrow{T}(:-, a.value, false)
  elseif a.name == :*
    # y = x * 3 => x = y/3
    return UnaryArithArrow{T}(:/, a.value, false)
  elseif a.name == :/ && a.isnumfirst == true
    # y = 3/x => x = 3/y
    return UnaryArithArrow{T}(:/, a.value, true)
  elseif a.name == :/ && a.isnumfirst == false
    # y = x/3 => x = 3y
    return UnaryArithArrow{T}(:*, a.value, true)
  elseif a.name == :^ && a.isnumfirst == true
    # y = 3 ^ x => x = log_3(y)
    return UnaryArithArrow{T}(:log, a.value, true)
  elseif a.name == :^ && a.isnumfirst == false
    # y = x ^ 3 => x = log_y(3)
    return UnaryArithArrow{T}(:log, a.value, false)
  elseif a.name == :log && a.isnumfirst == true
    # y = log_2(x) => x = 2^y
    return UnaryArithArrow{T}(:^, a.value, true)
  elseif a.name == :log && a.isnumfirst == false
    # y = log_x(2) => x = 2^(1/y)
    return invarrow >> UnaryArithArrow{T}(:^, a.value, true)
  else
    error("unsupported case")
  end
end

"Invert a binary arithmetic arrow"
function inv(a::ArithArrow)
  if a.name == :+
    over(clone(2)) >>> under(addarr)
  end
end
