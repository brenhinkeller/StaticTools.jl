module StaticTools

    using ManualMemory: MemoryBuffer, load, store!

    # StaticString type
    include("staticstring.jl")

    # Tools for IO with LLVM
    include("llvmio.jl")

    # Types
    export StaticString
    # Macros
    export @c_str, @mm_str
    # Functions
    export putchar, puts, printf

end
