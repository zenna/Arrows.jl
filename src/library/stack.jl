import Arrows: AbstractNonDetArray, UninterpretedArrow, AbstractDataType,
               ConcreteDataType, EquationalSpec, Arrow

## Example: stack
## ==============
begin
  local abstractstacktyp = AbstractNonDetArray(:stack)
  "Stack ⇝ ():Real"
  local isemptytyp = ExplicitArrowType{1,1}((abstractstacktyp,),
                     (ShapeArray(ConstantVar(Real), FixedLenVarArray{Integer}()),),
                     ConstraintSet())
  # @show isemptytyp
  local isempty = UninterpretedArrow(isemptytyp)


  # local pop = UninterpretedArrow()
  # local equalities = Set([isempty(empty()) == 0, pop(push()) == 0])
  # local spec = isempty >>>
  local spec = EquationalSpec(Set{Arrow}())
  abstractstack = AbstractDataType([isemptytyp], spec)
end

begin
  """
  What kind of thing is a stack.?
  A stack is an n dimensional vector.
  For simplicitly we might say there is no composite data types there's only this thing.
  In a way a stack is just an alias for

  empty ::
  isempty :: (n):Stack ⇝ ():Real
  pop :: (n):Stack ⇝ (n-m):Stack, (m):Real
  top :: (n):Stack ⇝ (m):Real
  push :: (n):Stack, (m):Real ⇝ (n+m):Stack
  """
  local data = ShapeArray(ConstantVar(Real), FixedLenVarArray((:n,)))
  local isemptyarr = partial(eucliddistarr, (_(), [0.0]))
  "This is an implementation of an abstract stack by simply using variable length vectors"
  concatstack = ConcreteDataType(:concatstack, data, [isemptyarr])
end
