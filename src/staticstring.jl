## ---  Define a StatiCompiler- and LLVM-compatible string type

    # Define the StaticString type, backed by a ManualMemory.MemoryBuffer
    struct StaticString{N,T}
        buf::MemoryBuffer{N,T}
    end
    StaticString{N}(::UndefInitializer) where N = StaticString(MemoryBuffer{N, UInt8}(undef))
    StaticString(data::NTuple) = StaticString(MemoryBuffer(data))

    # Basics
    Base.pointer(s::StaticString) = pointer(s.buf)
    Base.codeunits(s::StaticString) = s.buf
    codetuple(s::StaticString) = s.buf.data
    Base.:(==)(a::StaticString, b::StaticString) = a.buf.data == b.buf.data
    Base.copy(s::StaticString) = StaticString(codetuple(s))

    # Indexing
    Base.firstindex(s::StaticString) = 1
    Base.lastindex(s::StaticString{N}) where N = N-1
    Base.length(s::StaticString{N}) where N = N-1

    Base.getindex(s::StaticString, i::Int) = load(pointer(s)+(i-1))
    Base.getindex(s::StaticString, r::AbstractArray{Int}) = StaticString(codetuple(s)[r]) # Should  really null-terminate
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
        l = length(a) + length(b) + 1
        c = StaticString(MemoryBuffer{l, UInt8}(undef))
        c[1:length(a)] = a
        c[1+length(a):end] = b
        c[end+1] = 0x00 # Null-terminate
        return c
    end

    # Repetition
    @inline function Base.:^(s::StaticString, n::Integer)
        l = length(s)*n + 1
        c = StaticString(MemoryBuffer{l, UInt8}(undef))
        for i=1:n
            c[(1+(i-1)*length(s)):(i*length(s))] = s
        end
        c[end+1] = 0x00 # Null-terminate
        return c
    end

    # Custom printing
    function Base.print(s::StaticString)
        c = codeunits(s)
        GC.@preserve c printf(c)
    end
    function Base.println(s::StaticString)
        c = codeunits(s)
        GC.@preserve c puts(c)
    end

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::StaticString)
        Base.print(io, "c\"")
        Base.escape_string(io, Base.unsafe_string(pointer(s)))
        Base.print(io, "\"")
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

    # Process any ASCII escape sequences in a raw string captured by string macro
    function _unsafe_unescape!(c)
        n = length(c)
        a = Base.unsafe_wrap(Array, pointer(c)::Ptr{UInt8}, n)
        for i = 1:n
            if a[i] == 0x5c # \
                if a[i+1] == 0x30 # \0
                    a[i] = 0x00
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x61 # \a
                    a[i] = 0x07
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x62 # \b
                    a[i] = 0x08
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x66 # \f
                    a[i] = 0x0c
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x6e # \n
                    a[i] = 0x0a
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x72 # \r
                    a[i] = 0x0d
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x74 # \t
                    a[i] = 0x09
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x76 # \v
                    a[i] = 0x0b
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x5c # \\
                    a[i] = 0x5c
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x27 # \'
                    a[i] = 0x27
                    n = _advance!(a, i+1, n)
                elseif a[i+1] == 0x22 # \"
                    a[i] = 0x22
                    n = _advance!(a, i+1, n)
                end
            end
        end
        return n
    end

    @inline function _advance!(a::AbstractArray{UInt8}, i::Int, n::Int)
        copyto!(a, i, a, i+1, n-i)
        a[n] = 0x00
        n -= 1
    end
