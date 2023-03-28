# Test StackArray type

    # Test StackArray constructors
    A = StackArray{Float64}(undef, 20)
    @test isa(A, StackArray{Float64})
    @test isa(A, StackVector{Float64})
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
    @test (A[3:6])[2:3] === A[4:5]

    # Test equality
    @test A == ones(20)
    @test ones(20) == A
    @test A == A
    B = copy(A)
    @test isa(B, StackArray)
    @test A == B
    @test A !== B
    C = reshape(A, 5, 4)
    @test isa(C, ArrayView{Float64,2})
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
    @test isa(C, ArrayView{Float16,2})
    @test size(C) == (20,4)
    @test all(C .=== Float16(0))

    # Test special indexing for tuples
    A[:] = 0.
    A[(1,3,5)] = 1,3,5
    @test A[(1,3,5)] === (1.,3.,5.)
    A[:] = 0.
    A[(1,3,5)] = (1.,3.,5.)
    @test A[1:5] == [1,0,3,0,5]

    # Special indexing for 0d arrays
    C = StackArray{Float64}(undef, ())
    C[] = 1
    @test C[] === 1.0
    C[] = 2.0
    @test C[] === 2.0

    # Test other constructors
    C = similar(B)
    @test isa(C, StackArray{Float64,1})
    @test isa(C[1], Float64)
    @test length(C) == 20
    @test size(C) == (20,)

    C = similar(B, 10, 10)
    @test isa(C, StackArray{Float64,2})
    @test isa(C[1], Float64)
    @test length(C) == 100
    @test size(C) == (10,10)

    C = similar(B, Float32, 10)
    @test isa(C, StackArray{Float32,1})
    @test isa(C[1], Float32)
    @test length(C) == 10
    @test size(C) == (10,)

    m = (1:10)*(1:10)'
    C = StackArray(m)
    @test isa(C, StackArray{Int64,2, 100, (10, 10)})
    @test C == m

    # Text constructor in higher dims
    B = StackMatrix{Float32}(undef, 10, 10)
    @test isa(B, StackArray{Float32,2})
    @test size(B) == (10,10)
    @test length(B) == 100
    @test stride(B,1) == 1
    @test stride(B,2) == 10
    @test stride(B,3) == 100
    @test B[:,1] === B[:,1]
    @test B[3:7,1] === B[3:7,1]
    @test B[3:7,1] != B[4:7,1]

    B = StackArray{Int64,3}(undef,3,3,3)
    @test isa(B, StackArray{Int64,3})
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

    B = StackArray{Int64}(undef,2,2,2,2)
    @test isa(B, StackArray{Int64,4})
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

## -- test other constructors

    A = sfill(0.0, 11,10)
    @test A == zeros(11,10)
    @test A[1] === 0.0

    B = szeros(11,10)
    @test B == zeros(11,10)
    @test B[1] === 0.0

    C = szeros(Int32, 11,10)
    @test C == zeros(Int32, 11,10)
    @test C[1] === Int32(0)

    D = sfill(Int32(0), 11,10)
    @test D == zeros(Int32, 11,10)
    @test D[1] === Int32(0)

    @test A == B == C == D

## --- Additional constructors

    data = (1:25...,)
    A = StackArray(data)
    @test isa(A, StackArray{Int64, 1, 25, (25,)})

    B = StackArray(data,(5,5))
    @test isa(B, StackArray{Int64, 2, 25, (5,5)})

    C = StackArray(data,5,5)
    @test isa(C, StackArray{Int64, 2, 25, (5,5)})

    D = StackArray{Int64, 2, 25, (5,5)}(data)
    @test isa(D, StackArray{Int64, 2, 25, (5,5)})

    @test A != B
    @test A == vec(B)
    @test B == C
    @test C == D

    A = sones(11,10)
    @test A == ones(11,10)
    @test A[1] === 1.0

    B = sones(Int32, 11,10)
    @test B == ones(Int32, 11,10)
    @test B[1] === Int32(1.0)

    @test A == B

    A = seye(10)
    @test A == I(10)
    @test A[5,5] === 1.0

    B = seye(Int32, 10)
    @test B == I(10)
    @test B[5,5] === Int32(1.0)

    @test A == B

## --- Iteration

    A = sfill(10,10)
    let n = 0
        for a in A
            n += a
        end
        @test n == 100
    end

## --- RNG conveience functions

    rng = static_rng()

    A = srand(rng, 5, 5)
    @test isa(A, StackArray{Float64, 2, 25, (5,5)})
    @test all(x -> 0 <= x <= 1, A)

    B = srand(rng, Float64, 5, 5)
    @test isa(B, StackArray{Float64, 2, 25, (5,5)})
    @test all(x -> 0 <= x <= 1, A)

    @test A != B

    rng = MarsagliaPolar()

    A = srandn(rng, 5, 5)
    @test isa(A, StackArray{Float64, 2, 25, (5,5)})
    @test isapprox(sum(A)/length(A), 0, atol=1)

    B = srandn(rng, Float64, 5, 5)
    @test isa(B, StackArray{Float64, 2, 25, (5,5)})
    @test isapprox(sum(B)/length(A), 0, atol=1)

    @test A != B
