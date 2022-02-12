## --- File pointers

    fp = stdoutp()
    @test isa(fp, Ptr{StaticTools.FILE})
    @test stdoutp() == fp != 0
    fp = stderrp()
    @test isa(fp, Ptr{StaticTools.FILE})
    @test stderrp() == fp != 0
    fp = stdinp()
    @test isa(fp, Ptr{StaticTools.FILE})
    @test stdinp() == fp != 0


## -- Test low-level printing functions on a variety of arguments

    @test puts("1") == 0
    @test printf("2") == 0
    @test putchar('\n') == 0
    @test printf("%s\n", "3") == 0
    @test printf(4) == 0
    @test printf(5.0) == 0
    @test printf(10.0f0) == 0
    @test printf(0x01) == 0
    @test printf(0x0001) == 0
    @test printf(0x00000001) == 0
    @test printf(0x0000000000000001) == 0
    @test printf(Ptr{UInt64}(0)) == 0

## -- low-level printing to file

    fp = fopen("testfile.txt", "w")
    @test isa(fp, Ptr{StaticTools.FILE})
    @test fp != 0

    @test puts(fp, "1") == 0
    @test fprintf(fp, "2") == 1
    @test putchar(fp, '\n') == 10
    @test fprintf(fp, "%s\n", "3") == 2
    # @test printf(4) == 0
    # @test printf(5.0) == 0
    # @test printf(10.0f0) == 0
    # @test printf(0x01) == 0
    # @test printf(0x0001) == 0
    # @test printf(0x00000001) == 0
    # @test printf(0x0000000000000001) == 0
    # @test printf(Ptr{UInt64}(0)) == 0

    @test fclose(fp) == 0


## -- High-level printing

    # Print AbstractVector
    @test printf(1:5) == 0
    @test printf((1:5...,)) == 0

    # Print AbstractArray
    @test printf((1:5)') == 0
    @test printf(rand(4,4)) == 0

    # Print MallocString
    str = m"Hello, world! 🌍"
    @test print(str) == 0
    @test println(str) == 0
    @test printf(str) == 0
    @test puts(str) == 0
    @test printf(m"%s \n", str) == 0
    show(str)

    # Print StaticString
    str = c"Hello, world! 🌍"
    @test print(str) == 0
    @test println(str) == 0
    @test printf(str) == 0
    @test puts(str) == 0
    @test printf(m"%s \n", str) == 0
    show(str)


## ---

    # Wrap up
    @test newline() == 0
    @test StaticTools.system(c"echo Enough printing for now!") == 0
