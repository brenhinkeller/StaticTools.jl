module StaticTools

    # External dependencies
    using ManualMemory: MemoryBuffer, load, store!

    # Declare some types we'll use later
    struct FILE end # Plain struct to denote and dispatch on file pointers

    # Manual memory allocation
    include("mallocbuffer.jl")  # 🎶 Manage your memory with malloc and free! 🎶
    include("mallocarray.jl")

    # String handling
    include("unescape.jl")      # You don't want to know
    include("staticstring.jl")  # StaticCompiler-safe stack-allocated strings
    include("mallocstring.jl")  # StaticCompiler-safe heap-allocated strings

    # Union of things that don't need GC.@protect
    const AbstractMallocdMemory = Union{MallocString, MallocBuffer, MallocArray}

    # Here there be `llvmcall`s
    include("llvmio.jl")        # Best way to print things? LLVM IR obviously!
    include("llvmlibc.jl")      # strtod, strtol, parse, etc...

    # higher-level printing
    include("printformats.jl")


    # Types
    export StaticString, MallocString, MallocArray, MallocMatrix, MallocVector
    # Macros
    export @c_str, @m_str, @mm_str
    # Functions
    export malloc, free
    export newline, putchar, puts, printf
    export stdinp, stdoutp, stderrp, fopen, fclose # File pointers
    export unsafe_mallocstring, strlen, free

end
