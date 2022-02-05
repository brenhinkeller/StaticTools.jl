## ---  Define a StatiCompiler- and LLVM-compatible string type

    struct StaticString{T <: MemoryBuffer}
        buf::T
    end

    # Basics
    Base.pointer(s::StaticString) = pointer(s.buf)
    Base.codeunits(s::StaticString) = s.buf

    # Indexing
    Base.firstindex(s::StaticString) = 1
    Base.lastindex(s::StaticString{MemoryBuffer{N, UInt8}}) where N = N
    Base.length(s::StaticString{MemoryBuffer{N, UInt8}}) where N = N
    Base.getindex(s::StaticString, i::Int) = load(pointer(s)+(i-1))
    Base.setindex!(s::StaticString, x::UInt8, i::Int) = store!(pointer(s)+(i-1), x)
    Base.setindex!(s::StaticString, x, i::Int) = store!(pointer(s)+(i-1), convert(UInt8, x))

    # Custom printing
    function Base.print(s::StaticString)
        c = codeunits(s)
        GC.@preserve c puts(c)
    end
    function Base.println(s::StaticString)
        c = codeunits(s)
        GC.@preserve c puts(c)
        newline()
    end

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::StaticString)
        print(io, "c\"")
        print(io, Base.unsafe_string(pointer(s)))
        print(io, "\"")
    end

    # String macro to create StaticStrings
    macro c_str(s)
        t = Expr(:tuple, codeunits(s)..., 0x00)
        quote
            StaticString(MemoryBuffer($t))
        end
    end

    # String macro to directly create `ManualMemory.MemoryBuffer`s
    macro mm_str(s)
        t = Expr(:tuple, codeunits(s)..., 0x00)
        quote
            MemoryBuffer($t)
        end
    end
