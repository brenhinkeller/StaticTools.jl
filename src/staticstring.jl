## ---  Define a StatiCompiler- and LLVM-compatible string type

    struct StaticString{T <: MemoryBuffer}
        buf::T
    end

    # Basics
    Base.pointer(s::StaticString) = pointer(s.buf)
    Base.codeunits(s::StaticString) = s.buf

    # Indexing
    Base.firstindex(s::StaticString) = 1
    Base.lastindex(s::StaticString{MemoryBuffer{N, UInt8}}) where N = N-1
    Base.length(s::StaticString{MemoryBuffer{N, UInt8}}) where N = N-1

    Base.getindex(s::StaticString, i::Int) = load(pointer(s)+(i-1))
    # Base.getindex(s::StaticString, I::AbstractArray{Int}) = ntuple(i->load(pointer(s)+(I[i]-1)), length(I))

    Base.setindex!(s::StaticString, x::UInt8, i::Int) = store!(pointer(s)+(i-1), x)
    Base.setindex!(s::StaticString, x, i::Int) = store!(pointer(s)+(i-1), convert(UInt8, x))
    @inline function Base.setindex!(s::StaticString, x, r::UnitRange{Int})
        is₀ = first(r)-1
        ix₀ = firstindex(x)-1
        @inbounds for i = 1:length(r)
            setindex!(s, x[i+ix₀], i+is₀)
        end
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
        print(io, "c\"")
        print(io, Base.unsafe_string(pointer(s)))
        print(io, "\"")
    end

    # String macro to create null-terminated `StaticString`s
    macro c_str(s)
        t = Expr(:tuple, codeunits(s)..., 0x00)
        quote
            StaticString(MemoryBuffer($t))
        end
    end

    # String macro to directly create null-terminated `ManualMemory.MemoryBuffer`s
    macro mm_str(s)
        t = Expr(:tuple, codeunits(s)..., 0x00)
        quote
            MemoryBuffer($t)
        end
    end
