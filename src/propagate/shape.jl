"Shape of an Array"
struct Shape{T <: Integer, N}
  sizes::Tuple{Vararg{T, N}}
end
