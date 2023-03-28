## --- Test `MallocString`s

    # Test MallocString constructors
    str = m"Hello, world! 🌍"
    @test isa(str, MallocString)
    @test sizeof(str) == 19
    @test StaticTools.strlen(str) == length(str) == 18
    @test pointer(str) == Base.unsafe_convert(Ptr{UInt8}, str)
    str1 = MallocString(c"Hello, world! 🌍")
    @test isa(str1, MallocString)

    # Test basic string operations
    @test str == str1
    m, p = str*str, str^2
    @test m == p
    @test free(m) == 0
    @test free(p) == 0
    @test codeunit(str) === UInt8
    @test codeunit(str, 5) == UInt8('o')
    @test ncodeunits(str) == length(str)+1
    @test codeunits(str) == codeunits(c"Hello, world! 🌍")
    @test codeunits(c"Hello, world! 🌍") == codeunits(str)

    # Test concatenation
    m = m"asdf"
    c1 = m*c"asdf"
    @test c1 == "asdfasdf"
    @test m[1:3]*m[1:3] == "asdasd"
    @test m[1:3]^2 == "asdasd"
    free(m)
    free(c1)

    # Test mutability
    str[8] = 'W'
    @test str[8] == 0x57 # W
    str[:] = c"Hello, world! 🌍"
    @test str[8] == 0x77 # w

    # Test indexing
    @test isa(str[1:end], StringView)
    @test str == str[1:end]
    @test str === str[:]
    @test str[1:2] === str[1:2]
    @test str[1:2] != str[1:3]
    strc = copy(str)
    @test strc == str
    @test free(str) == 0
    @test free(str1) == 0
    @test free(strc) == 0

    # Test ascii escaping
    many_escapes = m"\"\0\a\b\f\n\r\t\v\'\"\\"
    @test isa(many_escapes, MallocString)
    @test length(many_escapes) == 12
    @test codeunits(many_escapes) == codeunits("\"\0\a\b\f\n\r\t\v'\"\\\0")

    # Test unsafe_mallocstring
    s = "Hello there!"
    m = unsafe_mallocstring(pointer(s))
    @test isa(m, MallocString)
    @test length(m) == 12
    @test codeunits(m) == codeunits(c"Hello there!")
    @test free(m) == 0

    # Test constructing from Ptr{Ptr{UInt8}} as in argv
    s1,s2 = "Hello", "there"
    a = [pointer(s1), pointer(s2)]
    argv = pointer(a)
    @test MallocString(argv,1) == c"Hello"
    @test MallocString(argv,2) == c"there"

    # Test consistency with other string types
    abc = m"abc"
    @test abc == "abc"
    @test "abc" == abc
    @test abc == c"abc"
    @test abc == abc[1:3]
    @test abc[1:3] == "abc"
    free(abc)

    # Test other convenience functions
    str = m"foobarbaz"
    @test contains(str, c"foo")
    @test contains(str, c"bar")
    @test contains(str, c"baz")
    @test startswith(str, c"foo")
    @test !startswith(c"foo", str)
    @test !startswith(str, c"g")
    @test endswith(str, c"baz")
    @test !endswith(str, c"bar")
    free(str)
