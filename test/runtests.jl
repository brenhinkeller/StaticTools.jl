using StaticTools
using Test
using ManualMemory: MemoryBuffer

const GROUP = get(ENV, "GROUP", "All")

@static if GROUP == "Core" || GROUP == "All"
    @testset "IO" begin include("testllvmio.jl") end
    @testset "libc" begin include("testllvmlibc.jl") end
    @testset "Parsing" begin include("testparse.jl") end
    @testset "StaticString" begin include("teststaticstring.jl") end
    @testset "MallocString" begin include("testmallocstring.jl") end
    @testset "MallocArray" begin include("testmallocarray.jl") end
    @testset "StaticRNG" begin include("teststaticrng.jl") end
    @testset "MemoryBuffer" begin

        # Test direct buffer constructor
        buf = mm"Hello, world! 🌍"
        @test isa(buf, MemoryBuffer{18, UInt8})

        # Test ascii escaping
        a = mm"\0\a\b\f\n\r\t\v'\"\\\0"::MemoryBuffer
        b = MemoryBuffer((codeunits("\0\a\b\f\n\r\t\v'\"\\\0")...,))
        @test a.data == b.data

    end
end

using LoopVectorization
@static if GROUP == "Integration" || GROUP == "All"
    @testset "StaticCompiler" begin include("teststaticcompiler.jl") end
end
