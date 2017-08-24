"""An Arrow of `I` inputs and `O` outputs

Semantics of this model

# `Arrow`
- There are a finite number of primitive arrows, `PrimArrow`
- Each primitive arrow is unique and uniquely identifiable by a name, globally
- There are a finite number of composite arrows, `CompArrow`
- Each composite arrow is unique and uniquely identifiable by name, globally

# `Ports`
- A `PrimArrow{I, O}` and `CompArrow{I, O}` has `I` and `O` input / output ports
- These I+O Ports are the `boundary` ports of a `CompArrow`
- a `SubPort` which is on a `SubArrow` is not a boundary

# `SubArrow`
- A composite arrow contains a finite number of components: `SubArrow`s
- Each `SubArrow` is unique and uniquely identifiable by name within its parent
- Each `SubArrow` contains a reference to another `PrimArrow` or `CompArrow`
- A `SubPort` is a port of `SubArrow`
- We can `deref`erence it to get the corresponding port on CompArrow / PrimArrow

# `Value`
- All `Port`s that are connected share the same `Value`
- Often it is useful to talk about these `Values` individually
- a `Value` is a set of `Port`s such that there exists an edge between each
  `port ∈ Value`

# `Trace`
- SubArrows can refer to CompArrow's, even the same CompArrow
- In execution and other contexts, it is useful be refer to nested

- In ssummary, three issues
- Arrow = {CompArrow, PrimArrow}
- Component
- Ref
"""
abstract type Arrow{I, O} end

abstract type ArrowRef{I, O} <: Arrow{I, O} end

"Is `arr` a reference?"
is_ref(arr::Arrow) = isa(arr, ArrowRef)
