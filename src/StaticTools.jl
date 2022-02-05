module StaticTools

    using ManualMemory: MemoryBuffer

    # LLVMString type
    include("staticstring.jl")

    # Tools for IO with LLVM
    include("llvmio.jl")


end
