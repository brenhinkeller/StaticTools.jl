## --- Malloc and free!

    p = malloc(100)
    @test isa(p, Ptr)
    @test free(p) == 0

    a = MallocArray{Float64}(undef, 100)
    StaticTools.memcpy!(a, ones(100))
    @test a == ones(100)
    free(a)
