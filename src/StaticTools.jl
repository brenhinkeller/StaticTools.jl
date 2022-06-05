module StaticTools

    if !(v"1.8.0-DEV" < VERSION < v"1.9.0-DEV")
        @warn "StaticTools + StaticCompiler integration is best supported on Julia 1.8.\n Consider switching to a different Julia version"
    end

    # External dependencies
    using ManualMemory: MemoryBuffer, load, store!

    # Declare some types we'll use later
    struct FILE end # Plain struct to denote and dispatch on file pointers
    struct DYLIB end # Plain struct to denote and dispatch pointers to dlopen'd shlibs

    # Manual memory allocation
    include("mallocarray.jl")
    include("staticrng.jl")

    # String handling
    include("abstractstaticstring.jl")  # Shared string infrastructure
    include("unescape.jl")      # You don't want to know
    include("staticstring.jl")  # StaticCompiler-safe stack-allocated strings
    include("mallocstring.jl")  # StaticCompiler-safe heap-allocated strings

    # Union of things that don't need GC.@protect
    const AbstractMallocdMemory = Union{MallocString, MallocArray}

    # Here there be `llvmcall`s
    include("llvminterop.jl")   # dlopen/sym/close, @ptrcall, @symbolcall
    include("llvmio.jl")        # Best way to print things? LLVM IR obviously!
    include("llvmlibc.jl")      # strtod, strtol, parse, etc...

    # higher-level printing, parsing, etc.
    include("printformats.jl")
    include("parsedlm.jl")

    # Types
    export StaticString, MallocString, StringView, AbstractStaticString
    export MallocArray, MallocMatrix, MallocVector
    # Macros
    export @c_str, @m_str, @mm_str
    export @ptrcall, @symbolcall

    # Functions
    export malloc, calloc, free, memset!, memcpy!, memcmp                       # Memory management
    export mfill, mzeros, mones                                                 # Other MallocArray functions
    export stdinp, stdoutp, stderrp                                             # File pointers
    export fopen, fclose, ftell, frewind, fseek, SEEK_SET, SEEK_CUR, SEEK_END   # File open, close, seek
    export usleep                                                               # Other libc utility functions
    export newline, putchar, getchar, getc, puts, gets!, fread!, readline!      # Char & String IO
    export unsafe_mallocstring, strlen                                          # String management
    export parsedlm, printf                                                     # File parsing and formatting
    export static_rng, xoshiro256✴︎✴︎, Xoshiro256✴︎✴︎, splitmix64, SplitMix64       # Random number generation
end
