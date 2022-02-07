module StaticTools

    using ManualMemory: MemoryBuffer, load, store!

    # Manual memory allocation:
    include("mallocbuffer.jl")

    # String handling
    include("unescape.jl")
    include("staticstring.jl")
    include("mallocstring.jl")

    # Tools for IO with LLVM
    include("llvmio.jl")

    # Types
    export StaticString, MallocString, MallocBuffer
    # Macros
    export @c_str, @m_str, @mm_str
    # Functions
    export newline, putchar, puts, printf
    export unsafe_mallocstring, free

end
