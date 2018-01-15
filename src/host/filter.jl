# TODO: This is a illegible, replace with simpler code (without codegen)

function get_ports end
function get_sub_ports end
function get_in_ports end
function get_in_sub_ports end
function get_out_ports end
function get_out_sub_ports end

function expander(short_symb, f_symb)
  plural = Symbol(f_symb, :s)
  fname = Symbol(:get_, plural)
  # @show fname, plural
  quote
  $fname(arr::Arrow, i::Int) = $f_symb(arr, i)
  $fname(arr::Arrow, pred, xs...) = filter(pred, $plural(arr))[xs...]
  $fname(arr::Arrow, pred) = filter(pred, $plural(arr))
  $fname(arr::Arrow) = $plural(arr)

  $fname(sarr::SubArrow, i::Int) = $f_symb(sarr, i)
  $fname(sarr::SubArrow, pred, xs...) = filter(pred, $plural(sarr))[xs...]
  $fname(sarr::SubArrow, pred) = filter(pred, $plural(sarr))
  $fname(sarr::SubArrow) = $plural(sarr)

  # $short_symb = $fname
  export $fname
  export $short_symb
  end
end

fs = [(:⬧, :port)
      (:⬨, :sub_port)
      (:▸, :in_port)
      (:▹, :in_sub_port)
      (:◂, :out_port)
      (:◃, :out_sub_port)]
codes = map(f -> expander(f...), fs)
foreach(eval, codes)

# TODO: Deprecate is(▸)
is▸ = is_in_port
is◂ = is_out_port

get_ports(arr::Arrow, nm::Symbol) = get_ports(arr, prt->name(prt).name == nm)[1]
get_sub_ports(arr::Arrow, nm::Symbol) = get_sub_ports(arr, prt->name(deref(prt)).name == nm)[1]
get_in_ports(arr::Arrow, nm::Symbol) = get_in_ports(arr, prt->name(prt).name == nm)[1]
get_out_ports(arr::Arrow, nm::Symbol) = get_out_ports(arr, prt->name(prt).name == nm)[1]
get_in_sub_ports(arr::Arrow, nm::Symbol) = get_in_sub_ports(arr, prt->name(deref(prt)).name == nm)[1]
get_out_sub_ports(arr::Arrow, nm::Symbol) = get_out_sub_ports(arr, prt->name(deref(prt)).name == nm)[1]

get_ports(arr::Arrow, nms::Vector{Symbol}) = [get_ports(arr, nm) for nm in nms]
get_sub_ports(arr::Arrow, nms::Vector{Symbol}) = [get_sub_ports(arr, nm) for nm in nms]
get_in_ports(arr::Arrow, nms::Vector{Symbol}) = [get_in_ports(arr, nm) for nm in nms]
get_out_ports(arr::Arrow, nms::Vector{Symbol}) = [get_out_ports(arr, nm) for nm in nms]
get_in_sub_ports(arr::Arrow, nms::Vector{Symbol}) = [get_in_sub_ports(arr, nm) for nm in nms]
get_out_sub_ports(arr::Arrow, nms::Vector{Symbol}) = [get_out_sub_ports(arr, nm) for nm in nms]


⬧ = get_ports
⬨ = get_sub_ports
▸ = get_in_ports
▹ = get_in_sub_ports
◂ = get_out_ports
◃ = get_out_sub_ports
