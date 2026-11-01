using StaticTools
using Test
using ManualMemory: MemoryBuffer
using LinearAlgebra

const GROUP = get(ENV, "GROUP", "Default")

@static if GROUP == "Core" || GROUP == "Default" || GROUP == "All"
    @testset "IO" begin include("testllvmio.jl") end
    @testset "libc" begin include("testllvmlibc.jl") end
    @testset "interop" begin include("testllvminterop.jl") end
    @testset "Parsing" begin include("testparse.jl") end
    @testset "MallocSlabBuffer" begin include("testslab.jl") end
    @testset "StaticString" begin include("teststaticstring.jl") end
    @testset "MallocString" begin include("testmallocstring.jl") end
    @testset "MallocArray" begin include("testmallocarray.jl") end
    @testset "StackArray" begin include("teststackarray.jl") end
    @testset "StaticLinearAlgebra" begin include("teststaticlinearalgebra.jl") end
    @testset "StaticRNG" begin include("teststaticrng.jl") end
    @testset "static_type" begin include("teststatic_type.jl") end
end

@static if GROUP == "Utilities" || GROUP == "Default" || GROUP == "All"
    @testset "static_type" begin include("teststatic_type.jl") end
end

# Setup
testpath = pwd()
scratch = tempdir()
@info "compiling in scratch directory $scratch"
jlpath = joinpath(Sys.BINDIR, Base.julia_exename()) # Get path to julia executable

# To remove output files
cleanup(files...) = foreach(f -> isfile(f) && rm(f), files)

@static if GROUP == "Integration" || GROUP == "All"
    @testset "StaticCompiler" begin include("teststaticcompiler.jl") end
end

using LoopVectorization
@static if GROUP == "LoopVectorization" || GROUP == "All"
    @testset "LoopVectorization" begin include("testloopvectorization.jl") end
end