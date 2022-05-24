
    const MaybePointer = Union{Ptr, UndefInitializer}

    # Definition and constructors:
    """
    ```julia
    MallocArray{T,N} <: AbstractArray{T,N}
    ```
    `N`-dimensional dense heap-allocated array with elements of type `T`.

    Much like `Base.Array`, except (1) backed by memory that is not tracked by
    the Julia garbage collector (is directly allocated with `malloc`) so is
    StaticCompiler-safe, (2) should be `free`d when no longer in use, and
    (3) indexing returns views rather than copies.
    """
    struct MallocArray{T,N} <: DenseArray{T,N}
        pointer::Ptr{T}
        length::Int
        size::NTuple{N, Int}
    end
    """
    ```julia
    MallocMatrix{T} <: AbstractMatrix{T}
    ```
    Two-dimensional dense heap-allocated array with elements of type `T`.
    As `Base.Matrix` is to `Base.Array`, but with `MallocArray`.
    """
    const MallocMatrix{T} = MallocArray{T,2}
    """
    ```julia
    MallocVector{T} <: AbstractVector{T}
    ```
    Two-dimensional dense heap-allocated array with elements of type `T`.
    As `Base.Vector` is to `Base.Array`, but with `MallocArray`.
    """
    const MallocVector{T} = MallocArray{T,1}


    """
    ```julia
    MallocArray{T}(undef, dims)
    MallocArray{T,N}(undef, dims)
    ```
    Construct an uninitialized `N`-dimensional `MallocArray` containing elements
    of type `T`. `N` can either be supplied explicitly, as in `Array{T,N}(undef, dims)`,
    or be determined by the length or number of `dims`. `dims` may be a tuple or
    a series of integer arguments corresponding to the lengths in each dimension.
    If the rank `N` is supplied explicitly, then it must match the length or
    number of `dims`. Here `undef` is the `UndefInitializer`.

    ## Examples
    ```julia
    julia> A = MallocArray{Float64}(undef, 3,3) # implicit N
    3×3 MallocMatrix{Float64}:
     3.10504e231   6.95015e-310   2.12358e-314
     1.73061e-77   6.95015e-310   5.56271e-309
     6.95015e-310  0.0           -1.29074e-231

    julia> free(A)
    0

    julia> A = MallocArray{Float64, 3}(undef, 2,2,2) # explicit N
    2×2×2 MallocArray{Float64, 3}:
    [:, :, 1] =
     3.10504e231  2.0e-323
     2.32036e77   6.94996e-310

    [:, :, 2] =
     6.95322e-310  5.0e-324
     6.95322e-310  5.56271e-309

    julia> free(A)
    0
    ```
    """
    @inline function MallocArray{T,N}(::UndefInitializer, length::Int, dims::Dims{N}) where {T,N}
        @assert Base.allocatedinline(T)
        @assert length == prod(dims)
        p = Ptr{T}(malloc(length*sizeof(T)))
        MallocArray{T,N}(p, length, dims)
    end
    @inline MallocArray{T,N}(x::MaybePointer, dims::Dims{N}) where {T,N} = MallocArray{T,N}(x, prod(dims), dims)
    @inline MallocArray{T}(x::MaybePointer, dims::Dims{N}) where {T,N} = MallocArray{T,N}(x, prod(dims), dims)
    @inline MallocArray{T,N}(x::MaybePointer, dims::Vararg{Int}) where {T,N} = MallocArray{T,N}(x, prod(dims), dims)
    @inline MallocArray{T}(x::MaybePointer, dims::Vararg{Int}) where {T} = MallocArray{T}(x, dims)

    # Indirect constructors
    @inline Base.similar(a::MallocArray{T,N}) where {T,N} = MallocArray{T,N}(undef, size(a))
    @inline Base.similar(a::MallocArray{T}, dims::Dims{N}) where {T,N} = MallocArray{T,N}(undef, dims)
    @inline Base.similar(a::MallocArray{T}, dims::Vararg{Int}) where {T} = MallocArray{T}(undef, dims)
    @inline Base.similar(a::MallocArray, ::Type{T}, dims::Dims{N}) where {T,N} = MallocArray{T,N}(undef, dims)
    @inline Base.similar(a::MallocArray, ::Type{T}, dims::Vararg{Int}) where {T} = MallocArray{T}(undef, dims)
    @inline function Base.copy(a::MallocArray{T,N}) where {T,N}
        new_a = MallocArray{T,N}(undef, size(a))
        copyto!(new_a, a)
        return new_a
    end

    # Destructor:
    @inline free(a::MallocArray) = free(a.pointer)

    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, a::MallocArray) where {T} = Ptr{T}(a.pointer)
    @inline Base.pointer(a::MallocArray) = a.pointer
    @inline Base.length(a::MallocArray) = a.length
    @inline Base.sizeof(a::MallocArray{T}) where {T} = a.length * sizeof(T)
    @inline Base.size(a::MallocArray) = a.size

    # Some of the AbstractArray interface:
    @inline Base.IndexStyle(::MallocArray) = IndexLinear()
    @inline Base.stride(a::MallocArray, dim::Int) = (dim <= 1) ? 1 : stride(a, dim-1) * size(a, dim-1)
    @inline Base.firstindex(::MallocArray) = 1
    @inline Base.lastindex(a::MallocArray) = a.length
    @inline Base.getindex(a::MallocArray{T}, i::Int) where T = unsafe_load(pointer(a)+(i-1)*sizeof(T))
    @inline Base.getindex(a::MallocArray, ::Colon) = a
    @inline Base.getindex(a::MallocArray{T}, r::UnitRange{<:Integer}) where T = MallocArray(pointer(a)+(first(r)-1)*sizeof(T), length(r), (length(r),))

    @inline Base.getindex(a::MallocArray, r::UnitRange{<:Integer}, inds::Vararg{Int}) = getindex(a, r, inds)
    @inline function Base.getindex(a::MallocArray{T}, r::UnitRange{<:Integer}, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+1)
        end
        return MallocArray{T,1}(pointer(a)+i0*sizeof(T), length(r), (length(r),))
    end

    @inline Base.getindex(a::MallocArray, ::Colon, inds::Vararg{Int}) = getindex(a, :, inds)
    @inline function Base.getindex(a::MallocArray{T}, ::Colon, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+1)
        end
        return MallocArray{T,1}(pointer(a)+i0*sizeof(T), size(a,1), (size(a,1),))
    end
    @inline Base.getindex(a::MallocArray, ::Colon, ::Colon, inds::Vararg{Int}) = getindex(a, :, :, inds)
    @inline function Base.getindex(a::MallocArray{T}, ::Colon, ::Colon, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+2)
        end
        return MallocArray{T,2}(pointer(a)+i0*sizeof(T), size(a,1)*size(a,2), (size(a,1), size(a,2)))
    end
    @inline Base.getindex(a::MallocArray, ::Colon, ::Colon, ::Colon, inds::Vararg{Int}) = getindex(a, :, :, :, inds)
    @inline function Base.getindex(a::MallocArray{T}, ::Colon, ::Colon, ::Colon, inds::Dims{N}) where {T,N}
        i0 = 0
        for i=1:N
            i0 += (inds[i]-1) * stride(a, i+3)
        end
        return MallocArray{T,3}(pointer(a)+i0*sizeof(T), size(a,1)*size(a,2)*size(a,3), (size(a,1), size(a,2), size(a,3)))
    end

    @inline Base.setindex!(a::MallocArray{T}, x::T, i::Int) where T = unsafe_store!(pointer(a)+(i-1)*sizeof(T), x)
    @inline Base.setindex!(a::MallocArray{T}, x, i::Int) where T = unsafe_store!(pointer(a)+(i-1)*sizeof(T), convert(T,x))
    @inline function Base.setindex!(a::MallocArray, x, r::UnitRange{Int})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(r)
            setindex!(a, x[i+ix₀], i+is₀)
        end
    end
    @inline function Base.setindex!(a::MallocArray{T}, x::Union{T,<:Number}, r::UnitRange{Int}) where T
        xₜ = convert(T,x)
        is₀ = first(r)-1
        @inbounds for i = 1:length(r)
            setindex!(a, xₜ, i+is₀)
        end
    end
    @inline function Base.setindex!(a::MallocArray, x, ::Colon)
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(a)
            setindex!(a, x[i+ix₀], i)
        end
    end
    @inline function Base.setindex!(a::MallocArray{T}, x::Union{T,<:Number}, ::Colon) where T
        xₜ = convert(T,x)
        @inbounds for i = 1:length(a)
            setindex!(a, xₜ, i)
        end
    end

    # Other nice functions
    @inline function Base.:(==)(a::MallocArray{A}, b::MallocArray{B}) where {A,B}
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n*sizeof(A)) == unsafe_load(pb + n*sizeof(B)) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::MallocArray, b::NTuple{N, <:Number}) where N
        N == length(a) || return false
        for n in 1:N
            a[n] == b[n] || return false
        end
        return true
    end
    @inline function Base.:(==)(a::NTuple{N, <:Number}, b::MallocArray) where N
        N == length(b) || return false
        for n in 1:N
            a[n] == b[n] || return false
        end
        return true
    end

    # Reshaping and Reinterpreting
    @inline function Base.reshape(a::MallocArray{T}, dims::Dims{N})  where {T,N}
        @assert prod(dims) == length(a)
        MallocArray{T,N}(pointer(a), dims)
    end
    @inline Base.reshape(a::MallocArray, dims::Vararg{Int}) = reshape(a, dims)

    @inline function Base.reinterpret(::Type{Tᵣ}, a::MallocArray{Tᵢ,N}) where {N,Tᵣ,Tᵢ}
        @assert Base.allocatedinline(Tᵣ)
        @assert length(a)*sizeof(Tᵢ) % sizeof(Tᵣ) == 0
        @assert size(a,1)*sizeof(Tᵢ) % sizeof(Tᵣ) == 0
        lengthᵣ = length(a)*sizeof(Tᵢ)÷sizeof(Tᵣ)
        sizeᵣ = ntuple(i -> i==1 ? size(a,i)*sizeof(Tᵢ)÷sizeof(Tᵣ) : size(a,i), Val(N))
        pointerᵣ = Ptr{Tᵣ}(pointer(a))
        MallocArray{Tᵣ,N}(pointerᵣ, lengthᵣ, sizeᵣ)
    end

    # Custom printing
    @inline Base.print(a::MallocArray) = printf(a)
    @inline Base.println(a::MallocArray) = (printf(a); newline())
    @inline Base.print(fp::Ptr{FILE}, a::MallocArray) = printf(fp, a)
    @inline Base.println(fp::Ptr{FILE}, a::MallocArray) = (printf(fp, a); newline(fp))
