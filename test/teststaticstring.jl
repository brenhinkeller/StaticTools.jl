## --- Test `StaticString`s

    # Test StaticString constructors
    str = c"Hello, world! 🌍"
    @test isa(str, StaticString{19})
    @test sizeof(str) == 19
    @test StaticTools.strlen(str) == length(str) == 18
    @test pointer(str) == Base.unsafe_convert(Ptr{UInt8}, str)
    str1 = StaticString(str[1:end])
    @test isa(str1, StaticString{19})

    # Test basic string operations
    @test str == c"Hello, world! 🌍"
    @test str*str == str^2
    @test codeunit(str) === UInt8
    @test codeunit(str, 5) == UInt8('o')
    @test ncodeunits(str) == length(str)+1
    @test codeunits(c"Hello") == codeunits(c"Hello")

    # Test concatenation with different string types
    c=c"asdf"
    @test c*c == c"asdfasdf"
    @test c*"asdf" == c"asdfasdf"
    @test "asdf"*c == c"asdfasdf"
    @test c[1:3]^2 == c"asdasd"
    @test c[1:3]*c[1:3] == c"asdasd"
    @test c[1:3]*c"asd" == c"asdasd"
    @test c"asd"*c[1:3] == c"asdasd"
    @test c[1:3]*"asd" == c"asdasd"
    @test "asd"*c[1:3] == c"asdasd"

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
    @test "abc" == abc
    @test abc == c"abc"
    @test abc == abc[1:3]
    @test abc[1:3] == "abc"

    # Test other convenience functions
    str = c"foobarbaz"
    @test contains(str, c"foo")
    @test contains(str, c"bar")
    @test contains(str, c"baz")
    @test startswith(str, c"foo")
    @test !startswith(c"foo", str)
    @test !startswith(str, c"g")

