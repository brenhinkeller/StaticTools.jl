
    # Definition and constructors:
    struct MallocBuffer{T}
        pointer::Ptr{T}
        length::Int
    end
    @inline function MallocBuffer{T}(::UndefInitializer, N::Int) where {T}
        @assert Base.allocatedinline(T)
        MallocBuffer{T}(Ptr{T}(Libc.malloc(len*sizeof(T))), N)
    end

    # Destructor:
    @inline free(a::MallocBuffer) = Libc.free(a.pointer)

    # Fundamentals
    Base.unsafe_convert(::Type{Ptr{T}}, m::MallocBuffer) where {T} = Ptr{T}(a.pointer)
    Base.pointer(a::MallocBuffer) = a.pointer
    Base.length(a::MallocBuffer) = a.length
    Base.sizeof(a::MallocBuffer{T}) where {T} = a.length * sizeof(T)
    @inline Base.:(==)(::MallocBuffer, ::MallocBuffer) = false
    @inline function Base.:(==)(a::MallocBuffer{A}, b::MallocBuffer{N,B}) where {A,B}
        length(a) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n*sizeof(A)) == unsafe_load(pb + n*sizeof(B)) || return false
        end
        return true
    end

    # Some of the AbstractArray interface:
    Base.firstindex(a::MallocBuffer) = 1
    Base.lastindex(a::MallocBuffer) = a.length
    Base.getindex(a::MallocBuffer{T}, i::Int) where T = unsafe_load(pointer(a)+(i-1)*sizeof(T))
    Base.setindex!(a::MallocBuffer{T}, x::T, i::Int) where T = unsafe_store!(pointer(a)+(i-1)*sizeof(T), x)
    Base.setindex!(a::MallocBuffer{T}, x, i::Int) where T = unsafe_store!(pointer(a)+(i-1)*sizeof(T), convert(T,x))
    @inline function Base.setindex!(a::MallocBuffer, x, r::UnitRange{Int})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(r)
            setindex!(a, x[i+ix₀], i+is₀)
        end
    end
    @inline function Base.setindex!(a::MallocBuffer, x, ::Colon)
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(a)
            setindex!(a, x[i+ix₀], i)
        end
    end

    # TODO:
    # Base.copy(a::MallocBuffer)
    # Base.getindex(a::MallocBuffer, r::AbstractArray{Int})
    # Base.getindex(a::MallocBuffer, ::Colon) = copy(s)
