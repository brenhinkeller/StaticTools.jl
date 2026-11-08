## --- printf with a format and any number of arguments, written to a file to look at what it wrote

    # what `f(fp)` writes to a file, and what it returns
    function written(f)
        path = tempname()
        fp = fopen(path, c"wb") # binary mode: no `\n` -> `\r\n` translation on Windows
        n = f(fp)
        fclose(fp)
        text = read(path, String)
        rm(path)
        return n, text
    end

    # numbers
    @test written(fp -> printf(fp, c"%d + %d = %d\n", 1, 2, 3)) == (10, "1 + 2 = 3\n")
    @test written(fp -> printf(fp, c"%d %d %d %d\n", 1, 2, 3, 4))[2] == "1 2 3 4\n"
    @test written(fp -> printf(fp, c"%lld %llu %llx\n", typemin(Int64), typemax(UInt64), 0xdeadbeef))[2] ==
        "-9223372036854775808 18446744073709551615 deadbeef\n"
    @test written(fp -> printf(fp, c"%5.2f|%-8.3e|%g\n", 12.345, 1234.6, 0.5))[2] == "12.35|1.235e+03|0.5\n" # not a tie, as ties round differently on Windows
    # integers smaller than an `int`, and `Bool`, are promoted; a `Float32` is a `double`
    @test written(fp -> printf(fp, c"%d %d %d %d %d\n", Int8(-5), Int16(-300), UInt8(200), UInt16(60000), true))[2] ==
        "-5 -300 200 60000 1\n"
    @test written(fp -> printf(fp, c"%u %x\n", UInt32(4000000000), UInt32(255)))[2] == "4000000000 ff\n"
    @test written(fp -> printf(fp, c"%.3f %.1f\n", 1.5f0, Float16(2.5)))[2] == "1.500 2.5\n"

    # strings of all kinds, and pointers
    ms = m"malloc'd"
    @test written(fp -> printf(fp, c"[%s] [%s] [%s] %d\n", ms, c"static", "julia", 7))[2] == "[malloc'd] [static] [julia] 7\n"
    free(ms)
    @test written(fp -> printf(fp, c"%s=%d\n", c"x", 1))[2] == "x=1\n"
    @test written(fp -> printf(fp, c"%p %p\n", C_NULL, Ptr{UInt8}(UInt(0x1000))))[2] in ("0x0 0x1000\n", "(nil) 0x1000\n")
    # a format that is a pointer or a `MallocString`
    fmt = m"%d-%d\n"
    @test written(fp -> printf(fp, fmt, 8, 9))[2] == "8-9\n"
    @test written(fp -> printf(fp, pointer(fmt), 8, 9))[2] == "8-9\n"
    free(fmt)
    # a lot of arguments
    @test written(fp -> printf(fp, c"%d%d%d%d%d%d%d%d%d%d%d%d\n", 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2))[2] == "123456789012\n"
    @test written(fp -> printf(fp, c"%f %f %f %f %f %f %f %f %f %f\n", 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0))[2] ==
        "1.000000 2.000000 3.000000 4.000000 5.000000 6.000000 7.000000 8.000000 9.000000 10.000000\n"
    # a mix, which has integers and floats in different registers
    @test written(fp -> printf(fp, c"%d %f %d %f %s %lld\n", 1, 2.0, 3, 4.0, c"five", 6))[2] == "1 2.000000 3 4.000000 five 6\n"

    # many arguments of different types are inferred, and don't allocate (a recursion over the arguments that
    # builds the converted ones stops being inferred after a few, and then boxes: which can't be compiled statically)
    path = tempname()
    fp = fopen(path, c"w")
    many(fp) = printf(fp, c"%d %f %s %d %f %s %lld %u\n", 1, 2.0, c"a", 3, 4.0, "b", 10^12, UInt32(8))
    @test @inferred(many(fp)) isa Int32
    many(fp)
    @test @allocated(many(fp)) == 0
    fclose(fp); rm(path)

    # one argument (these were methods of their own): all the types, to a file, with the format of any kind
    @test written(fp -> printf(fp, c"%d|", 5)) == (2, "5|")
    @test written(fp -> printf(fp, c"%d|", 2^40 % Int32))[2] == "0|"
    @test written(fp -> printf(fp, c"%lld|", 2^40)) == (14, "1099511627776|")
    @test written(fp -> printf(fp, c"%llu|", UInt64(2)^40))[2] == "1099511627776|"
    @test written(fp -> printf(fp, c"%d|%d|", Int8(-3), UInt8(200)))[2] == "-3|200|"
    @test written(fp -> printf(fp, c"%d|%u|", Int16(-3), UInt16(60000)))[2] == "-3|60000|"
    @test written(fp -> printf(fp, c"%d|%u|", Int32(5), UInt32(7)))[2] == "5|7|"
    @test written(fp -> printf(fp, c"%.2f|", 2.5f0))[2] == "2.50|"
    @test written(fp -> printf(fp, c"%f|", 2.5))[2] == "2.500000|"
    @test written(fp -> printf(fp, c"%s|", c"static"))[2] == "static|"
    @test written(fp -> printf(fp, c"%s|", "julia"))[2] == "julia|"
    @test written(fp -> printf(fp, "%d %s|", 3, c"x"))[2] == "3 x|" # a `String` format
    ms = m"malloc'd"
    @test written(fp -> printf(fp, c"%s|", ms))[2] == "malloc'd|"
    free(ms)
    mf = m"%d|"
    @test written(fp -> printf(fp, mf, 4))[2] == "4|"
    free(mf)
    @test written(fp -> printf(fp, c"%p|", Ptr{UInt8}(UInt(0x1000))))[2] == "0x1000|"
    # the return value is always the number of characters written, as in C
    @test printf(c"%d\n", 5) == 2
    @test printf(c"%f\n", 1.5) == 9
    @test printf(c"%lld\n", 10^12) == 14
    @test printf(c"%s\n", c"ab") == 3

    # a null file pointer is an error, as in the other methods
    @test printf(Ptr{StaticTools.FILE}(C_NULL), c"%d %d\n", 1, 2) < 0

    # the number of characters written, to the standard output
    @test printf(c"%d %d\n", 1, 2) == 4
    @test printf(c"%s|%s\n", c"a", "b") == 4
