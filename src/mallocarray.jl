
    # Definition and constructors:
    struct MallocArray{T,N} <: DenseArray{T,N}
        pointer::Ptr{T}
        length::Int
        size::NTuple{N, Int}
    end
    @inline function MallocArray{T,N}(p::Ptr, size::NTuple{N, Int}) where {N,T}
        @assert Base.allocatedinline(T)
        MallocArray{T,N}(Ptr{T}(p), prod(size), size)
    end
    @inline function MallocArray{T,N}(::UndefInitializer, size::NTuple{N, Int}) where {N,T}
        @assert Base.allocatedinline(T)
        len = prod(size)
        MallocArray{T,N}(Ptr{T}(Libc.malloc(len*sizeof(T))), len, size)
    end
    @inline MallocArray{T}(x::Union{Ptr, UndefInitializer}, size::NTuple{N, Int}) where {N,T} = MallocArray{T,N}(x, size)
    @inline MallocArray{T}(x::Union{Ptr, UndefInitializer}, length::Int) where {T} = MallocArray{T,1}(x, (length,))
    @inline MallocArray{T}(x::Union{Ptr, UndefInitializer}, size...) where {T} = MallocArray{T}(x, size)

    # Destructor:
    @inline free(a::MallocArray) = Libc.free(a.pointer)

    # Fundamentals
    Base.unsafe_convert(::Type{Ptr{T}}, m::MallocArray) where {T} = Ptr{T}(a.pointer)
    Base.pointer(a::MallocArray) = a.pointer
    Base.length(a::MallocArray) = a.length
    Base.sizeof(a::MallocArray{T}) where {T} = a.length * sizeof(T)
    Base.size(a::MallocArray) = a.size

    # Some of the AbstractArray interface:
    Base.IndexStyle(::MallocArray) = IndexLinear()
    Base.stride(a::MallocArray, dim::Int) = (dim <= 1) ? 1 : stride(a, dim-1) * size(a, dim-1)
    Base.firstindex(::MallocArray) = 1
    Base.lastindex(a::MallocArray) = a.length
    Base.getindex(a::MallocArray{T}, i::Int) where T = unsafe_load(pointer(a)+(i-1)*sizeof(T))
    Base.getindex(a::MallocArray{T}, r::UnitRange{<:Integer}) where T = MallocArray(pointer(a)+(first(r)-1)*sizeof(T), length(r), (length(r),))
    Base.getindex(a::MallocArray, ::Colon) = a
    Base.setindex!(a::MallocArray{T}, x::T, i::Int) where T = unsafe_store!(pointer(a)+(i-1)*sizeof(T), x)
    Base.setindex!(a::MallocArray{T}, x, i::Int) where T = unsafe_store!(pointer(a)+(i-1)*sizeof(T), convert(T,x))
    # @inline function Base.setindex!(a::MallocArray, x, r::UnitRange{Int})
    #     is₀ = first(r)-1
    #     ix₀ = firstindex(x)-1
    #     @inbounds for i = 1:length(r)
    #         setindex!(a, x[i+ix₀], i+is₀)
    #     end
    # end
    @inline function Base.setindex!(a::MallocArray, x, ::Colon)
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(a)
            setindex!(a, x[i+ix₀], i)
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
    # @inline function Base.:(==)(a::MallocArray, b)
    #     (N = length(a)) == length(b) || return false
    #     for n in 1:N
    #         a[n] == b[n] || return false
    #     end
    #     return true
    # end
    # @inline function Base.:(==)(a, b::MallocArray)
    #     (N = length(a)) == length(b) || return false
    #     for n in 1:N
    #         a[n] == b[n] || return false
    #     end
    #     return true
    # end


    # TODO:
    # Base.copy(a::MallocArray)
