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
    @test pointer(A) == Base.unsafe_convert(Ptr{Float64}, A)

    # Test mutability and indexing
    A[8] = 5
    @test A[8] === 5.0
    A[8] = 3.1415926735897
    @test A[8] === 3.1415926735897
    A[1:end] = fill(2, 20)
    @test A[10] === 2.0
    A[:] = ones(20)
    @test A[8] === 1.0
    @test A == A[1:end]
    @test A === A[:]
    @test A[1:2] === A[1:2]
    @test A[1:2] != A[1:3]
    @test isa(A[1:2], ArrayView)

    # Test equality
    @test A == ones(20)
    @test ones(20) == A
    @test A == A
    B = copy(A)
    @test isa(B, MallocArray)
    @test A == B
    @test A !== B
    C = reshape(A, 5, 4)
    @test isa(C, MallocArray{Float64,2})
    @test size(C) == (5,4)
    A[2] = 7
    @test C[2,1] == 7
    A[7] = 2
    @test C[2,2] == 2
    A[1:end] = 5.0
    @test C[2,2] === 5.0
    A[:] = 0.0
    @test all(C .=== 0.0)
    C = reinterpret(Float16, C)
    @test isa(C, MallocArray{Float16,2})
    @test size(C) == (20,4)
    @test all(C .=== Float16(0))

    # Special indexing for 0d arrays
    C = MallocArray{Float64}(undef, ())
    C[] = 1
    @test C[] === 1.0
    C[] = 2.0
    @test C[] === 2.0
    @test free(C) == 0

    # Test other constructors
    C = similar(B)
    @test isa(C, MallocArray{Float64,1})
    @test isa(C[1], Float64)
    @test length(C) == 20
    @test size(C) == (20,)
    @test free(C) == 0

    C = similar(B, 10, 10)
    @test isa(C, MallocArray{Float64,2})
    @test isa(C[1], Float64)
    @test length(C) == 100
    @test size(C) == (10,10)
    @test free(C) == 0

    C = similar(B, Float32, 10)
    @test isa(C, MallocArray{Float32,1})
    @test isa(C[1], Float32)
    @test length(C) == 10
    @test size(C) == (10,)
    @test free(C) == 0

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

    B = MallocArray{Int64}(undef,2,2,2,2)
    @test isa(B, MallocArray{Int64,4})
    @test size(B) == (2,2,2,2)
    @test length(B) == 16
    @test stride(B,1) == 1
    @test stride(B,2) == 2
    @test stride(B,3) == 4
    @test stride(B,4) == 8
    @test stride(B,5) == 16
    @test B[:,1,1,1] === B[:,1,1,1]
    @test B[1:2,1,1,1] === B[1:2,1,1,1]
    @test B[1:2,1,1,1] != B[1:3,1,1,1]
    @test B[:,:,1,1] === B[:,:,1,1]
    @test B[:,:,:,1] === B[:,:,:,1]
    B[:,2,2,2] .= 7
    @test B[2,2,2,2] === 7
    B[:,:,2,2] .= 5
    @test B[2,2,2,2] === 5
    B[:,:,:,2] .= 3
    @test B[2,2,2,2] === 3
    @test free(B) == 0

## -- test other constructors

    A = MallocArray{Float64,2}(zeros, 11, 10)
    @test A == zeros(11,10)
    @test A[1] === 0.0

    B = mzeros(11,10)
    @test B == zeros(11,10)
    @test B[1] === 0.0

    C = mzeros(Int32, 11,10)
    @test C == zeros(Int32, 11,10)
    @test C[1] === Int32(0)

    D = mfill(Int32(0), 11,10)
    @test D == zeros(Int32, 11,10)
    @test D[1] === Int32(0)

    @test A == B == C == D
    free(A)
    free(B)
    free(C)
    free(D)

## ---

    A = mones(11,10)
    @test A == ones(11,10)
    @test A[1] === 1.0

    B = mones(Int32, 11,10)
    @test B == ones(Int32, 11,10)
    @test B[1] === Int32(1.0)

    @test A == B
    free(A)
    free(B)

    A = meye(10)
    @test A == I(10)
    @test A[5,5] === 1.0

    B = meye(Int32, 10)
    @test B == I(10)
    @test B[5,5] === Int32(1.0)

    @test A == B
    free(A)
    free(B)
