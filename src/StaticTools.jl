module StaticTools

    # External dependencies
    using ManualMemory: MemoryBuffer, load, store!

    # Declare some empty types we'll use for dispatch, etc., later
    abstract type AbstractMallocdMemory end # that doesn't need GC.@protect
    struct FILE end # Plain struct to denote and dispatch on file pointers

    # Manual memory allocation
    include("mallocbuffer.jl")  # 🎶 Manage your memory with malloc and free! 🎶

    # String handling
    include("unescape.jl")      # You don't want to know
    include("staticstring.jl")  # StaticCompiler-safe stack-allocated strings
    include("mallocstring.jl")  # StaticCompiler-safe heap-allocated strings

    # Here there be `llvmcall`s
    include("llvmio.jl")        # Best way to print things? LLVM IR obviously!
    include("llvmlibc.jl")      # strtod, strtol, parse, etc...

    # higher-level printing
    include("printformats.jl")


    # Types
    export StaticString, MallocString, MallocBuffer, AbstractMallocdMemory
    # Macros
    export @c_str, @m_str, @mm_str
    # Functions
    export newline, putchar, puts, printf
    export stdinp, stdoutp, stderrp, fopen, fclose # File pointers
    export unsafe_mallocstring, strlen, free

end
