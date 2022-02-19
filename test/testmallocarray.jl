# Test MallocArray type

    # Test MallocArray constructors
    A = MallocArray{Float64}(undef, 20)
    @test isa(A, MallocArray{Float64})
    @test isa(A, MallocVector{Float64})
    @test length(A) == 20
    @test sizeof(A) == 20*sizeof(Float64)
    @test IndexStyle(A) == IndexLinear()
    @test firstindex(A) == 1
    @test lastindex(A) == 20
    @test stride(A,1) == 1
    @test stride(A,2) == 20

    # Test mutability and indexing
    A[8] = 5
    @test A[8] === 5.0
    A[8] = 3.1415926735897
    @test A[8] === 3.1415926735897
    A[1:end] = fill(2, 20)
    @test A[10] === 2.0
    A[:] = ones(20)
    @test A[8] === 1.0
    @test A === A[1:end]
    @test A === A[:]
    @test A[1:2] === A[1:2]
    @test A[1:2] != A[1:3]

    # Test equality
    @test A == ones(20)
    @test ones(20) == A
    @test A == A
    B = copy(A)
    @test isa(B, MallocArray)
    @test A == B
    @test A !== B

    # The end
    @test free(A) == 0
    @test free(B) == 0

    # Text constructor in higher dims
    B = MallocMatrix{Float32}(undef, 10, 10)
    @test isa(B, MallocArray{Float32,2})
    @test size(B) == (10,10)
    @test length(B) == 100
    @test stride(B,1) == 1
    @test stride(B,2) == 10
    @test stride(B,3) == 100
    @test B[:,1] === B[:,1]
    @test B[3:7,1] === B[3:7,1]
    @test B[3:7,1] != B[4:7,1]
    @test free(B) == 0

    B = MallocArray{Int64,3}(undef,3,3,3)
    @test isa(B, MallocArray{Int64,3})
    @test size(B) == (3,3,3)
    @test length(B) == 27
    @test stride(B,1) == 1
    @test stride(B,2) == 3
    @test stride(B,3) == 9
    @test stride(B,4) == 27
    @test B[:,1,1] === B[:,1,1]
    @test B[1:2,1,1] === B[1:2,1,1]
    @test B[1:2,1,1] != B[1:3,1,1]
    @test B[:,:,1] === B[:,:,1]
    B[:,2,2] .= 7
    @test B[2,2,2] === 7
    B[:,:,2] .= 5
    @test B[2,2,2] === 5
    @test free(B) == 0
