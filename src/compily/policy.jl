Vertex = Int
# What's wrong?
# - We need to say values connected to source nodes are known
# - We may have to resolve a condition before we can compute anything
# - I think I need to copy known

"Describes execution `Policy` of an `Arrow`: which sub_arrows to execute when"
abstract type Policy end

"Type of node in `Policy`, `compute` = evaluate node, `swtich` branch"
@enum NodeType Branch Compute
