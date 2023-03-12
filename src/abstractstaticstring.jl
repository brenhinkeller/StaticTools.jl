
    # General string interface

    # Supertype for all strings in this package
    abstract type AbstractStaticString <: AbstractString end

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
        Base.print(io, "$(length(s))-byte StringView:\n \"")
        Base.escape_string(io, Base.unsafe_string(pointer(s), length(s)))
        Base.print(io, "\"")
    end

    # Custom printing
    @inline Base.print(s::AbstractStaticString) = printf(s)
    @inline Base.println(s::AbstractStaticString) = puts(s)
    @inline Base.print(fp::Ptr{FILE}, s::AbstractStaticString) = printf(fp, s)
    @inline Base.println(fp::Ptr{FILE}, s::AbstractStaticString) = puts(fp, s)


    # Fundamentals
    @inline Base.unsafe_convert(::Type{Ptr{T}}, s::AbstractPointerString) where {T} = Ptr{T}(s.pointer)
    @inline Base.pointer(s::AbstractPointerString) = s.pointer
    @inline Base.sizeof(s::AbstractPointerString) = s.length
    @inline function Base.:(==)(a::AbstractStaticString, b::AbstractStaticString)
        (N = length(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n) == unsafe_load(pb + n) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::AbstractStaticString, b::AbstractString)
        (N = length(a)) == sizeof(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n) == unsafe_load(pb + n) || return false
        end
        return true
    end
    @inline function Base.:(==)(a::AbstractString, b::AbstractStaticString)
        (N = sizeof(a)) == length(b) || return false
        pa, pb = pointer(a), pointer(b)
        for n in 0:N-1
            unsafe_load(pa + n) == unsafe_load(pb + n) || return false
        end
        return true
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
    @inline Base.:*(a::AbstractStaticString, b::AbstractStaticString) = _concat_staticstring(a,b)
    @inline Base.:*(a::AbstractStaticString, b::AbstractString) = _concat_staticstring(a,b)
    @inline Base.:*(a::AbstractString, b::AbstractStaticString) = _concat_staticstring(a,b)
    @inline function _concat_staticstring(a::AbstractString, b::AbstractString)  # Concatenation
        N = length(a) + length(b) + 1 # n.b. `length` excludes null-termination
        c = StaticString{N}(undef)
        c[1:length(a)] = a
        c[length(a)+1:length(a)+length(b)] = b
        c[end] = 0x00 # Null-terminate
        return c
    end
    @inline function Base.:^(s::AbstractStaticString, n::Integer)       # Repetition
        l = length(s) # Excluding null-termination
        N = n*l + 1
        c = StaticString{N}(undef)
        for i=1:n
            c[(l*(i-1) + 1):(l*i)] = s
        end
        c[end] = 0x00 # Null-terminate
        return c
    end

    # Other handy functions
    @inline function Base.contains(haystack::AbstractStaticString, needle::AbstractStaticString)
        lₕ, lₙ = length(haystack), length(needle)
        lₕ < lₙ && return false
        for i ∈ 0:(lₕ-lₙ)
            (haystack[1+i:lₙ+i] == needle) && return true
        end
        return false
    end
    
    # Adapted from Julia's stdlib
    """
        iterate(s::AbstractStaticString, i=firstindex(s))

    Adapted form Julia's stdlib, but made type-stable. 

    !!! warning "Return type"
        
        The interface is a bit different from `Base`. When iterating outside of
        the string, it will return the Null character and the current index.

    # Examples

    ```jldoctest
    julia> s = c"foo"
    c"foo"

    julia> iterate(s, 1)
    ('f', 2)

    julia> iterate(s, 99999)
    ('\\0', 99999)
    ```
    """
    @inline function Base.iterate(s::AbstractStaticString, i::Int=firstindex(s))
        ((i % UInt) - 1 < ncodeunits(s) && s[i] ≠ 0x00) || return ('\0', i)
        b = @inbounds codeunit(s, i)
        u = UInt32(b) << 24
        between(b, 0x80, 0xf7) || return reinterpret(Char, u), i+1
        return iterate_continued(s, i, u)
    end
    @inline between(b::T, lo::T, hi::T) where {T<:Integer} = (lo ≤ b) & (b ≤ hi)
    @inline function iterate_continued(s::AbstractStaticString, i::Int, u::UInt32)
        u < 0xc0000000 && (i += 1; @goto ret)
        n = ncodeunits(s)
        # first continuation byte
        (i += 1) > n && @goto ret
        @inbounds b = codeunit(s, i)
        b & 0xc0 == 0x80 || @goto ret
        u |= UInt32(b) << 16
        # second continuation byte
        ((i += 1) > n) | (u < 0xe0000000) && @goto ret
        @inbounds b = codeunit(s, i)
        b & 0xc0 == 0x80 || @goto ret
        u |= UInt32(b) << 8
        # third continuation byte
        ((i += 1) > n) | (u < 0xf0000000) && @goto ret
        @inbounds b = codeunit(s, i)
        b & 0xc0 == 0x80 || @goto ret
        u |= UInt32(b); i += 1
        @label ret
        return reinterpret(Char, u), i
    end
    @inline Base.isvalid(s::AbstractStaticString, i::Int) = checkbounds(Bool, s, i) && thisind(s, i) == i
    @inline Base.isvalid(::Type{T}, s::Union{Vector{UInt8},Base.FastContiguousSubArray{UInt8,1,Vector{UInt8}},T}) where {T <: AbstractStaticString} = ccall(:u8_isvalid, Int32, (Ptr{UInt8}, Int), s, sizeof(s)) ≠ 0
    @inline function Base.thisind(s::AbstractStaticString, i::Int)
        i == 0 && return 0
        n = ncodeunits(s)
        i == n + 1 && return i
        @boundscheck between(i, 1, n) || throw(BoundsError(s, i))
        @inbounds b = codeunit(s, i)
        (b & 0xc0 == 0x80) & (i-1 > 0) || return i
        @inbounds b = codeunit(s, i-1)
        between(b, 0b11000000, 0b11110111) && return i-1
        (b & 0xc0 == 0x80) & (i-2 > 0) || return i
        @inbounds b = codeunit(s, i-2)
        between(b, 0b11100000, 0b11110111) && return i-2
        (b & 0xc0 == 0x80) & (i-3 > 0) || return i
        @inbounds b = codeunit(s, i-3)
        between(b, 0b11110000, 0b11110111) && return i-3
        return i
    end
    """
        prevind(str::AbstractStaticString, i::Integer, n::Integer=1) -> Int

    Adapted form Julia's stdlib, but made type-stable. 

    !!! warning "Type-stability and exceptions"
        
        The interface is a bit different from `Base`. To make it compile-able,
        we need to remove all throw cases. The method behaves as close as it 
        can from the original.

        The method won't throw `BoundsError` anymore, but will return the closest
        index (0 or `ncodeunits(s)+1`).

    # Examples
     
    ```jldoctest
    julia> prevind(c"α", 3)
    1
    julia> prevind(c"α", 1)
    0
    julia> prevind(c"α", 0)
    0
    julia> prevind(c"α", 2, 2)
    0
    julia> prevind(c"α", 2, 3)
    -1
    ```
    """
    @inline function Base.prevind(s::AbstractStaticString, i::Int, n::Int=1)
        n < 0 && return i
        z = ncodeunits(s) + 1
        @boundscheck 0 < i ≤ z || return i<=0 ? 0 : z-1
        n == 0 && return thisind(s, i)
        while n > 0 && 1 < i
            @inbounds n -= isvalid(s, i -= 1)
        end
        return i - n
    end
    """
        nextind(s::AbstractString, i::Int, n::Int=1) -> Int

    Adapted form Julia's stdlib, but made type-stable. 

    !!! warning "Type-stability and exceptions"
        
        The interface is a bit different from `Base`. To make it compile-able,
        we need to remove all throw cases. The method behaves as close as it 
        can from the original.

        The method won't throw `BoundsError` anymore, but will return the closest
        index (0 or `ncodeunits(s)+1`).

    # Examples

    ```jldoctest
    julia> nextind(c"α", 0)
    1
    julia> nextind(c"α", 1)
    3
    julia> nextind(c"α", 3)
    3
    julia> nextind(c"α", 0, 2)
    3
    julia> nextind(c"α", 1, 2)
    4
    ```

    """
    @inline function Base.nextind(s::AbstractStaticString, i::Int, n::Int=1)
        n < 0 && return i
        z = ncodeunits(s)
        @boundscheck 0 ≤ i ≤ z-1 || return i<=0 ? 0 : z
        n == 0 && return thisind(s, i)
        while n > 0 && i < z
            @inbounds n -= isvalid(s, i += 1)
        end
        return i + n
    end
    @inline function Base.endswith(a::AbstractStaticString, b::AbstractStaticString)
        i, j = iterate(a, prevind(a, lastindex(a))), iterate(b, prevind(b, lastindex(b)))
        while true
            j[2] < firstindex(b) && return true # ran out of suffix: success!
            i[2] < firstindex(a) && return false # ran out of source: failure
            i[1] == j[1] || return false # mismatch: failure
            i, j = iterate(a, prevind(a, i[2], 2)), iterate(b, prevind(b, j[2], 2))
        end
    end
    @inline function Base.startswith(a::AbstractStaticString, b::AbstractStaticString)
       i, j = iterate(a), iterate(b)
       while true
           j[1] === '\0' && return true # ran out of prefix: success!
           i[1] === '\0' && return false # ran out of source: failure
           i[1] == j[1] || return false # mismatch: failure
           i, j = iterate(a, i[2]), iterate(b, j[2])
        end
    end
