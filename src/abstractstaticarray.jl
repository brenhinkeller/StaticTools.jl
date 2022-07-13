
    # General array interface

    # Supertype for all arrays in this package
    abstract type DenseStaticArray{T,N} <: DenseArray{T,N} end

    # A subtype for arrays that are backed by a pointer, length, and size alone
    abstract type DensePointerArray{T,N} <: DenseStaticArray{T,N} end

    # Lightweight type for taking a view into an existing array
    struct ArrayView{T,N} <: DensePointerArray{T,N}
        pointer::Ptr{T}
        length::Int
        size::NTuple{N, Int}
    end


    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, a::DensePointerArray) where {T} = Ptr{T}(a.pointer)
    @inline Base.pointer(a::DensePointerArray) = a.pointer
    @inline Base.length(a::DensePointerArray) = a.length
    @inline Base.sizeof(a::DensePointerArray{T}) where {T} = a.length * sizeof(T)
    @inline Base.size(a::DensePointerArray) = a.size


    # Some of the AbstractArray interface:
    @inline Base.IndexStyle(::DenseStaticArray) = IndexLinear()
    @inline Base.stride(a::DenseStaticArray, dim::Int) = (dim <= 1) ? 1 : stride(a, dim-1) * size(a, dim-1)
    @inline Base.firstindex(::DenseStaticArray) = 1
    @inline Base.lastindex(a::DenseStaticArray) = length(a)

    # Scalar getindex
    @inline Base.getindex(a::DenseStaticArray{T,0}) where {T} = unsafe_load(pointer(a))
    @inline Base.getindex(a::DenseStaticArray{T}, i::Int) where T = unsafe_load(pointer(a)+(i-1)*sizeof(T))

    # Getindex methods returning views
    @inline Base.getindex(a::DenseStaticArray, ::Colon) = a
    @inline Base.getindex(a::DenseStaticArray{T}, r::UnitRange{<:Integer}) where T = ArrayView(pointer(a)+(first(r)-1)*sizeof(T), length(r), (length(r),))
    @inline Base.getindex(a::DenseStaticArray, r::UnitRange{<:Integer}, inds::Vararg{Int}) = getindex(a, r, inds)
    @inline function Base.getindex(a::DenseStaticArray{T}, r::UnitRange{<:Integer}, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+1)
        end
        return ArrayView{T,1}(pointer(a)+i0*sizeof(T), length(r), (length(r),))
    end
    @inline Base.getindex(a::DenseStaticArray, ::Colon, inds::Vararg{Int}) = getindex(a, :, inds)
    @inline function Base.getindex(a::DenseStaticArray{T}, ::Colon, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+1)
        end
        return ArrayView{T,1}(pointer(a)+i0*sizeof(T), size(a,1), (size(a,1),))
    end
    @inline Base.getindex(a::DenseStaticArray, ::Colon, ::Colon, inds::Vararg{Int}) = getindex(a, :, :, inds)
    @inline function Base.getindex(a::DenseStaticArray{T}, ::Colon, ::Colon, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+2)
        end
        return ArrayView{T,2}(pointer(a)+i0*sizeof(T), size(a,1)*size(a,2), (size(a,1), size(a,2)))
    end
    @inline Base.getindex(a::DenseStaticArray, ::Colon, ::Colon, ::Colon, inds::Vararg{Int}) = getindex(a, :, :, :, inds)
    @inline function Base.getindex(a::DenseStaticArray{T}, ::Colon, ::Colon, ::Colon, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+3)
        end
        return ArrayView{T,3}(pointer(a)+i0*sizeof(T), size(a,1)*size(a,2)*size(a,3), (size(a,1), size(a,2), size(a,3)))
    end

    # Setindex methods
    @inline Base.setindex!(a::DenseStaticArray{T,0}, x::T) where {T} = unsafe_store!(pointer(a), x)
    @inline Base.setindex!(a::DenseStaticArray{T,0}, x) where {T} = unsafe_store!(pointer(a), convert(T,x))
    @inline Base.setindex!(a::DenseStaticArray{T}, x::T, i::Int) where {T} = unsafe_store!(pointer(a)+(i-1)*sizeof(T), x)
    @inline Base.setindex!(a::DenseStaticArray{T}, x, i::Int) where {T} = unsafe_store!(pointer(a)+(i-1)*sizeof(T), convert(T,x))
    @inline function Base.setindex!(a::DenseStaticArray{T}, x::Union{AbstractArray{T},NTuple{T}}, r::UnitRange{Int}) where T
        ix₀ = firstindex(x)-first(r)
        for i ∈ r
            setindex!(a, x[i+ix₀], i)
        end
    end
    @inline function Base.setindex!(a::DenseStaticArray{T}, x::T, r::UnitRange{Int}) where T
        for i ∈ r
            setindex!(a, x, i)
        end
    end
    @inline function Base.setindex!(a::DenseStaticArray{T}, x::Union{AbstractArray{T},NTuple{T}}, ::Colon) where T
        ix₀ = firstindex(x)-1
        for i ∈ eachindex(a)
            setindex!(a, x[i+ix₀], i)
        end
    end
    @inline function Base.setindex!(a::DenseStaticArray{T}, x::T, ::Colon) where T
        for i ∈ eachindex(a)
            setindex!(a, x, i)
        end
    end

    # Other nice functions
    @inline Base.fill!(A::DenseStaticArray{T}, x) where {T} = fill!(A, convert(T,x))
    @inline function Base.fill!(A::DenseStaticArray{T}, x::T) where {T}
        setindex!(A, x, :)
        return A
    end

    @inline function Base.:(==)(a::DenseStaticArray{A}, b::DenseStaticArray{B}) where {A,B}
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n*sizeof(A)) == unsafe_load(pb + n*sizeof(B)) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::DenseStaticArray, b::NTuple{N, <:Number}) where N
        N == length(a) || return false
        for n in 1:N
            a[n] == b[n] || return false
        end
        return true
    end
    @inline function Base.:(==)(a::NTuple{N, <:Number}, b::DenseStaticArray) where N
        N == length(b) || return false
        for n in 1:N
            a[n] == b[n] || return false
        end
        return true
    end

    # Custom printing
    @inline Base.print(a::DenseStaticArray) = printf(a)
    @inline Base.println(a::DenseStaticArray) = (printf(a); newline())
    @inline Base.print(fp::Ptr{FILE}, a::DenseStaticArray) = printf(fp, a)
    @inline Base.println(fp::Ptr{FILE}, a::DenseStaticArray) = (printf(fp, a); newline(fp))
