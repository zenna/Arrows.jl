o# Little functions without a home

"Comp"
arrsinside(arr::) = Set(simpletracewalk(Arrows.name ∘ deref, a))
