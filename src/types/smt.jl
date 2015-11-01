## Summarise the type issue
For a type that is parametric in dimensionality we need to first get an expression
for each dimension.  This could be (1) a constant (2) a (pure) parameter (3) a transformed parameter.
Ideally, we would convert that into a function that could be called.
However

1. The output type should depend on the input type.
For instance if we apply it to all numbers, we should expect the appropriate nueric type output
If we call it within an SMT variable we expect the SMT variable output

2. We want to be able to partially evaluate that type to create another parametric value.
e..g if we call 2t+p(t=>4) we want 8 + p.

3. The input should satisfy the constraints, and if partially evaluated it should generate new constraints

Unfortunately SMT variables are weird and require passing some context around.
To me this is a horrible API.

And so I have to treat calling an expression with an SMT expression slightly differently.

Desired outcome
2T(t=>3) ===> 6
2T(t=>Var(Integer)) ===> Var(Integer)

One idea is to separate away the idea of a variable.
I've been rebuilding variable classes in many forms, with operations and what not
I have a pretty decent one in Sigma.

"default do nothing"
handle(x) = x

"Convert param to whatever"
handle(v::Variable) = @show :(args[$(QuoteNode(v.name))])

function handle(x::Expr)
  const params = Expr(:parameters, Expr(:kw, :ctx, :ctx))
  Expr(:call, x.args[1], params, [handle(arg) for arg in x.args[2:end]]...)
end

"Lets rewrite"
function SMTify(p::TransformedParameter)
  paramsexpr = handle(p.expr)
  Expr(:(->), :((args::Dict, ctx::Z3.Context)), paramsexpr)
end

"Convert type parameter into something that can be called"
lambarise(p::TransformedParameter) = eval(SMTify(p))


import Z3

"Convert an integer into an SMT integer"
function SMTify(v::Integer, ctx::Z3.Context)
  @show x
  Z3.NumeralAst(Integer, v; ctx=ctx)
end

"Convert a parameter into an SMT variable"
function SMTify{T}(x::Parameter{T}, ctx::Z3.Context)
  @show x
  Z3.Var(Integer; name = string(x.name), ctx=ctx)
end

begin


    Z3.disable_global_ctx!()
    ctx = Z3.Context()
    slv = Z3.Solver(;ctx=ctx)

    ## Construct this map from ports to their dimensions
    # for subarr in nodes(a)
    #   subarrvars = variables(typ(subarr))
    # end
    inport2var = [inport => SMTify(ndims(a, inport), ctx) for inport in subarrowinports(a)]
    outport2var = [outport => SMTify(ndims(a, outport), ctx) for outport in subarrowoutports(a)]

    ## assert that dimensions connected by edges are equal
    for (outp, inp) in edges(a)
      if !(isboundary(outp) | isboundary(inp))
        Z3.add!((==)(outport2var[outp], inport2var[inp];ctx=ctx); solver=slv, ctx=ctx)
      end
    end

    # TOADD
    # - variable dimensions should be positive
    # - variables with same symbol should be the same variable - doofus

    @show Z3.check(;solver=slv, ctx=ctx)
    Z3.del_context(ctx)
    return Nullable{Model}(model)
end
