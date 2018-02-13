

"Are all targets found?"
all_targets_found(targets::Vector{SubPort}, xabv::XAbValues) =
  all((tgt ∈ keys(xabv) for tgt in targets)...)


# What to return form these choices
# 1. 

"""
All parametric choices associated with `arr` under information `xabv`
"""
function choices(arr::Arrow, xabv::XAbValues)
end

"Select first choice"
firstchoice(choices::Vector) = first(choices)

""
choose_param_values(choice) = ...

"Pointwise propagation (get a better name)

# Arguments
- `targets`: Targets whose values are desired
- `xabv`: Initial beliefs
- `cont`: 
"
function pointwise_prop(arr::Arrow,
                        targets::Vector{SubPort},
                        xabv::XAbValues;
                        cont = all_targets_found,
                        decision_procedure = firstchoice,
                        choose_thetas = rand_thetas)
  propagate(arr)
  while cont()
    choices_ = choices(arr, xabv)
    choice = decision_procedure(choices)
    thetas = choose_thetas(choice)
    xabv = update(thetas, xabv)
    xabv = propagate(xabv)
  end
end
