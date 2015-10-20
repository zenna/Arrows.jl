## Compilation to Theano
## =====================

"""Theano is a high performance python based library providing automatic
differrentiation, GPU nd-array computations and multiple primitives oriented
towards deep learning."""
module Theano

using PyCall
using Arrows
using Arrows.Library
import Base:convert, call
# @pyimport theano.compile.function as theano_func
@pyimport theano.compile.function as th_function
@pyimport theano.tensor as T
@pyimport theano.tensor.nnet as nnet
@pyimport theano.tensor.nnet.conv as thconv

# function (a::DimShuffleArrow)

# "convert between symbols used for funciton names and theano PyObject functions"
# function applytheanofunc(fname::Symbol, args...)
#   const name2theanofunc =
#     Dict{Symbol, PyObject}(
#       :cos => (T.cos, false),
#       :sin => (T.sin, false),
#       :(+) => (T.add, false),
#       :(-) => (T.sub, false),
#       :dot => (T.dot, false),
#       :conv2d => (thconv.conv2d, false),
#       :relu => (nnet.relu, false),
#       :dimshuffle => (T.dimshuffle, true)
#
#   (th_name, ismethod) = name2theanofunc[fname]
#   if ismethod
#     @assert length(args) == 1 "Cannot call method for multiple objects"
#     args[1][th_name]
#   else
#     th_name(args...)
#   end
# end

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
  @show arrtype
  typ = T.TensorType(dtype="float64", broadcastable=tuple([false for i = 1:n]...))
  TheanoTensorType(typ)
end

"Return vector of theano input variables which correspond to arrow"
function th_inputs(arrseq::Arrows.ArrowSequence)
  ninputs = length(arrseq.inpsymbs)
  ## Create Variable Inputs
  th_inputs = Array(PyObject, ninputs)
  for i = 1:ninputs
    @show varname = string(arrseq.inpsymbs[i])
    th_inputs[i] = convert(TheanoTensorType, inppintype(arrseq, i))(varname)
  end
  th_inputs
end

## Theano handling of arrow funcs
## ==============================

function th_apply(a::Arrows.Library.TrigArrow, inp)
  th_func = T.pymember(name(a))
  th_func(inp)
end

"Get theano variables for outputs of an arrow arrow"
function th_outputs(theano_inputs, arrseq::Arrows.ArrowSequence)
  # Map funcinputs to theano inputs
  symb2pyvar = Dict{Symbol, PyObject}(zip(arrseq.inpsymbs, theano_inputs))

  for arrow in arrseq.arrowsequence
    ## Treat 'clone' specially so not to unnecessarily copy data
    if name(arrow) == :clone
      error("unimplemented")
    else
      args = extract(symb2pyvar, arrow.inpsymbs)
      th_op = th_apply(arrow.arr, args...)

      # There are only two valid scenarios
      # 1. theano returns a list of the same length as number of outputs
      # 2. theano returns a scalar and number of outputs is 1

      # Multiple outputs from theano
      if isa(th_op, Array)
        @assert length(th_op) == length(arrow.outsymbs)
          """$(arrow.name): theano returned $(length(th_op)) outputs but was
          expecting $(length(arrow.outsymbs))"""
        for i = 1:length(arrow.outsymbs)
          haskey(symb2pyvar, arrow.outsymbs[i]) && error("symbol $symb assigned to twice")
          arrow.outsymbs[i]
          symb2pyvar[arrow.outsymbs[i]] = th_op[i]
        end
      else # Single output
        @assert length(arrow.outsymbs) == 1 "was expecting more than 1 output"
        arrow.outsymbs[1]
        symb2pyvar[arrow.outsymbs[1]] = th_op
      end
    end
  end
  @show symb2pyvar
  extract(symb2pyvar, arrseq.outsymbs)
end

"Fully construct theano function from arrow"
function convert(::Type{TheanoFunc}, arrseq::Arrows.ArrowSequence)
  @show inputs = th_inputs(arrseq)
  @show outputs = th_outputs(inputs, arrseq)
  TheanoFunc(th_function.pymember(:function)(inputs, outputs))
end

end
