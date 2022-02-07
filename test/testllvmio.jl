## -- Test low-level printing functions on a variety of arguments


    @test printf(1) == 0
    @test printf(1.0) == 0
    @test printf(0x01) == 0
    @test printf(0x0001) == 0
    @test printf(0x00000001) == 0
    @test printf(0x0000000000000001) == 0
    @test printf(Ptr{UInt64}(0)) == 0

    # Print AbstractVector
    @test printf(1:10) == 0
    # Print AbstractArray
    @test printf(rand(5,5)) == 0
