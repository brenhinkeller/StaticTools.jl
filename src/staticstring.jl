## ---  Define a StatiCompiler- and LLVM-compatible string type

    struct LLVMString{T <: MemoryBuffer}
        buf::T
    end

    # Basics
    Base.pointer(s::LLVMString) = pointer(s.buf)
    Base.codeunits(s::LLVMString) = s.buf

    # Setindex/getindex
    Base.getindex(s::LLVMString, i::Int) = load(pointer(s)+(i-1))
    Base.setindex!(s::LLVMString, x::UInt8, i::Int) = store(pointer(s)+(i-1), x)
    Base.setindex!(s::LLVMString, x, i::Int) = store!(pointer(s)+(i-1), convert(UInt8, x))

    # Custom printing
    Base.print(s::LLVMString) = puts(s)
    Base.println(s::LLVMString) = (puts(s); newline())

    # Custom replshow for interactive use (n.b. _NOT_ static-compilerable)
    function Base.show(io::IO, s::LLVMString)
        print(io, "c\"")
        print(io, Base.unsafe_string(pointer(s)))
        print(io, "\"")
    end

    # String macro to create StaticStrings
    macro c_str(s)
        t = Expr(:tuple, codeunits(s)..., 0x00)
        quote
            LLVMString(MemoryBuffer($t))
        end
    end

    # macro mm_str(s)
    #     t = Expr(:tuple, codeunits(s)...)
    #     quote
    #         MemoryBuffer($t)
    #     end
    # end
