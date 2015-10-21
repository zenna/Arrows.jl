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

const th_name = Dict{Symbol,Symbol}(
  :+ => :add,
  :- => :sub,
  :/ => :truediv,
  :^ => :pow,
  :* => :mul)

## Theano handling of arrow funcs
## ==============================
function th_apply(a::Arrows.Library.TrigArrow, inp)
  th_func = T.pymember(name(a))
  th_func(inp)
end

function th_apply(a::Arrows.Library.SigmoidArrow, inp)
  th_func = nnet.pymember(name(a))
  th_func(inp)
end

function th_apply(a::Arrows.Library.ArithArrow, x, y)
  th_func = T.pymember(th_name[name(a)])
  th_func(x, y)
end

function th_apply(a::Arrows.Library.ConvArrow, imgs, weights)
  th_func = thconv.pymember(:conv2d)
  th_func(imgs, weights)
end

function th_apply(a::Arrows.Library.DimshuffleArrow, inp)
  inp[:dimshuffle](a.pattern...)
end

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
