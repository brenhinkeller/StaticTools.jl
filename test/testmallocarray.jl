# Test MallocArray type

    # Test MallocArray constructors
    A = MallocArray{Float64}(undef, 20)
    @test isa(A, MallocArray{Float64})
    @test length(A) == 20
    @test sizeof(A) == 20*sizeof(Float64)

    # Test mutability and indexing
    A[8] = 5
    @test A[8] === 5.0
    A[8] = 3.1415926735897
    @test A[8] === 3.1415926735897
    A[1:end] = fill(2, 20)
    @test A[10] === 2.0
    A[:] = ones(20)
    @test A[8] === 1.0
    # @test A === A[1:end]
    # @test A === A[:]
    # @test A[1:2] === A[1:2]
    @test A[1:2] != A[1:3]

    # Test equality
    @test A == ones(20)
    @test ones(20) == A
    @test A == A

    # The end
    @test free(A) === nothing
