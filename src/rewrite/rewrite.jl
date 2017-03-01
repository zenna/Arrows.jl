# Arrow Rewriting

"Rewrite Rule"
immutable RewriteRule
  left
  Interface
  right
end

function rewrite!(arr::CompArrow, rule::RewriteRule)
end


# Invert is a graph rewrite where by
# - Every primitive sub_arrow is replaced by its inverse
# - Unless its a constant
function invert(arr:CompArrow)
end
