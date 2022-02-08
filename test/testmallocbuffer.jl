# Test MallocBuffer type

    # Test MallocBuffer constructors
    buf = MallocBuffer{Float64}(undef, 20)
    @test isa(buf, MallocBuffer{Float64})
    @test length(buf) == 20
    @test sizeof(buf) == 20*sizeof(Float64)

    # Test mutability and integral indexing
    buf[8] = 5
    @test buf[8] === 5.0
    buf[8] = 3.1415926735897
    @test buf[8] === 3.1415926735897
    buf[:] = ones(20)
    @test buf[8] === 1.0

    # Test equality
    @test buf == ones(20)
    @test ones(20) == buf
    @test buf == buf

    # The end
    @test free(buf) === nothing
