
    # General string interface

    # Supertype for all strings in this package
    abstract type AbstractStaticString end

    # A subtype for strings that are backed by a pointer and a length alone
    abstract type AbstractPointerString <: AbstractStaticString end

    # Lightweight type for taking a view into an existing string
    # Like MallocString, but not necessarily null-terminated
    struct StringView <: AbstractPointerString
        pointer::Ptr{UInt8}
        length::Int
    end
    @inline Base.length(s::StringView) = s.length

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::StringView)
        Base.print(io, "StringView: \"")
        Base.escape_string(io, Base.unsafe_string(pointer(s), length(s)))
        Base.print(io, "\"")
    end

    # Custom printing
    @inline Base.print(s::AbstractStaticString) = printf(s)
    @inline Base.println(s::AbstractStaticString) = puts(s)
    @inline Base.print(fp::Ptr{FILE}, s::AbstractStaticString) = printf(fp, s)
    @inline Base.println(fp::Ptr{FILE}, s::AbstractStaticString) = puts(fp, s)


    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, m::AbstractPointerString) where {T} = Ptr{T}(s.pointer)
    @inline Base.pointer(s::AbstractPointerString) = s.pointer
    @inline Base.sizeof(s::AbstractPointerString) = s.length
    @inline function Base.:(==)(a::AbstractStaticString, b::AbstractStaticString)
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n ∈ 0:Na
            unsafe_load(pa + n) == unsafe_load(pb + n) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::AbstractStaticString, b::AbstractString)
        GC.@preserve a b begin
            (N = length(a)) == sizeof(b) || return false
            pa, pb = pointer(a), pointer(b)
            for n in 0:N-1
                unsafe_load(pa + n) == unsafe_load(pb + n) || return false
            end
            return true
        end
    end
    @inline function Base.:(==)(a::AbstractString, b::AbstractStaticString)
        GC.@preserve a b begin
            (N = sizeof(a)) == length(b) || return false
            pa, pb = pointer(a), pointer(b)
            for n in 0:N-1
                unsafe_load(pa + n) == unsafe_load(pb + n) || return false
            end
            return true
        end
    end


    # Some of the AbstractArray interface:
    @inline Base.firstindex(s::AbstractStaticString) = 1
    @inline Base.lastindex(s::AbstractPointerString) = s.length
    @inline Base.eachindex(s::AbstractPointerString) = 1:s.length
    @inline Base.getindex(s::AbstractStaticString, i::Int) = unsafe_load(pointer(s)+(i-1))
    @inline Base.setindex!(s::AbstractStaticString, x::UInt8, i::Integer) = unsafe_store!(pointer(s)+(i-1), x)
    @inline Base.setindex!(s::AbstractStaticString, x, i::Integer) = unsafe_store!(pointer(s)+(i-1), convert(UInt8,x))
    @inline Base.getindex(s::AbstractStaticString, ::Colon) = s
    @inline function Base.getindex(s::AbstractStaticString, r::UnitRange{<:Integer})
        i₀ = max(first(r), 1) - 1
        l = min(length(r), length(s))
        return StringView(pointer(s)+i₀, l)
    end
    @inline function Base.setindex!(s::AbstractStaticString, x, r::UnitRange{<:Integer})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(r)
            s[i+is₀] = x[i+ix₀]
        end
    end
    @inline function Base.setindex!(s::AbstractStaticString, x, ::Colon)
        ix₀ = firstindex(x)-firstindex(s)
        @inbounds for i ∈ eachindex(s)
            s[i] = x[i+ix₀]
        end
    end

    # Some of the AbstractString interface
    @inline Base.ncodeunits(s::AbstractPointerString) = s.length
    @inline Base.codeunits(s::AbstractPointerString) = MallocVector{UInt8}(s.pointer, s.length)
    @inline Base.codeunit(s::AbstractStaticString) = UInt8
    @inline Base.codeunit(s::AbstractStaticString, i::Integer) = s[i]
