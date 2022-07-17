
    # General array interface

    # Supertype for all arrays in this package
    abstract type DenseStaticArray{T,N} <: DenseArray{T,N} end

    # A subtype for arrays that are backed by a pointer, length, and size alone
    abstract type DensePointerArray{T,N} <: DenseStaticArray{T,N} end
    # A subtype for arrays that are backed by an NTuple
    abstract type DenseTupleArray{T,N,L,D} <: DenseStaticArray{T,N} end


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

    # Getindex methods returning tuples
    @inline Base.getindex(a::DenseStaticArray, t::NTuple{N,Int}) where N = ntuple(i->a[t[i]], Val(N))

    # Getindex methods returning views
    @inline Base.getindex(a::DenseStaticArray, ::Colon) = a
    @inline Base.getindex(a::DenseStaticArray{T}, r::AbstractUnitRange{<:Integer}) where T = ArrayView(pointer(a)+(first(r)-1)*sizeof(T), length(r), (length(r),))
    @inline Base.getindex(a::DenseStaticArray, r::AbstractUnitRange{<:Integer}, inds::Vararg{Int}) = getindex(a, r, inds)
    @inline function Base.getindex(a::DenseStaticArray{T}, r::AbstractUnitRange{<:Integer}, inds::Dims{N}) where {T,N}
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
    @inline function Base.setindex!(a::DenseStaticArray, x::Union{AbstractArray,NTuple{L}}, r::Union{AbstractUnitRange{Int}, NTuple{L,Int}}) where {L}
        length(x) == length(r) || error(c"DimensionMismatch: indices and values not of matching length")
        for (i,xᵢ) ∈ zip(r,x)
            setindex!(a, xᵢ, i)
        end
    end
    @inline function Base.setindex!(a::DenseStaticArray{T}, x::T, r::Union{AbstractUnitRange{<:Integer}, NTuple{L,<:Integer}}) where {L,T}
        for i ∈ r
            setindex!(a, x, i)
        end
    end
    @inline Base.setindex!(a::DenseStaticArray, x, ::Colon) = setindex!(a, x, eachindex(a))
    @inline Base.setindex!(a::DenseStaticArray{T}, x::T, ::Colon) where {T} = fill!(a, x)

    # Other nice functions
    @inline Base.fill!(a::DenseStaticArray{T}, x) where {T} = fill!(a, convert(T,x))
    @inline function Base.fill!(a::DenseStaticArray{T}, x::T) where {T}
        for i ∈ eachindex(a)
            setindex!(a, x, i)
        end
        return a
    end

    @inline function Base.:(==)(a::DenseStaticArray{Ta}, b::DenseStaticArray{Tb}) where {Ta,Tb}
        axes(a) == axes(b) || return false
        pa, pb = pointer(a), pointer(b)
        sa, sb = sizeof(Ta), sizeof(Tb)
        for n in 0:length(a)-1
            unsafe_load(pa + n*sa) == unsafe_load(pb + n*sb) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::DenseStaticArray, b::Union{DenseArray,NTuple})
        axes(a) == axes(b) || return false
        @inbounds for n in eachindex(a)
            a[n] == b[n] || return false
        end
        return true
    end
    @inline function Base.:(==)(a::Union{DenseArray,NTuple}, b::DenseStaticArray)
        axes(a) == axes(b) || return false
        @inbounds for n in eachindex(b)
            a[n] == b[n] || return false
        end
        return true
    end


    # Reshaping and Reinterpreting
    @inline function Base.reshape(a::DenseStaticArray{T}, dims::Dims{N})  where {T,N}
        @assert prod(dims) == length(a)
        ArrayView{T,N}(pointer(a), length(a), dims)
    end
    @inline Base.reshape(a::DenseStaticArray, dims::Vararg{Int}) = reshape(a, dims)

    @inline function Base.reinterpret(::Type{Tᵣ}, a::DenseStaticArray{Tᵢ,N}) where {N,Tᵣ,Tᵢ}
        @assert Base.allocatedinline(Tᵣ)
        @assert length(a)*sizeof(Tᵢ) % sizeof(Tᵣ) == 0
        @assert size(a,1)*sizeof(Tᵢ) % sizeof(Tᵣ) == 0
        lengthᵣ = length(a)*sizeof(Tᵢ)÷sizeof(Tᵣ)
        sizeᵣ = ntuple(i -> i==1 ? size(a,i)*sizeof(Tᵢ)÷sizeof(Tᵣ) : size(a,i), Val(N))
        pointerᵣ = Ptr{Tᵣ}(pointer(a))
        ArrayView{Tᵣ,N}(pointerᵣ, lengthᵣ, sizeᵣ)
    end

    # Custom printing
    @inline Base.print(a::DenseStaticArray) = printf(a)
    @inline Base.println(a::DenseStaticArray) = (printf(a); newline())
    @inline Base.print(fp::Ptr{FILE}, a::DenseStaticArray) = printf(fp, a)
    @inline Base.println(fp::Ptr{FILE}, a::DenseStaticArray) = (printf(fp, a); newline(fp))
