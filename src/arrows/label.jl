"Does `port` have `label` `lb`?"
has_port_label(pprops::Props, lb::Label) = lb ∈ pprops.labels
has_port_label(prt::Port, lb::Label) = has_port_label(props(prt), lb)
add_port_label(pprops::Props, lb::Label) = push!(pprops.labels, lb)

"""Code generation for labels
For a particular `label`, e.g., `error` or `parameter` generates
`is_label_port`, `set_label_port!`, `port!`
"""
function label_code_gen(shorthand, super, long)
  set_name = Symbol(:set_, long, :_port!)
  is_name = Symbol(:is_, long, :_port)
  short_set = Symbol(shorthand, :!)
  quote

  "Make `prop` parameter"
  function $set_name(pprop::Props)
    add_port_label(pprop, $(QuoteNode(long)))
  end

  $is_name(pprop::Props) = has_port_label(pprop, $(QuoteNode(long)))
  $is_name(port::Port) = $is_name(props(port))

  $short_set = $set_name

  $is_name(sprt::SubPort) = $is_name(deref(sprt))
  $set_name(port::Port{CompArrow}) = $set_name(props(port))
  $set_name(sprt::SubPort) = $set_name(deref(sprt))

  export $set_name, $is_name, $short_set
  end
end

const std_labels = [@NT(shorthand = :θ, super = :ᶿ, long = :parameter),
                    @NT(shorthand = :ϵ, super = :ᵋ, long = :error)]

for lb in std_labels
  eval(label_code_gen(lb.shorthand, lb.super, lb.long))
end
