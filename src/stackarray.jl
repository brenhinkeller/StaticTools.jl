
    # Definition and constructors:
    """
    ```julia
    StackArray{T,N} <: AbstractArray{T,N}
    ```
    `N`-dimensional dense stack-allocated array with elements of type `T`.

    Much like `Base.Array`, except (1) backed by memory that is not tracked by
    the Julia garbage collector (is stack allocated by `alloca`), so is
    StaticCompiler-friendly, and (2) indexing returns views rather than copies.
    """
    mutable struct StackArray{T,N,L,D} <: DenseStaticArray{T,N}
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
        @inline function StackArray{T,N}(data::NTuple{L,T₀}, size::Dims{N}) where {T,N,L,T₀}
            @assert Base.allocatedinline(T)
            @assert prod(size)*sizeof(T) == L*sizeof(T₀)
            A = new{T,N,prod(size),size}()
        end
        @inline function StackArray(data::NTuple{L,T}, size::Dims{N}) where {T,N,L}
            @assert Base.allocatedinline(T)
            @assert L == prod(size)
            A = new{T,N,L,size}()
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
    ```
    Construct an uninitialized `N`-dimensional `StackArray` containing elements
    of type `T`. `N` can either be supplied explicitly, as in `Array{T,N}(undef, dims)`,
    or be determined by the length or number of `dims`. `dims` may be a tuple or
    a series of integer arguments corresponding to the lengths in each dimension.
    If the rank `N` is supplied explicitly, then it must match the length or
    number of `dims`.

    ## Examples
    ```julia
    julia> A = StackArray{Float64}(undef, 3,3) # implicit N
    3×3 StackMatrix{Float64}:
     3.10504e231   6.95015e-310   2.12358e-314
     1.73061e-77   6.95015e-310   5.56271e-309
     6.95015e-310  0.0           -1.29074e-231
    ```
    """
    @inline StackArray(x::NTuple, dims::Vararg{Int}) = StackArray(x, dims)
    @inline StackArray{T}(x::Union{UndefInitializer,NTuple}, dims::Vararg{Int}) where {T} = StackArray{T}(x, dims)
    @inline StackArray{T}(x::Union{UndefInitializer,NTuple}, dims::Dims{N}) where {T,N} = StackArray{T,N}(x, dims)
    @inline StackArray{T,N}(x::Union{UndefInitializer,NTuple}, dims::Vararg{Int}) where {T,N} = StackArray{T,N}(x, dims)


    # Indirect constructors
    @inline Base.similar(a::StackArray{T,N,L,D}) where {T,N,L,D} = StackArray{T,N,L,D}(undef)
    @inline Base.similar(a::StackArray{T}, dims::Dims{N}) where {T,N} = StackArray{T,N}(undef, dims)
    @inline Base.similar(a::StackArray{T}, dims::Vararg{Int}) where {T} = StackArray{T}(undef, dims)
    @inline Base.similar(a::StackArray, ::Type{T}, dims::Dims{N}) where {T,N} = StackArray{T,N}(undef, dims)
    @inline Base.similar(a::StackArray, ::Type{T}, dims::Vararg{Int}) where {T} = StackArray{T}(undef, dims)
    @inline function Base.copy(a::StackArray{T,N,L,D}) where {T,N,L,D}
        c = StackArray{T,N,L,D}(undef)
        copyto!(c, a)
        return c
    end

    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, a::StackArray) where {T} = Ptr{T}(pointer_from_objref(a))
    @inline Base.pointer(a::StackArray{T}) where {T} = Ptr{T}(pointer_from_objref(a))
    @inline Base.length(a::StackArray{T,N,L}) where {T,N,L} = L
    @inline Base.sizeof(a::StackArray{T,N,L}) where {T,N,L} = L * sizeof(T)
    @inline Base.size(a::StackArray{T,N,L,D}) where {T,N,L,D} = D


    @inline function Base.:(==)(a::StackArray{A}, b::StackArray{B}) where {A,B}
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n*sizeof(A)) == unsafe_load(pb + n*sizeof(B)) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::StackArray, b::NTuple{N, <:Number}) where N
        N == length(a) || return false
        for n in 1:N
            a[n] == b[n] || return false
        end
        return true
    end
    @inline function Base.:(==)(a::NTuple{N, <:Number}, b::StackArray) where N
        N == length(b) || return false
        for n in 1:N
            a[n] == b[n] || return false
        end
        return true
    end

    # # Reshaping and Reinterpreting
    # @inline function Base.reshape(a::StackArray{T}, dims::Dims{N})  where {T,N}
    #     @assert prod(dims) == length(a)
    #     StackArray{T,N}(pointer(a), dims)
    # end
    # @inline Base.reshape(a::StackArray, dims::Vararg{Int}) = reshape(a, dims)
    #
    # @inline function Base.reinterpret(::Type{Tᵣ}, a::StackArray{Tᵢ,N}) where {N,Tᵣ,Tᵢ}
    #     @assert Base.allocatedinline(Tᵣ)
    #     @assert length(a)*sizeof(Tᵢ) % sizeof(Tᵣ) == 0
    #     @assert size(a,1)*sizeof(Tᵢ) % sizeof(Tᵣ) == 0
    #     lengthᵣ = length(a)*sizeof(Tᵢ)÷sizeof(Tᵣ)
    #     sizeᵣ = ntuple(i -> i==1 ? size(a,i)*sizeof(Tᵢ)÷sizeof(Tᵣ) : size(a,i), Val(N))
    #     pointerᵣ = Ptr{Tᵣ}(pointer(a))
    #     StackArray{Tᵣ,N}(pointerᵣ, lengthᵣ, sizeᵣ)
    # end


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
    2×2 StackMatrix{Int32}:
     0  0
     0  0
    ```
    """
    @inline szeros(dims::Vararg{Int}) = szeros(dims)
    @inline szeros(dims::Dims{N}) where {N} = fill!(StackArray{Float64,N}(undef, dims), 0.0)
    @inline szeros(T::Type, dims::Vararg{Int}) = szeros(T, dims)
    @inline szeros(::Type{T}, dims::Dims{N}) where {T,N} = fill!(StackArray{T,N}(undef, dims), zero(T))

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
    2×2 StackMatrix{Int32}:
     1  1
     1  1
    ```
    """
    @inline sones(dims::Vararg{Int}) = sones(Float64, dims)
    @inline sones(dims::Dims) = sones(Float64, dims)
    @inline sones(T::Type, dims::Vararg{Int}) = sones(T, dims)
    @inline function sones(::Type{T}, dims::Dims{N}) where {T,N}
        A = StackArray{T,N}(undef, dims)
        fill!(A, one(T))
    end

    """
    ```julia
    seye([T=Float64,] dim::Int)
    ```
    Create a `StackArray{T}` containing an identity matrix of type `T`,
    of size `dim` x `dim`.

    ## Examples
    ```julia
    julia> seye(Int32, 2,2)
    2×2 StackMatrix{Int32}:
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
    2×2 StackMatrix{Int64}:
     3  3
     3  3
    ```
    """
    @inline sfill(x, dims::Vararg{Int}) = sfill(x, dims)
    @inline function sfill(x::T, dims::Dims{N}) where {T,N}
        A = StackArray{T,N,prod(dims),dims}(undef)
        fill!(A, x)
    end
