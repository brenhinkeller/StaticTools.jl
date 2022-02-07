## ---  Define a StatiCompiler- and LLVM-compatible statically-sized string type

    # Define the StaticString type, backed by a ManualMemory.MemoryBuffer

    # Definition and constructors:
    struct StaticString{N,T}
        buf::MemoryBuffer{N,T}
    end
    StaticString{N}(::UndefInitializer) where N = StaticString(MemoryBuffer{N, UInt8}(undef))
    StaticString(data::NTuple) = StaticString(MemoryBuffer(data))

    # Basics
    Base.ncodeunits(s::StaticString{N}) where N = N
    Base.codeunits(s::StaticString) = s.buf
    Base.pointer(s::StaticString) = pointer(s.buf)
    codetuple(s::StaticString) = s.buf.data
    Base.:(==)(a::StaticString, b::StaticString) = codetuple(a) == codetuple(b)
    Base.copy(s::StaticString) = StaticString(codetuple(s))

    # Indexing
    Base.firstindex(s::StaticString) = 1
    Base.lastindex(s::StaticString{N}) where N = N
    Base.length(s::StaticString{N}) where N = N

    Base.getindex(s::StaticString, i::Int) = load(pointer(s)+(i-1))
    Base.getindex(s::StaticString, r::AbstractArray{Int}) = StaticString(codetuple(s)[r]) # Should really null-terminate
    Base.getindex(s::StaticString, ::Colon) = copy(s)

    Base.setindex!(s::StaticString, x::UInt8, i::Int) = store!(pointer(s)+(i-1), x)
    Base.setindex!(s::StaticString, x, i::Int) = store!(pointer(s)+(i-1), convert(UInt8, x))
    @inline function Base.setindex!(s::StaticString, x, r::UnitRange{Int})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(r)
            setindex!(s, x[i+ix₀], i+is₀)
        end
    end
    @inline function Base.setindex!(s::StaticString, x, ::Colon)
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(s)
            setindex!(s, x[i+ix₀], i)
        end
    end

    # Concatenation
    @inline function Base.:*(a::StaticString, b::StaticString)
        N = length(a) + length(b) - 1
        c = StaticString(MemoryBuffer{N, UInt8}(undef))
        c[1:length(a)-1] = a
        c[length(a):end-1] = b
        c[end] = 0x00 # Null-terminate
        return c
    end

    # Repetition
    @inline function Base.:^(s::StaticString, n::Integer)
        l = length(s)-1 # Excluding the null-termination
        N = n*l + 1
        c = StaticString(MemoryBuffer{N, UInt8}(undef))
        for i=1:n
            c[(l*(i-1) + 1):(l*i)] = s
        end
        c[end] = 0x00 # Null-terminate
        return c
    end

    # Custom printing
    Base.print(s::StaticString) = printf(s)
    Base.println(s::StaticString) = puts(s)

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::StaticString)
        Base.print(io, "c\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
    end

    # As Base.unsafe_string, but loading to a StaticString instead
    @inline function unsafe_staticstring(p::Ptr{UInt8})
        len = 1
        while unsafe_load(p, len) != 0x00
            len +=1
        end
        s = StaticString{len}(undef)
        for i=1:len
            s[i] = unsafe_load(p, i)
        end
        return s
    end

    # String macro to create null-terminated `StaticString`s
    macro c_str(s)
        n = _unsafe_unescape!(s)
        t = Expr(:tuple, codeunits(s[1:n])..., 0x00)
        :(StaticString($t))
    end

    # String macro to directly create null-terminated `ManualMemory.MemoryBuffer`s
    macro mm_str(s)
        n = _unsafe_unescape!(s)
        t = Expr(:tuple, codeunits(s[1:n])...)
        :(MemoryBuffer($t))
    end
