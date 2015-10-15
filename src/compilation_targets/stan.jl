## Compilation to Stan math library
## ================================

module Stan
using Arrows

const header = """
#pragma once

#include <tuple>

using Eigen::Matrix;
using Eigen::Dynamic;
"""

typealias CppExpr ASCIIString

function convert(::Type{CppExpr}, a::Arrows.ArrayType)
  n = ndims(a)
  if n == 1
    "Matrix<T, Dynamic, 1>"
  elseif n == 2
    "Matrix<T, Dynamic, Dynamic>"
  else
    error("Cannot convert matrices with dim higher than 2 to Stan")
  end
end

function convert(::Type{CppExpr}, f::Arrows.FuncDef)
  args = join(["const Matrix<T, Dynamic, Dynamic>  &$(inp)" for inp in f.inputsymbs], ",")
  code = [convert(CppExpr, fcall) for fcall in f.calls]
  codes = join(code,"\n")
  retargs = join([out for out in f.outputsymbs], ",")

  ret = "return std::make_tuple($retargs);"
  """template <typename T>
  const auto $(f.name)($args) {
    $codes
    $ret
  }"""
end

"Convert a CallExpr into Cpp code (as a string)"
function convert(::Type{CppExpr}, x::Arrows.CallExpr)
  tuple_var = string("tpl_", join(x.outputsymbs, "_"))
  args = join(x.inputsymbs, ",")
  callf = "auto $tuple_var = $(x.name)($args);"
  unpack = ["$(convert(CppExpr, x.outputtypes[i])) $(x.outputsymbs[i]) = std::get<$(i-1)>($tuple_var);" for i = 1:length(x.outputsymbs)]
  join(vcat(callf, unpack), "\n")
end

end
