
    struct MallocBuffer{T}
        pointer::Ptr{T}
        length::Int
    end
    @inline function MallocBuffer{T}(::UndefInitializer, N::Int) where {T}
        @assert Base.allocatedinline(T)
        MallocBuffer{T}(Ptr{T}(Libc.malloc(len*sizeof(T))), N)
    end
    @inline free(a::MallocBuffer) = Libc.free(a.pointer)

    @inline Base.unsafe_convert(::Type{Ptr{T}}, m::MallocBuffer) where {T} = Ptr{T}(a.pointer)
    @inline Base.pointer(a::MallocBuffer) = a.pointer
    @inline Base.length(a::MallocBuffer) = a.length
    @inline Base.firstindex(a::MallocBuffer) = 1
    @inline Base.lastindex(a::MallocBuffer) = a.length
    @inline Base.sizeof(a::MallocBuffer{T}) where {T} = a.length * sizeof(T)

    @inline Base.getindex(a::MallocBuffer{T}, i::Int) where T = unsafe_load(a.ptr+(i-1)*sizeof(T))
    @inline Base.setindex!(a::MallocBuffer{T}, x::T, i::Int) where T = unsafe_store!(a.ptr+(i-1)*sizeof(T), x)
    @inline Base.setindex!(a::MallocBuffer{T}, x, i::Int) where T = unsafe_store!(a.ptr+(i-1)*sizeof(T), convert(T,x))
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

    @inline Base.:(==)(::MallocBuffer, ::MallocBuffer) = false
    @inline function Base.:(==)(a::MallocBuffer{A}, b::MallocBuffer{N,B}) where {A,B}
        length(a) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n*sizeof(A)) == unsafe_load(pb + n*sizeof(B)) || return false
        end
        return true
    end


    # Base.getindex(a::MallocBuffer, r::AbstractArray{Int}) = MallocBuffer(codetuple(s)[r]) # Should really null-terminate
    # Base.getindex(a::MallocBuffer, ::Colon) = copy(s)
