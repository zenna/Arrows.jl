module Targets

export Target

"A Compilation / Interpretation Target"
abstract type Target end

"Generate an expression"
function expr end

end