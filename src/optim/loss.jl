"A Plain port is neither a parameter port nor an error port"
is_plain_port(port::Port) = !(is_parameter_port(port) || is_error_port(port))

"In ports that are plain"
plain_in_ports(arr) = filter(is_plain_port, in_ports(arr))

"f(x, y) = (x - y)^2 sqrt"
function diff_arrow()
  carr = SubtractArrow() >> SqrArrow() >> SqrtArrow()
  rename!(carr, :diff)
  set_error_port!(out_port(carr, 1))
  carr
end

"Arrow `arr: x_1::T, x_2::T -> Real` which compares two inputs of type `T`"
δ(T::DataType) = diff_arrow()

"mean()"
make_error_accum(Ts::Vector{DataType}) =
  stack(map(δ, Ts)...) >> MeanArrow(length(Ts))

"δ(fwd(inv(y)), y)"
function iden_loss(fwd::Arrow, inv::Arrow)::Arrow
  inv_fwd = inv >> fwd
  diffs = make_error_accum(map(typ, out_ports(inv_fwd)))
  plain = plain_in_ports(inv_fwd)
  dupl_inv_fwd = dupl_first(inv_fwd, plain)
  dupl_inv_fwd >> diffs
end
