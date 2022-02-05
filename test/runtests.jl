using StaticTools
using Test
using ManualMemory: MemoryBuffer

@testset "StaticTools.jl" begin

    # Test StaticString constructors
    str = c"Hello, world! 🌍"
    @test isa(str, StaticString{19})
    

    # Test ascii escaping
    many_escapes = c"\0\a\b\f\n\r\t\v'\"\\"
    @test isa(many_escapes, StaticString{12})
    @test length(many_escapes) == 11
    a = codeunits(many_escapes)
    c = MemoryBuffer((codeunits("\0\a\b\f\n\r\t\v'\"\\\0")...,))
    @test a.data == b.data


end
