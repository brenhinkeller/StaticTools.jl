module StaticTools

    # External dependencies
    using ManualMemory: MemoryBuffer, load, store!

    # Declare some types we'll use later
    struct FILE end # Plain struct to denote and dispatch on file pointers

    # Manual memory allocation
    include("mallocarray.jl")
    include("staticrng.jl")

    # String handling
    include("unescape.jl")      # You don't want to know
    include("staticstring.jl")  # StaticCompiler-safe stack-allocated strings
    include("mallocstring.jl")  # StaticCompiler-safe heap-allocated strings

    # Union of things that don't need GC.@protect
    const AbstractMallocdMemory = Union{MallocString, MallocArray}

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
    export getchar, gets!
    export stdinp, stdoutp, stderrp, fopen, fclose # File pointers
    export fseek, SEEK_SET, SEEK_CUR, SEEK_END
    export unsafe_mallocstring, strlen, free
    export static_rng, StaticRNG, xoshiro256✴︎✴︎, Xoshiro256✴︎✴︎, splitmix64, SplitMix64

end
