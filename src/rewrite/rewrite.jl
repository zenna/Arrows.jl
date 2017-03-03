# Arrow Rewriting

"Rewrite Rule"
immutable RewriteRule
  left
  Interface
  right
end

function rewrite!(arr::CompArrow, rule::RewriteRule)
end

function invert(arr:CompArrow)
end
