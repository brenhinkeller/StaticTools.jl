# Scalar multiplication
@inline Base.:*(A::DenseStaticArray, c::Number) = c * A
@inline function Base.:*(c::T1, A::DenseStaticArray{T2}) where {T1<:Number, T2<:Number}
    C = similar(A, promote_type(T1, T2))
    @inbounds for i in eachindex(A,C)
        C[i] = A[i]*c
    end
    return C
end

# Matrix multiplication
@inline function Base.:*(A::DenseStaticArray{T1}, B::DenseStaticArray{T2}) where {T1<:Number, T2<:Number}
    # @assert size(A,2) == size(B,1)
    C = similar(A, promote_type(T1, T2), size(A,1), size(B,2))
    mul!(C, A, B)
end

@inline function mul!(C::DenseStaticArray{T}, A::DenseStaticArray, B::DenseStaticArray) where T
    @inbounds for n ∈ axes(C, 2), m ∈ axes(C, 1)
        Cmn = zero(T)
        for k ∈ axes(A, 2)
            Cmn += A[m,k] * B[k,n]
        end
        C[m,n] = Cmn
    end
    return C
end

@inline function mul!(C::DenseStaticArray{T}, A::DenseStaticArray, B::DenseStaticArray, α::Number, β::Number) where T
    @inbounds for n ∈ axes(C, 2), m ∈ axes(C, 1)
        Cmn = zero(T)
        for k ∈ axes(A, 2)
            Cmn += A[m,k] * B[k,n]
        end
        if iszero(β) # Like BLAS, ignore (possibly uninitialized or NaN) C entirely
            C[m,n] = Cmn * α
        else
            C[m,n] = C[m,n] * β + Cmn * α
        end
    end
    return C
end
