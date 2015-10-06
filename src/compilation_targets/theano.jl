## Compilation to Theano
## =====================

using PyCall
@pyimport theano.compile.function as f
@pyimport theano.tensor as T

thfunction = f.zfunction

x = pycall(T.dscalar, PyAny, "x")
y = pycall(T.dscalar, PyAny, "y")
z = x[:__add__](y)

op = thfunction([x,y], z)

"A Theano Function.  Represents a compiled arrow"
immutable TheanoFunc
  func::PyObject
end

function convert(TheanoFunc, funcdef::FuncDef)
end
