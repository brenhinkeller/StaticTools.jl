## --- Test `StaticString`s

    # Test StaticString constructors
    str = c"Hello, world! 🌍"
    @test isa(str, StaticString{19})
    @test sizeof(str) == 19
    @test StaticTools.strlen(str) == length(str) == 18
    str1 = StaticString(str[1:end])
    @test isa(str1, StaticString{19})

    # Test basic string operations
    @test str == c"Hello, world! 🌍"
    @test str*str == str^2
    @test codeunit(str) === UInt8
    @test codeunit(str, 5) == UInt8('o')
    @test ncodeunits(str) == length(str)+1
    @test codeunits(c"Hello") == codeunits(c"Hello")

    # Test mutability
    str[8] = 'W'
    @test str[8] == 0x57 # W
    str[:] = c"Hello, world! 🌍"
    @test str[8] == 0x77 # w

    # Test indexing
    @test isa(str[1:end], StringView)
    @test str == str[1:end]
    @test str == str[:]
    @test str[1:2] == str[1:2]
    @test str[1:2] != str[1:3]
    @test str == copy(str)

    # Test ascii escaping
    many_escapes = c"\"\0\a\b\f\n\r\t\v\'\"\\"
    @test isa(many_escapes, StaticString{13})
    @test length(many_escapes) == 12
    @test all(codeunits(many_escapes) .== codeunits("\"\0\a\b\f\n\r\t\v'\"\\\0"))

    # Test consistency with other strings
    abc = c"abc"
    @test abc == "abc"
    @test abc == c"abc"
    @test abc == abc[1:3]
    @test abc[1:3] == "abc"
