"Takes no input simple emits a `value::T`"
struct CondArrow <: PrimArrow end
props(::CondArrow) =   [Props(true, :i, Bool),
                             Props(true, :t, Real),
                             Props(true, :e, Real),
                             Props(false, :e, Real)]
name(::CondArrow) = :cond

"ifelse(i, t, e)`"
struct IfElseArrow <: PrimArrow end
props(::IfElseArrow) =   [Props(true, :i, Bool),
                          Props(true, :t, Real),
                          Props(true, :e, Real),
                          Props(false, :y, Real)]
name(::IfElseArrow) = :ifelse
abinterprets(::IfElseArrow) = [sizeprop]

function inv(arr::IfElseArrow, sarr::SubArrow, idabv::IdAbValues)
  constin = const_in(arr, idabv)
  # @show idabv

  if constin[2] && constin[3]
    warn("fixme")
    # idabv[2][:value] != idabv[3][:value] || throw(ArgumentError("Constness Combination not supported"))
    # no e! could have been no t but chose arbitrarily, ramifications?
    invifelse_teconst(), Dict(:i => :i, :t => :t, :e => :e, :y => :y)
  elseif constin[2]
    invifelse_tconst(), Dict(:i => :i, :t => :t, :e => :e, :y => :y)
  elseif constin[3]
    invifelse_econst(), Dict(:i => :i, :t => :t, :e => :e, :y => :y)
  elseif all(i->!constin[i], port_id.(get_in_ports(arr)))
    invifelse_fullpi(), Dict(:i => :i, :t => :t, :e => :e, :y => :y)
  else
    # @show constin
    # @show idabv
    throw(ArgumentError("Constness Combination not supported"))
  end
end

"`t`then and `e` else constant but not same"
function invifelse_teconst_diff()
  carr = CompArrow(:invifelse_teconst_diff, [:y, :t], [:i])
  y, t, i = ⬨(carr)
  ii = ifelse(EqualArrow()(y, t), true, false)
  ii ⥅ i
  @assert is_wired_ok(carr)
  carr
end

"`t`then and `e` else constant but not same"
function invifelse_teconst()
  carr = CompArrow(:invifelse_teconst, [:y, :t, :e, :θi], [:i])
  y, t, e, θi, i = ⬨(carr)
  ii = ifelse(EqualArrow()(y, t),
              ifelse(EqualArrow()(y, e),
                     θi,
                     true),
              ifelse(EqualArrow()(y, e),
                      false,
                      false))   # domain error

  ii ⥅ i
  @assert is_wired_ok(carr)
  carr
end

function invifelse_tconst()
  carr = CompArrow(:invifelse_tconst, [:y, :t, :θi, :θmissing], [:i, :e])
  y, t, θi, θmissing, i, e = ⬨(carr)
  ii = ifelse(EqualArrow()(y, t), θi, false)
  ii ⥅ i
  ifelse(ii, θmissing, y) ⥅ e
  @assert is_wired_ok(carr)
  carr
end

function invifelse_econst()
  carr = CompArrow(:invifelse_econst, [:y, :e, :θi, :θmissing], [:i, :t])
  y, e, θi, θmissing, i = ⬨(carr)
  ii = ifelse(EqualArrow()(y, e), θi, true)
  ii ⥅ i
  ifelse(ii, y, θmissing) ⥅ e
  @assert is_wired_ok(carr)
  carr
end

function invifelse_fullpi()
  carr = CompArrow(:invifelse_fullpi, [:y, :θi, :θmissing], [:i, :t, :e])
  y, θi, θmissing, i, t, e = ⬨(carr)
  θi ⥅ i
  ifelse(θi, y, θmissing) ⥅ t
  ifelse(θi, θmissing, y) ⥅ e
  @assert is_wired_ok(carr)
  carr
end
