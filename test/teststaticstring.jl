## --- Test `StaticString`s

    # Test StaticString constructors
    str = c"Hello, world! 🌍"
    @test isa(str, StaticString{19})
    @test print(str) == 0
    @test println(str) == 0
    @test printf(str) == 0
    @test puts(str) == 0

    # Test basic string operations
    @test str == c"Hello, world! 🌍"
    @test str*str == str^2

    # Test ascii escaping
    many_escapes = c"\0\a\b\f\n\r\t\v'\"\\"
    @test isa(many_escapes, StaticString{12})
    @test length(many_escapes) == 12
    a = codeunits(many_escapes)::Tuple
    @test a == (codeunits("\0\a\b\f\n\r\t\v'\"\\\0")...,)
