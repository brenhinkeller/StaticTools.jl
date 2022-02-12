module StaticTools

    # External dependencies
    using ManualMemory: MemoryBuffer, load, store!

    # Declare some types we'll use for dispatch later
    abstract type AbstractMallocdMemory end

    # Manual memory allocation
    include("mallocbuffer.jl")  # 🎶 Manage your memory with malloc and free! 🎶

    # String handling
    include("unescape.jl")      # You don't want to know
    include("staticstring.jl")  # StaticCompiler-safe stack-allocated strings
    include("mallocstring.jl")  # StaticCompiler-safe heap-allocated strings

    # Here there be `llvmcall`s
    include("llvmio.jl")        # Best way to print things? LLVM IR obviously!
    include("llvmlibc.jl")      # strtod, strtol, parse, etc...
    include("printformats.jl")        # Best way to print things? LLVM IR obviously!


    # Types
    export StaticString, MallocString, MallocBuffer, AbstractMallocdMemory
    # Macros
    export @c_str, @m_str, @mm_str
    # Functions
    export newline, putchar, puts, printf, fprintf, fopen, fclose, strlen
    export unsafe_mallocstring, free

end
