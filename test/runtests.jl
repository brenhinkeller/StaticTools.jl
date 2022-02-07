using StaticTools
using Test
using ManualMemory: MemoryBuffer


@testset "StaticString" begin include("teststaticstring.jl") end

@testset "MemoryBuffer" begin

    # Test direct buffer constructor
    buf = mm"Hello, world! 🌍"
    @test isa(buf, MemoryBuffer{18, UInt8})

    # Test ascii escaping
    a = mm"\0\a\b\f\n\r\t\v'\"\\\0"::MemoryBuffer
    b = MemoryBuffer((codeunits("\0\a\b\f\n\r\t\v'\"\\\0")...,))
    @test a.data == b.data

end
