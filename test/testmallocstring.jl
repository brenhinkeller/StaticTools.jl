## --- Test `MallocString`s

    # Test MallocString constructors
    str = m"Hello, world! 🌍"
    @test isa(str, MallocString)
    @test length(str) == 19

    # Test basic string operations
    @test str == m"Hello, world! 🌍"
    @test str*str == str^2

    # Test mutability
    str[8] = 'W'
    @test str[8] == 0x57 # W
    str[:] = c"Hello, world! 🌍"
    @test str[8] == 0x77 # w

    # Test indexing
    @test str == str[1:end]
    @test str == str[:]
    @test str[1:2] == str[1:2]

    # Test ascii escaping
    many_escapes = m"\0\a\b\f\n\r\t\v'\"\\"
    @test isa(many_escapes, MallocString)
    @test length(many_escapes) == 12
    @test codeunits(many_escapes) == codeunits("\0\a\b\f\n\r\t\v'\"\\\0")
