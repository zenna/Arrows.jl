## Compilation to Theano
## =====================

# x = pycall(T.dscalar, PyAny, "x")
#
# Arrows.CallExpr(:clone,[:x0],[:x1,:x2],[Arrows.ArrayType((Arrows.TypeVariable(:N),)),Arrows.ArrayType((Arrows.TypeVariable(:N),))])
# Arrows.CallExpr(:sin,[:x1],[:x3],[Arrows.ArrayType((Arrows.TypeVariable(:N),))])
# Arrows.CallExpr(:sin,[:x2],[:x4],[Arrows.ArrayType((Arrows.TypeVariable(:N),))])
# Arrows.CallExpr(:sin,[:x3],[:x5],[Arrows.ArrayType((Arrows.TypeVariable(:N),))])
# Arrows.CallExpr(:sin,[:x4],[:x6],[Arrows.ArrayType((Arrows.TypeVariable(:N),))])
# Arrows.CallExpr(:cos,[:x5],[:x7],[Arrows.ArrayType((Arrows.TypeVariable(:N),))])


module Theano
  using PyCall
  using Arrows
  import Base:convert
  @pyimport theano.compile.function as f
  @pyimport theano.tensor as T
  #
  # thfunction = f.zfunction
  #
  # x = pycall(T.dscalar, PyAny, "x")
  # y = pycall(T.dscalar, PyAny, "y")
  # z = x[:__add__](y)
  #
  # op = thfunction([x,y], z)

  "A Theano Function.  Represents a compiled arrow"
  immutable TheanoFunc
    func::PyObject
  end

  "A Theano Tensor Type - i.e. n-dimensional array type"
  immutable TheanoTensorType
    typ::PyObject
  end

  call(t::TheanoTensorType, name::ASCIIString) = t.typ(name)

  function convert(::Type{TheanoTensorType}, arrtype::Arrows.ArrayType)
    n = ndims(arrtype)
    typ = T.TensorType(dtype="float64", broadcastable=tuple([false for i = 1:n]...))
    TheanoTensorType(typ)
  end

  function th_inputs(funcdef::Arrows.FuncDef)
    ninputs = length(funcdef.inputsymbs)
    ## Create Variable Inputs
    th_inputs = Array(PyObject, ninputs)
    for i = 1:ninputs
      varname = string(funcdef.inputsymbs[i])
      th_inputs[i] = convert(TheanoTensorType, funcdef.inputtypes[i])(varname)
    end
    th_inputs
  end

  function convert(TheanoFunc, funcdef::Arrows.FuncDef)
    ## Create Variable Inputs
    inputs = th_inputs(funcdef)
    symb2pyvar = Dict{Symbol, PyObject}()
    
    th_inputs
  end
end
