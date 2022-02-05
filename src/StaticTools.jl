module StaticTools

    using ManualMemory: MemoryBuffer, load, store!

    # StaticString type
    include("staticstring.jl")

    # Tools for IO with LLVM
    include("llvmio.jl")

    export @c_str, @mm_str, putchar, puts, printf

end
