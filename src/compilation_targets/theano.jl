## Compilation to Theano
## =====================

"""Theano is a high performance python based library providing automatic
differrentiation, GPU nd-array computations and multiple primitives oriented
towards deep learning."""
module Theano

using PyCall
using Arrows
import Base:convert, call
# @pyimport theano.compile.function as theano_func
@pyimport theano.compile.function as th_function
@pyimport theano.tensor as T
@pyimport theano.tensor.nnet as nnet
@pyimport theano.tensor.nnet.conv as thconv

"convert between symbols used for funciton names and theano PyObject functions"
const name2theanofunc =
  Dict{Symbol, PyObject}(
    :cos => T.cos,
    :sin => T.sin,
    :(+) => T.add,
    :(-) => T.sub,
    :dot => T.dot,
    :conv2d => thconv.conv2d,
    :relu => nnet.relu)

"Return a set of values from a dictionary from a vector of keys"
extract{A,B}(x::Dict{A, B}, v::Vector{A}) = B[x[val] for val in v]

"A Theano Function.  Represents a compiled arrow"
immutable TheanoFunc
  func::PyObject
end

call(t::TheanoFunc, x...) = call(t.func, x...)

"A Theano Tensor Type - i.e. n-dimensional array type"
immutable TheanoTensorType
  typ::PyObject
end

call(t::TheanoTensorType, name::ASCIIString) = t.typ(name)

function convert(::Type{TheanoTensorType}, arrtype::Arrows.ArrayType)
  @show n = ndims(arrtype)
  typ = T.TensorType(dtype="float64", broadcastable=tuple([false for i = 1:n]...))
  TheanoTensorType(typ)
end

"Return vector of theano input variables which correspond to funcdef"
function th_inputs(funcdef::Arrows.FuncDef)
  ninputs = length(funcdef.inputsymbs)
  ## Create Variable Inputs
  th_inputs = Array(PyObject, ninputs)
  for i = 1:ninputs
    @show varname = string(funcdef.inputsymbs[i])
    th_inputs[i] = convert(TheanoTensorType, funcdef.inputtypes[i])(varname)
  end
  th_inputs
end

"Get theano variables for outputs of an arrow funcdef"
function th_outputs(theano_inputs, funcdef::Arrows.FuncDef)
  ## Create Variable Inputs
  # theano_inputs = th_inputs(funcdef)

  # Map funcinputs to theano inputs
  symb2pyvar = Dict{Symbol, PyObject}(zip(funcdef.inputsymbs, theano_inputs))

  for fcall in funcdef.calls
    ## Treat 'clone' specially so not to unnecessarily copy data
    if fcall.name == :clone
      error("unimplemented")
    else
      args = extract(symb2pyvar, fcall.inputsymbs)
      th_op = name2theanofunc[fcall.name](args...)

      # There are only two valid scenarios
      # 1. theano returns a list of the same length as number of outputs
      # 2. theano returns a scalar and number of outputs is 1

      # Multiple outputs from theano
      if isa(th_op, Array)
        @assert length(th_op) == length(fcall.outputsymbs)
          """$(fcall.name): theano returned $(length(th_op)) outputs but was
          expecting $(length(fcall.outputsymbs))"""
        for i = 1:length(fcall.outputsymbs)
          haskey(symb2pyvar, fcall.outputsymbs[i]) && error("symbol $symb assigned to twice")
          fcall.outputsymbs[i]
          symb2pyvar[fcall.outputsymbs[i]] = th_op[i]
        end
      else # Single output
        @assert length(fcall.outputsymbs) == 1 "was expecting more than 1 output"
        fcall.outputsymbs[1]
        symb2pyvar[fcall.outputsymbs[1]] = th_op
      end
    end
  end
  @show symb2pyvar
  extract(symb2pyvar, funcdef.outputsymbs)
end

"Fully construct theano function from funcdef"
function convert(::Type{TheanoFunc}, funcdef::Arrows.FuncDef)
  @show inputs = th_inputs(funcdef)
  @show outputs = th_outputs(inputs, funcdef)
  TheanoFunc(th_function.pymember(:function)(inputs, outputs))
end

end
