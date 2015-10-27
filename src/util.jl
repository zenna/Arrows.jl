type Counter
  X::Int64
end

GLOBAL_COUNTER = Counter(0)
inc(c::Counter) = c.X +=1
genint() = (inc(GLOBAL_COUNTER);GLOBAL_COUNTER.X-1)
genvar(prefix="x") = "$prefix$(genint())"
restart_counter!() = GLOBAL_COUNTER.X = 0

function printers(T::Type)
  @eval print(io::IO, x::$T) = print(io, string(x))
  @eval println(io::IO, x::$T) = println(io, string(x))
  @eval show(io::IO, x::$T) = print(io, string(x))
  @eval showcompact(io::IO, x::$T) = print(io, string(x))
end
