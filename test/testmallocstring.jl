## --- Test `MallocString`s

    # Test MallocString constructors
    str = m"Hello, world! 🌍"
    @test isa(str, MallocString)
    @test length(str) == 19
    @test sizeof(str) == 19
    @test StaticTools.strlen(str) == 18

    # Test basic string operations
    @test str == m"Hello, world! 🌍"
    m, p = str*str, str^2
    @test m == p
    @test free(m) == 0
    @test free(p) == 0
    @test codeunit(str) === UInt8
    @test codeunit(str, 5) == UInt8('o')
    @test ncodeunits(str) == length(str)
    @test codeunits(str) == codeunits(c"Hello, world! 🌍")

    # Test mutability
    str[8] = 'W'
    @test str[8] == 0x57 # W
    str[:] = c"Hello, world! 🌍"
    @test str[8] == 0x77 # w

    # Test indexing
    @test str === str[1:end]
    @test str === str[:]
    @test str[1:2] === str[1:2]
    @test str[1:2] != str[1:3]
    free(str)

    # Test ascii escaping
    many_escapes = m"\0\a\b\f\n\r\t\v'\"\\"
    @test isa(many_escapes, MallocString)
    @test length(many_escapes) == 12
    @test codeunits(many_escapes) == codeunits("\0\a\b\f\n\r\t\v'\"\\\0")

    # Test unsafe_mallocstring
    s = "Hello there!"
    m = unsafe_mallocstring(pointer(s))
    @test isa(m, MallocString)
    @test length(m) == 13
    @test codeunits(m) == codeunits(c"Hello there!")
    @test free(m) == 0

    # Test constructing from Ptr{Ptr{UInt8}} as in argv
    s1,s2 = "Hello", "there"
    a = [pointer(s1), pointer(s2)]
    argv = pointer(a)
    @test MallocString(argv,1) == c"Hello"
    @test MallocString(argv,2) == c"there"
