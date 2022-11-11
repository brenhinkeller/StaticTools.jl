# Test parsing strings as numbers!

    # `Base.parse` is the frontend, but strtod, strotol, and strtoul are the backend
    # Test basic methods for both of our string types
    m = m"123456789" # MallocString
    @test parse(Float64, c"123456789") === 123456789.0
    @test parse(Float64, m) === 123456789.0
    @test parse(Float64, MallocString(pointer(m))) === 123456789.0
    @test parse(Int64, c"123456789") === 123456789
    @test parse(Int64, m) === 123456789
    @test parse(Int64, MallocString(pointer(m))) === 123456789
    @test parse(UInt64, c"123456789") === 0x00000000075bcd15
    @test parse(UInt64, m) === 0x00000000075bcd15
    @test parse(UInt64, MallocString(pointer(m))) === 0x00000000075bcd15
    free(m)

    # Signed Integers (via strtol)
    @test parse(Int64, c"123") === Int64(123)
    @test parse(Int32, c"123") === Int32(123)
    @test parse(Int16, c"123") === Int16(123)
    @test parse(Int16, c"123") === Int16(123)
    @test parse(Int8, c"123") === Int8(123)

    # Unsigned Integers (via strtol)
    @test parse(UInt64, c"18446744073709551615") === 0xffffffffffffffff
    @test parse(UInt64, c"123") === UInt64(123)
    @test parse(UInt32, c"123") === UInt32(123)
    @test parse(UInt16, c"123") === UInt16(123)
    @test parse(UInt16, c"123") === UInt16(123)
    @test parse(UInt8, c"123") === UInt8(123)

    # Floats (via strtod)
    @test parse(Float64, c"123") === Float64(123.)
    @test parse(Float32, c"123") === Float32(123.)
    @test parse(Float16, c"123") === Float16(123.)
    @test parse(Float16, c"123") === Float16(123.)

    # More complicated cases
    @test parse(Float64, c"3.1415926535897") === 3.1415926535897

    # Strtod and strtol are a bit more forgiving than Base.parse,
    # and I, for one, am here for it
    @test parse(Int64, c"3.1415926535897") === 3
    @test parse(Int64, c"3asdfasdf") === 3
    @test parse(Float64, c"3 4 5") === 3.0
    @test parse(Float64, c"3asdfasdf") === 3.0
    @test parse(Float64, c"3 4 5") === 3.0
    @test parse(Float64, c"asdfasdf") === NaN


    # Test parsing from Ptr{Ptr{UInt8}} as in argv
    s1,s2 = "1", "2.0"
    a = [pointer(s1), pointer(s2)]
    argv = pointer(a)
    @test argparse(Int64, argv, 1) === 1
    @test argparse(Float64, argv, 2) === 2.0


## --- Test parsedlm

    m = (1:10) * (1:10)'
    @test printdlm(c"testfile.tsv", m) == 0

    fp = fopen(c"testfile.tsv", c"r")
    m_parsed = parsedlm(fp, '\t')
    @test isa(m_parsed, MallocMatrix{Float64})
    @test m_parsed == m broken=(Sys.ARCH===:aarch64)
    @test free(m_parsed) == 0
    @test fclose(fp) == 0

    m_parsed = parsedlm(c"testfile.tsv", '\t')
    @test isa(m_parsed, MallocMatrix{Float64})
    @test m_parsed == m broken=(Sys.ARCH===:aarch64)
    @test free(m_parsed) == 0

    str = read(c"testfile.tsv", MallocString)
    m_parsed = StaticTools.parsedlmstr(Float64, str, '\t')
    free(str)
    @test m_parsed == m broken=(Sys.ARCH===:aarch64)
    @test free(m_parsed) == 0

    # Clean up
    rm("testfile.tsv")
