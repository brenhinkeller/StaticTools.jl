
    const PointerOrInitializer = Union{Ptr, UndefInitializer, typeof(Base.zeros)}

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
    ```julia
    MallocArray{T}(zeros, dims)
    MallocArray{T,N}(zeros, dims)
    ```
    Construct an uninitialized (`undef`) or zero-initialized (`zeros`)
    `N`-dimensional `MallocArray` containing elements of type `T`.
    `N` can either be supplied explicitly, as in `Array{T,N}(undef, dims)`,
    or be determined by the length or number of `dims`. `dims` may be a tuple or
    a series of integer arguments corresponding to the lengths in each dimension.
    If the rank `N` is supplied explicitly, then it must match the length or
    number of `dims`.

    Here `undef` is the `UndefInitializer` and signals that `malloc` should be
    used to obtain the underlying memory, while `zeros` is the `Base` function
    `zeros` and flags that `calloc` should be used to obtain and zero-initialize
    the underlying memory

    ## Examples
    ```julia
    julia> A = MallocArray{Float64}(undef, 3,3) # implicit N
    3×3 MallocMatrix{Float64}:
     3.10504e231   6.95015e-310   2.12358e-314
     1.73061e-77   6.95015e-310   5.56271e-309
     6.95015e-310  0.0           -1.29074e-231

    julia> free(A)
    0

    julia> A = MallocArray{Float64, 3}(zeros, 2,2,2) # explicit N, zero initialize
    2×2×2 MallocArray{Float64, 3}:
    [:, :, 1] =
     0.0  0.0
     0.0  0.0

    [:, :, 2] =
     0.0  0.0
     0.0  0.0

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
    @inline function MallocArray{T,N}(::typeof(Base.zeros), length::Int, dims::Dims{N}) where {T,N}
        @assert Base.allocatedinline(T)
        @assert length == prod(dims)
        p = Ptr{T}(calloc(length*sizeof(T)))
        MallocArray{T,N}(p, length, dims)
    end
    @inline MallocArray{T,N}(x::PointerOrInitializer, dims::Dims{N}) where {T,N} = MallocArray{T,N}(x, prod(dims), dims)
    @inline MallocArray{T}(x::PointerOrInitializer, dims::Dims{N}) where {T,N} = MallocArray{T,N}(x, prod(dims), dims)
    @inline MallocArray{T,N}(x::PointerOrInitializer, dims::Vararg{Int}) where {T,N} = MallocArray{T,N}(x, prod(dims), dims)
    @inline MallocArray{T}(x::PointerOrInitializer, dims::Vararg{Int}) where {T} = MallocArray{T}(x, dims)

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
    @inline function Base.setindex!(a::MallocArray{T}, x::Union{AbstractArray{T},NTuple{T}}, r::UnitRange{Int}) where T
        ix₀ = firstindex(x)-first(r)
        @inbounds for i ∈ r
            setindex!(a, x[i+ix₀], i)
        end
    end
    @inline function Base.setindex!(a::MallocArray{T}, x::T, r::UnitRange{Int}) where T
        @inbounds for i ∈ r
            setindex!(a, x, i)
        end
    end
    @inline function Base.setindex!(a::MallocArray{T}, x::Union{AbstractArray{T},NTuple{T}}, ::Colon) where T
        ix₀ = firstindex(x)-1
        @inbounds for i ∈ eachindex(a)
            setindex!(a, x[i+ix₀], i)
        end
    end
    @inline function Base.setindex!(a::MallocArray{T}, x::T, ::Colon) where T
        @inbounds for i ∈ eachindex(a)
            setindex!(a, x, i)
        end
        return a
    end

    # Other nice functions
    @inline Base.fill!(A::MallocArray{T}, x::T) where {T} = setindex!(A, x, :)
    @inline Base.fill!(A::MallocArray{T}, x) where {T} = setindex!(A, convert(T,x), :)
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


    # Other custom constructors
    """
    ```julia
    mzeros([T=Float64,] dims::Tuple)
    mzeros([T=Float64,] dims...)
    ```
    Create a `MallocArray{T}` containing all zeros of type `T`, of size `dims`.
    As `Base.zeros`, but returning a `MallocArray` instead of an `Array`.

    See also `mones`, `mfill`.

    ## Examples
    ```julia
    julia> mzeros(Int32, 2,2)
    2×2 MallocMatrix{Int32}:
     0  0
     0  0
    ```
    """
    @inline mzeros(dims::Vararg{Int}) = mzeros(dims)
    @inline mzeros(dims::Dims{N}) where {N} = MallocArray{Float64,N}(zeros, dims)
    @inline mzeros(T::Type, dims::Vararg{Int}) = mzeros(T, dims)
    @inline mzeros(::Type{T}, dims::Dims{N}) where {T,N} = MallocArray{T,N}(zeros, dims)


    """
    ```julia
    mones([T=Float64,] dims::Tuple)
    mones([T=Float64,] dims...)
    ```
    Create a `MallocArray{T}` containing all zeros of type `T`, of size `dims`.
    As `Base.zeros`, but returning a `MallocArray` instead of an `Array`.

    See also `mzeros`, `mfill`.

    ## Examples
    ```julia
    julia> mones(Int32, 2,2)
    2×2 MallocMatrix{Int32}:
     1  1
     1  1
    ```
    """
    @inline mones(dims::Vararg{Int}) = mones(Float64, dims)
    @inline mones(dims::Dims) = mones(Float64, dims)
    @inline mones(T::Type, dims::Vararg{Int}) = mones(T, dims)
    @inline function mones(::Type{T}, dims::Dims{N}) where {T,N}
        A = MallocArray{T,N}(undef, prod(dims), dims)
        fill!(A, one(T))
    end

    """
    ```julia
    mfill(x::T, dims::Tuple)
    mfill(x::T, dims...)
    ```
    Create a `MallocArray{T}` of size `dims`, filled with the value `x`, where `x` is of type `T`.
    As `Base.fill`, but returning a `MallocArray` instead of an `Array`.

    See also `mzeros`, `mones`.

    ## Examples
    ```julia
    julia> mfill(3, 2, 2)
    2×2 MallocMatrix{Int64}:
     3  3
     3  3
    ```
    """
    @inline mfill(x, dims::Vararg{Int}) = mfill(x, dims)
    @inline function mfill(x::T, dims::Dims{N}) where {T,N}
        A = MallocArray{T,N}(undef, prod(dims), dims)
        fill!(A, x)
    end
