# Little functions without a home

"Comp"
arrsinside(arr::Arrow) = Set(simpletracewalk(Arrows.name ∘ deref, arr))
