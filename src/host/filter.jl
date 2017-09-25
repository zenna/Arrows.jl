function expander(short_symb, f_symb)
  plural = Symbol(f_symb, :s)
  fname = Symbol(:get_, plural)
  # @show fname, plural
  quote
  $fname(carr::CompArrow, i::Int) = $f_symb(carr, i)
  $fname(carr::CompArrow, pred, xs...) = filter(pred, $plural(carr))[xs...]
  $fname(carr::CompArrow, pred) = filter(pred, $plural(carr))
  $fname(carr::CompArrow) = $plural(carr)

  $fname(sarr::SubArrow, i::Int) = $f_symb(sarr, i)
  $fname(sarr::SubArrow, pred, xs...) = filter(pred, $plural(sarr))[xs...]
  $fname(sarr::SubArrow, pred) = filter(pred, $plural(sarr))
  $fname(sarr::SubArrow) = $plural(sarr)

  $short_symb = $fname
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

is▸ = is_in_port
is◂ = is_out_port
isϵ = is_error_port
isθ = is_parameter_port

export isθ, is◂, is▸, isϵ
