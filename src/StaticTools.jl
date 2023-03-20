module StaticTools

    # External dependencies
    using ManualMemory: MemoryBuffer, load, store!
    using LoopVectorization
    import Random: rand!, randn!

    # Declare some types we'll use later
    struct FILE end # Plain struct to denote and dispatch on file pointers
    struct DYLIB end # Plain struct to denote and dispatch pointers to dlopen'd shlibs

    # String handling
    include("abstractstaticstring.jl")  # Shared string infrastructure
    include("unescape.jl")      # You don't want to know
    include("staticstring.jl")  # StaticCompiler-safe stack-allocated strings
    include("mallocstring.jl")  # StaticCompiler-safe heap-allocated strings

    # Arrays backed by malloc'd and alloca'd memory
    include("abstractstaticarray.jl")  # Shared array infrastructure
    include("staticlinearalgebra.jl")  # Shared array infrastructure
    include("stackarray.jl")           # StackArray, StackMatrix, StackVector
    include("mallocarray.jl")          # MallocArray, MallocMatrix, MallocVector

    # Union of things that don't need GC.@protect
    const AbstractMallocdMemory = Union{MallocString, MallocArray}

    # Here there be `llvmcall`s
    include("llvminterop.jl")   # dlopen/sym/close, @ptrcall, @symbolcall, @externload
    include("llvmio.jl")        # Best way to print things? LLVM IR obviously!
    include("llvmlibc.jl")      # strtod, strtol, parse, etc...

    # higher-level printing, parsing, etc.
    include("printformats.jl")
    include("parsedlm.jl")

    # Random number generation
    include("staticrng.jl")
    include("ziggurat.jl")

    # Types
    export StaticString, MallocString, StringView, AbstractStaticString         # String types
    export MallocArray, MallocMatrix, MallocVector                              # Heap-allocated array types
    export StackArray, StackMatrix, StackVector                                 # Stack-allocated array types
    export ArrayView
    export SplitMix64, Xoshiro256✴︎✴︎, BoxMuller, MarsagliaPolar, Ziggurat        # RNG types

    # Macros
    export @c_str, @m_str, @mm_str
    export @ptrcall, @symbolcall, @externptr, @externload

    # Functions
    export ⅋, malloc, calloc, free, memset!, memcpy!, memcmp                    # Memory management
    export mfill, mzeros, mones, meye, mrand, mrandn                            # Other MallocArray functions
    export sfill, szeros, sones, seye, srand, srandn                            # Other StackArray functions
    export stdinp, stdoutp, stderrp                                             # File pointers
    export fopen, fclose, ftell, frewind, fseek, SEEK_SET, SEEK_CUR, SEEK_END   # File open, close, seek
    export usleep                                                               # Other libc utility functions
    export newline, putchar, getchar, getc, puts, gets!, readline!              # Char & String IO
    export fwrite, fread!                                                       # String and Binary IO
    export unsafe_mallocstring, strlen                                          # String management
    export printf, printdlm, parsedlm, argparse                                # File parsing and formatting
    export static_rng, splitmix64, xoshiro256✴︎✴︎, rand!, randn!                  # RNG functions
end
