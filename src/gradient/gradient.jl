"Julia function which computes derivative of inputs of `prt.arrow` w.r.t `prt`"
function gradient(prt::Port)
  carr = prt.arrow
  carrjl = julia(carr)
  ◂id = findfirst(◂(carr), prt)
  function ∇carrjl(xs...)
    ReverseDiff.gradient(v -> carrjl(v...)[◂id], [xs...])
  end
  ∇carrjl
end
