
    # Definition and constructors:
    """
    ```julia
    StackArray{T,N,L,D} <: DenseTupleArray{T,N,L,D} <: DenseArray{T,N} <: AbstractArray{T,N}
    ```
    `N`-dimensional dense stack-allocated array with elements of type `T`.

    Much like `Base.Array`, except (1) backed by memory that is not tracked by
    the Julia garbage collector (is stack allocated by `alloca`), so is
    StaticCompiler-friendly, and (2) contiguous slice indexing returns
    `ArrayView`s rather than copies.
    """
    mutable struct StackArray{T,N,L,D} <: DenseTupleArray{T,N,L,D}
        data::NTuple{L,T}
        @inline function StackArray{T,N,L,D}(::UndefInitializer) where {T,N,L,D}
            @assert Base.allocatedinline(T)
            @assert N == length(D)
            @assert L == prod(D)
            A = new{T,N,L,D}()
        end
        @inline function StackArray{T,N}(::UndefInitializer, size::Dims{N}) where {T,N}
            @assert Base.allocatedinline(T)
            L = prod(size)
            A = new{T,N,L,size}()
        end
        @inline function StackArray{T,N,L,D}(data::NTuple{L,T}) where {T,N,L,D}
            @assert Base.allocatedinline(T)
            @assert N == length(D)
            @assert L == prod(D)
            A = new{T,N,L,D}(data)
        end
        @inline function StackArray(data::NTuple{L,T}, size::Dims{N}) where {T,N,L}
            @assert Base.allocatedinline(T)
            @assert L == prod(size)
            A = new{T,N,L,size}(data)
        end
        @inline function StackArray(data::NTuple{L,T}) where {T,L}
            @assert Base.allocatedinline(T)
            A = new{T,1,L,(L,)}(data)
        end
    end

    """
    ```julia
    StackMatrix{T} <: AbstractMatrix{T}
    ```
    Two-dimensional dense stack-allocated array with elements of type `T`.
    As `Base.Matrix` is to `Base.Array`, but with `StackArray`.
    """
    const StackMatrix{T,L,D} = StackArray{T,2,L,D}
    """
    ```julia
    StackVector{T} <: AbstractVector{T}
    ```
    Two-dimensional dense stack-allocated array with elements of type `T`.
    As `Base.Vector` is to `Base.Array`, but with `StackArray`.
    """
    const StackVector{T,L,D} = StackArray{T,1,L,D}


    """
    ```julia
    StackArray{T}(undef, dims)
    StackArray{T,N}(undef, dims)
    StackArray{T,N,L,D}(undef)
    StackArray(data::NTuple{N,T})
    StackArray(data::NTuple{N,T}, dims)
    ```
    Construct an uninitialized `N`-dimensional `StackArray` containing elements
    of type `T` with `N` dimensions, length `L` and dimensions `D`. Dimensionality
    `N` can either be supplied explicitly, as in `Array{T,N}(undef, dims)`,
    or be determined by the length or number of `dims`. `dims` may be a tuple or
    a series of integer arguments corresponding to the lengths in each dimension.
    If the rank `N` is supplied explicitly, then it must match the length or
    number of `dims`.

    ## Examples
    ```julia
    julia> StackArray{Float64}(undef, 3,3)
    3×3 StackMatrix{Float64, 9, (3, 3)}:
     0.0  0.0  0.0
     0.0  0.0  0.0
     0.0  0.0  0.0
    ```
    """
    @inline StackArray(x::AbstractArray{T,N}) where {T,N} = copyto!(StackArray{T,N,length(x),size(x)}(undef), x)
    @inline StackArray(x::NTuple, dims::Vararg{Int}) = StackArray(x, dims)
    @inline StackArray{T}(x::UndefInitializer, dims::Vararg{Int}) where {T} = StackArray{T}(x, dims)
    @inline StackArray{T}(x::UndefInitializer, dims::Dims{N}) where {T,N} = StackArray{T,N}(x, dims)
    @inline StackArray{T,N}(x::UndefInitializer, dims::Vararg{Int}) where {T,N} = StackArray{T,N}(x, dims)

    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, a::StackArray) where {T} = Ptr{T}(pointer_from_objref(a))
    @inline Base.pointer(a::StackArray{T}) where {T} = Ptr{T}(pointer_from_objref(a))
    @inline Base.length(a::DenseTupleArray{T,N,L}) where {T,N,L} = L
    @inline Base.sizeof(a::DenseTupleArray{T,N,L}) where {T,N,L} = L * sizeof(T)
    @inline Base.size(a::DenseTupleArray{T,N,L,D}) where {T,N,L,D} = D
    @inline Base.Tuple(a::DenseTupleArray) = a.data

    # Other nice functions
    @inline Base.:(==)(::StackArray, ::StackArray) = false
    @inline function Base.:(==)(a::StackArray{Ta,N,L,D}, b::StackArray{Tb,N,L,D}) where {Ta,Tb,N,L,D}
        pa, pb = pointer(a), pointer(b)
        sa, sb = sizeof(Ta), sizeof(Tb)
        for n ∈ 0:L-1
            unsafe_load(pa + n*sa) == unsafe_load(pb + n*sb) || return false
        end
        return true
    end

    # Indirect constructors
    @inline Base.similar(a::StackArray{T,N,L,D}) where {T,N,L,D} = StackArray{T,N,L,D}(undef)
    @inline Base.similar(a::StackArray{T}, dims::Dims{N}) where {T,N} = StackArray{T,N}(undef, dims)
    @inline Base.similar(a::StackArray, dims::Vararg{Int}) = similar(a, dims)
    @inline Base.similar(a::StackArray, ::Type{T}, dims::Dims{N}) where {T,N} = StackArray{T,N}(undef, dims)
    @inline Base.similar(a::StackArray, T::Type, dims::Vararg{Int}) = similar(a, T, dims)
    @inline function Base.copy(a::StackArray{T,N,L,D}) where {T,N,L,D}
        c = StackArray{T,N,L,D}(undef)
        copyto!(c, a)
        return c
    end

    # Other custom constructors
    """
    ```julia
    szeros([T=Float64,] dims::Tuple)
    szeros([T=Float64,] dims...)
    ```
    Create a `StackArray{T}` containing all zeros of type `T`, of size `dims`.
    As `Base.zeros`, but returning a `StackArray` instead of an `Array`.

    See also `sones`, `sfill`.

    ## Examples
    ```julia
    julia> szeros(Int32, 2,2)
    2×2 StackMatrix{Int32, 4, (2, 2)}:
     0  0
     0  0
    ```
    """
    @inline sones(dims...) = sones(Float64, dims...)
    @inline sones(::Type{T}, dims...) where {T} = sfill(one(T), dims...)

    """
    ```julia
    sones([T=Float64,] dims::Tuple)
    sones([T=Float64,] dims...)
    ```
    Create a `StackArray{T}` containing all zeros of type `T`, of size `dims`.
    As `Base.zeros`, but returning a `StackArray` instead of an `Array`.

    See also `szeros`, `sfill`.

    ## Examples
    ```julia
    julia> sones(Int32, 2,2)
    2×2 StackMatrix{Int32, 4, (2, 2)}:
     1  1
     1  1
    ```
    """
    @inline szeros(dims...) = szeros(Float64, dims...)
    @inline szeros(::Type{T}, dims...) where {T} = sfill(zero(T), dims...)

    """
    ```julia
    seye([T=Float64,] dim::Int)
    ```
    Create a `StackArray{T}` containing an identity matrix of type `T`,
    of size `dim` x `dim`.

    ## Examples
    ```julia
    julia> seye(Int32, 2)
    2×2 StackMatrix{Int32, 4, (2, 2)}:
     1  0
     0  1
    ```
    """
    @inline seye(dim::Int) = seye(Float64, dim)
    @inline function seye(::Type{T}, dim::Int) where {T}
        A = StackMatrix{T,dim*dim,(dim,dim)}(undef)
        fill!(A, zero(T))
        𝔦 = one(T)
        @inbounds for i=1:dim
            A[i,i] = 𝔦
        end
        return A
    end

    """
    ```julia
    sfill(x::T, dims::Tuple)
    sfill(x::T, dims...)
    ```
    Create a `StackArray{T}` of size `dims`, filled with the value `x`, where `x` is of type `T`.
    As `Base.fill`, but returning a `StackArray` instead of an `Array`.

    See also `szeros`, `sones`.

    ## Examples
    ```julia
    julia> sfill(3, 2, 2)
    2×2 StackMatrix{Int64, 4, (2, 2)}:
     3  3
     3  3
    ```
    """
    @inline sfill(x, dims::Vararg{Int}) = sfill(x, dims)
    @inline function sfill(x::T, dims::Dims{N}) where {T,N}
        A = StackArray{T,N,prod(dims),dims}(undef)
        fill!(A, x)
    end
