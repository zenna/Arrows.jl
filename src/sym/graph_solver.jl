using Spec

abstract type SolverElement end

"Struct that represents the bipartite graph between variables and constraints"
mutable struct SolverGraph
  variables::Dict{Symbol, SolverElement}
  constraints::Set{SolverElement}
  function SolverGraph()
    g = new()
    g.variables = Dict{Symbol, SolverElement}()
    g.constraints = Set{SolverElement}()
    g
  end
end


mutable struct SolverEdge
  variable::SolverElement
  constraint::SolverElement
  weight::Number
  carr::Arrow
  function SolverEdge(variable::SolverElement, 
    constraint::SolverElement, 
    weight::Number)
    edge = new()
    edge.variable = variable
    edge.constraint = constraint
    edge.weight = weight
    edge
  end
end

function SolverEdge(variable::SolverElement, 
    constraint::SolverElement, 
    weight::Number,
    carr::Arrow)
  edge = SolverEdge(variable, constraint, weight)
  edge.carr = carr
  edge
end


mutable struct SolverVariable <: SolverElement
  name::Symbol
  edges::Set{SolverEdge}
  solution::SolverEdge
  function SolverVariable(name)
    v = new()
    v.name = name
    v.edges = Set{SolverEdge}()
    v
  end
end

mutable struct SolverConstraint <: SolverElement
  edges::Set{SolverEdge}
  expr::Expr
  function SolverConstraint(expr)
    c = new()
    c.expr = expr
    c.edges = Set{SolverEdge}()
    c
  end
end

name(v::SolverVariable) = v.name
name(v::SolverConstraint) = v.expr

function Base.show(io::IO, e::SolverEdge)
  print(io, "SolverEdge($(name(e.variable)) -> $(name(e.constraint)))")
end

function add_to!(graph::SolverGraph, sym::Symbol)::SolverVariable
  if sym ∈ keys(graph.variables)
    graph.variables[sym]
  else
    var = SolverVariable(sym)
    graph.variables[sym] = var
  end
end

function add_to!(graph::SolverGraph, exp::Expr)::SolverConstraint
  constraint = SolverConstraint(exp)
  push!(graph.constraints, constraint)
  constraint
end

SolverSolution = Dict{SolverVariable, SolverConstraint}
"""
Algorithm to solve resolve variables using constraints
Graph algorithm
1) While there is a variable with a minimum cost greater than zero: remove that variable
  1.1) If this produce the elimination of a constraint, mark that constraint as unsolved
2) while there is a constraint with a single incoming edge: solve the variable associated using 
  this constraint
  2.1 If when removing the constraint, a variable contains a minimum path greater than zero, remove the 
  variable and mark the constraint as unsolved
3) if there is a variable with a single outgoing edge, solve this variable using the associated constraint
  3.1) Go to 1
4) Mark as independent the variable with the highest degree (pick one at random)
5) go to 1.
"""
function solve_graph(exprs, non_parameters::Set{Symbol})
  graph = build_graph(exprs, non_parameters::Set{Symbol})
  solution = SolverSolution()
  foreach(graph.constraints) do constraint
   propagate!(graph, constraint, solution)
  end
  while !isempty(graph.variables)
    modified = solve_nonzero!(graph, solution)
    modified = modified || solve_single_constraint!(graph, solution)
    modified = modified || mark_highest_degree!(graph, solution)
  end
  map(solution |> keys) do variable
    variable.solution.carr
  end
end

"build a `graph` from a set of expression excluding variables in `non_parameters`"
function build_graph(exprs, non_parameters::Set{Symbol})
  graph = SolverGraph()
  for expr ∈ exprs
    symbols = expr |> collect_symbols |> keys
    constraint = add_to!(graph, expr)
    left, right = map(forward, expr.args[2:end])
    names = merge(left.names, right.names)
    for symbol ∈ symbols
      (symbol ∈ non_parameters) && continue
      variable = add_to!(graph, symbol)
      edge = if names[symbol] != 1
        SolverEdge(variable, constraint, Inf)
      else
        left, right = symbol ∈ keys(left.names) ? (left, right) : (right, left)
        inv_left = partial_invert_to(left.carr, symbol)
        weight = (⬧(inv_left) |> length) - (⬧(left.carr) |> length)
        # using the fact that the output of the `forward` is always named `forward_z`
        # and that was designed to provid composition
        portmap = Dict{Arrows.Port, Arrows.Port}([p1 => p2 for p1 in ◂(right.carr)
                                                          for p2 in ▸(inv_left)
                                                          if name(p1) == name(p2)])
        solver = compose_share_by_name(inv_left, right.carr, portmap)
        SolverEdge(variable, constraint, weight, solver)
      end
      push!(variable.edges, edge)
      push!(constraint.edges, edge)
    end
  end
  graph
end

"""When a variable is associated with a single constraint, then we should use that 
constraint to solve the variable"""
function solve_single_constraint!(graph::SolverGraph, solution::SolverSolution)
  for variable ∈ values(graph.variables)
    if length(variable.edges) == 1
      solve!(graph, first(variable.edges), solution)
      return true
    end
  end
  false
end

"""When the minimim cost of solving a variable is greater than zero, then we set that
variable as independent"""
function solve_nonzero!(graph::SolverGraph, solution::SolverSolution)
  function min_weight(variable::SolverVariable)
    minimum(map(e->e.weight, variable.edges))
  end
  for variable in values(graph.variables)
    if length(variable.edges) > 0 && min_weight(variable) > 0
      remove!(graph, variable, solution)
      return true
    end
  end
  return false
end

"""When we cannot deduce any more variables, we pick the variable with the highest degree"""
function mark_highest_degree!(graph::SolverGraph, solution::SolverSolution)
  @pre !isempty(graph.variables)
  var = sort(graph.variables |> values |> collect, by=v->length(v.edges))[end]
  remove!(graph, var, solution)
  true
end

"Using `constraint` for solving `variable` and propagate this knowledge"
function solve!(graph::SolverGraph, 
                edge::SolverEdge, 
                solution::SolverSolution)
  # TODO: directly return the function to be used based on the constraint
  variable, constraint = edge.variable, edge.constraint
  @pre variable ∉ keys(solution)
  solution[variable] = constraint
  variable.solution = edge
  remove!(graph, constraint)
  remove!(graph, variable, solution)  
end

"remove `constraint` from `graph`"
function remove!(graph::SolverGraph, constraint::SolverConstraint)
  pop!(graph.constraints, constraint)
  for edge in constraint.edges
    pop!(edge.variable.edges, edge)
  end
end

"""Removing a `variable` from the graph propagate the knowledge about it"""
function remove!(graph::SolverGraph, variable::SolverVariable, solution::SolverSolution)
  pop!(graph.variables, variable.name)
  to_propagate = []
  for edge ∈ variable.edges
    constraint = edge.constraint
    to_remove = filter(constraint.edges) do e
      e.variable == variable
    end
    foreach(e->pop!(constraint.edges, e), to_remove)
    if length(constraint.edges) == 0
      warn("Possible incompatible constraint: $(constraint)")
      remove!(graph, constraint)
    end
    if length(constraint.edges) == 1
      push!(to_propagate, constraint)
    end
  end
  for constraint ∈ to_propagate
    propagate!(graph, constraint, solution)
  end
end

"If a `constraint` contains a single edge, solve that edge, and recurse"
function propagate!(graph::SolverGraph, 
                    constraint::SolverConstraint, 
                    solution::SolverSolution)
  if length(constraint.edges) == 1
    edge = first(constraint.edges)
    solve!(graph, edge, solution)
  end
end