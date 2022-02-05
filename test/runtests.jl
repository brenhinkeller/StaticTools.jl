using StaticTools
using Test
using ManualMemory: MemoryBuffer

@testset "StaticTools.jl" begin

    # Test StaticString constructors
    str = c"Hello, world! 🌍"
    @test isa(str, StaticString{19})

    # Test basic string operations
    @test str == c"Hello, world! 🌍"
    @test str*str == str^2

    # Test direct buffer constructor
    buf = mm"Hello, world! 🌍"
    @test isa(buf, MemoryBuffer{18, UInt8})

    # Test ascii escaping
    many_escapes = c"\0\a\b\f\n\r\t\v'\"\\"
    @test isa(many_escapes, StaticString{12})
    @test length(many_escapes) == 11
    a = codeunits(many_escapes)::MemoryBuffer
    b = mm"\0\a\b\f\n\r\t\v'\"\\\0"::MemoryBuffer
    @test a.data == b.data
    c = MemoryBuffer((codeunits("\0\a\b\f\n\r\t\v'\"\\\0")...,))
    @test b.data == c.data


end
