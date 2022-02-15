## --- Malloc and free!

    p = malloc(100)
    @test isa(p, Ptr)
    @test free(p) == 0
