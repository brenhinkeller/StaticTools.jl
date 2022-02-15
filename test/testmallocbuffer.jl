# Test MallocBuffer type

    # Test MallocBuffer constructors
    buf = MallocBuffer{Float64}(undef, 20)
    @test isa(buf, MallocBuffer{Float64})
    @test length(buf) == 20
    @test sizeof(buf) == 20*sizeof(Float64)

    # Test mutability and indexing
    buf[8] = 5
    @test buf[8] === 5.0
    buf[8] = 3.1415926735897
    @test buf[8] === 3.1415926735897
    buf[1:end] = fill(2, 20)
    @test buf[10] === 2.0
    buf[:] = ones(20)
    @test buf[8] === 1.0
    @test buf === buf[1:end]
    @test buf === buf[:]
    @test buf[1:2] === buf[1:2]
    @test buf[1:2] != buf[1:3]

    # Test equality
    @test buf == ones(20)
    @test ones(20) == buf
    @test buf == buf

    # The end
    @test free(buf) == 0
