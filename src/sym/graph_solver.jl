using Spec

"Struct that represents the bipartite graph between variables and constraints"
mutable struct SolverGraph
  variables
  constraints
end

abstract type SolverElement end
struct SolverEdge
  variable::SolverElement
  constraint::SolverElement
  weight::UInt
end

mutable struct SolverVariable
  edges::Set{SolverEdge}
end
mutable struct SolverConstraint
  edges::Set{SolverEdge}
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
  graph = SolverGraph()
  solution = SolverSolution()
  foreach(graph.constraints) do constraint
   propagate!(graph, constraint, solution)
  end
  while !isempty(graph.variables)
    modified = solve_nonzero!(graph, solution)
    modified = modified || solve_single_constraint!(graph, solution)
    modified = modified || mark_highest_degree!(graph, solution)
  end
end

"""When a variable is associated with a single constraint, then we should use that 
constraint to solve the variable"""
function solve_single_constraint!(graph::SolverGraph, solution::SolverSolution)
  for variable ∈ graph.variables
    if length(variable.edges) == 1
      solve!(graph, variable.edges[1], solution)
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
  for variable in graph.variables
    if min_weight(variable) > 0
      remove!(graph, variable, solution)
      return true
    end
  end
  return false
end

"""When we cannot deduce any more variables, we pick the variable with the highest degree"""
function mark_highest_degree!(graph::SolverGraph, solution::SolverSolution)
  @pre !isempty(graph.variables)
  var = sort(collect(graph.variables), by=v->length(v.edges))[end][1]
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

"""Removing a `variable` from the graph propagate the knowledge about it"""
function remove!(graph::SolverGraph, variable::SolverVariable, solution::SolverSolution)
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

function propagate!(graph::SolverGraph, 
                    constraint::SolverConstraint, 
                    solution::SolverSolution)
  if length(constraint.edges) == 1
    variable = constraint.edges[1].variable
    solve!(graph, variable, constraint)
  end
end