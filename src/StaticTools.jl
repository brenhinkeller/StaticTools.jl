module StaticTools

    # External dependencies
    using ManualMemory: MemoryBuffer, load, store!

    # Declare any abstract types we'll be subtyping later
    abstract type AbstractMallocdMemory end

    # Here there be `llvmcall`s
    include("llvmlibc.jl")       # 🎶 Pointers, assembly,...

    # Manual memory allocation
    include("mallocbuffer.jl")   #...manage your memory with malloc and free! 🎶

    # String handling
    include("unescape.jl")       # You don't want to know
    include("staticstring.jl")   # StaticCompiler-safe stack-allocated strings
    include("mallocstring.jl")   # StaticCompiler-safe heap-allocated strings

    # What's the best way to print things? LLVM IR obviously
    include("llvmio.jl")

    # Types
    export StaticString, MallocString, MallocBuffer
    # Macros
    export @c_str, @m_str, @mm_str
    # Functions
    export newline, putchar, puts, printf
    export unsafe_mallocstring, free

end
