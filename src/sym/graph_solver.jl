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


struct SolverEdge
  variable::SolverElement
  constraint::SolverElement
  weight::UInt
end

mutable struct SolverVariable <: SolverElement
  name::Symbol
  edges::Set{SolverEdge}
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

function SolverEdge(variable::SolverVariable, constraint::SolverConstraint)::SolverEdge
  SolverEdge(variable, constraint, 0)
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
  solution
end

"build a `graph` from a set of expression excluding variables in `non_parameters`"
function build_graph(exprs, non_parameters::Set{Symbol})
  graph = SolverGraph()
  for expr ∈ exprs
    !isempty(setdiff(collect_calls(expr), valid_calls)) && continue
    symbols = expr |> collect_symbols |> keys
    constraint = add_to!(graph, expr)
    for symbol ∈ symbols
      (symbol ∈ non_parameters) && continue
      variable = add_to!(graph, symbol)
      edge = SolverEdge(variable, constraint)
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
  remove!(graph, constraint)
  remove!(graph, variable, solution)  
end

"remove `constraint` from `graph`"
function remove!(graph::SolverGraph, constraint::SolverConstraint)
  @grab graph
  pop!(graph.constraints, constraint)
  for edge in constraint.edges
    @grab edge
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
    map(e->remove!(constraint.edges, e), to_remove)
    if length(constraint.edge) == 0
      warn("Possible incompatible constraint: $(constraint)")
      remove!(graph, constraint)
    end
    if length(constraint.edge) == 1
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
    variable = constraint.edges[1].variable
    solve!(graph, variable, constraint)
  end
end