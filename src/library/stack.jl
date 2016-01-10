import Arrows: AbstractNonDetArray, UninterpretedArrow, AbstractDataType,
               ConcreteDataType, EquationalSpec, Arrow

## Example: stack
## ==============
begin
  local abstractstacktyp = AbstractNonDetArray(:stack)
  "Stack ⇝ ():Real"
  local isemptytype = ExplicitArrowType{1,1}(
                     (abstractstacktyp,),
                     (ShapeArray(ConstantVar(Real), FixedLenVarArray{Integer}()),),
                     ConstraintSet())
  # @show isemptytype
  local isemptyuarr = UninterpretedArrow(isemptytype)
  "Stack ⇝ ():Real"
  local poptype = ExplicitArrowType{1,2}(
                     (abstractstacktyp,)
                     (abstractstacktyp, (ShapeArray(ConstantVar(Real), FixedLenVarArray((:n))),)),
                     ConstraintSet())
  local popuarr = UninterpretedArrow(poptype)

  local pushtype = ExplicitArrowType{2,1}(
                     (abstractstacktyp, (ShapeArray(ConstantVar(Real), FixedLenVarArray((:n))),)),
                     (abstractstacktyp,),
                     ConstraintSet())
  local pushuarr = UninterpretedArrow(pushtype)

  ## So we'll describe the
  push >>> pop >>> concatarr

  local s = ForallVar()
  local i = ForallVar()
  local spec1 = isempty(empty())
  local spec2 = !isempty(push(s, i))
  local spec3 = (push >> pop)(s, i) == (s, i)
  local spec = EquationalSpec(Set{Arrow}(spec1, spec2, spec3, spec4))
  abstractstack = AbstractDataType([isemptytype], spec)
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


## TODO
# - what kind of thing is emptystack? - a nullary function? or what
#
