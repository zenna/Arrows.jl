immutable AddArrow <: PrimArrow{2, 1} end
name(::AddArrow) = :+

immutable MinusArrow <: PrimArrow{2, 1} end
name(::MinusArrow) = :-

immutable MulArrow <: PrimArrow{2, 1} end
name(::MulArrow) = :*

immutable SqrtArrow <: PrimArrow{1, 1} end
name(::SqrtArrow) = :*
